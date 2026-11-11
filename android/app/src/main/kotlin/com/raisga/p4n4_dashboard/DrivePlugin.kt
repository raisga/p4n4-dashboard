package com.raisga.p4n4_dashboard

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.StatFs
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.IOException
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

/**
 * What the Drive features (lib/drive/) need from Android that no plugin offers:
 * keeping the screen on, the free storage the dashcam may fill, and a Bluetooth
 * serial (RFCOMM) link to an OBD-II adapter, which the app relays to the stack
 * over TCP.
 *
 * Methods are on `p4n4/drive`. `connect` answers `{"name", "link"}`; the link's
 * bytes arrive on `p4n4/drive/serial`, then `{"closed": reason, "link": link}`
 * if the adapter goes away (not when Dart closed it).
 */
@SuppressLint("MissingPermission") // [permitted] is checked before every Bluetooth call
class DrivePlugin :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    PluginRegistry.RequestPermissionsResultListener {
    private lateinit var context: Context
    private lateinit var methods: MethodChannel
    private lateinit var serial: EventChannel
    private val main = Handler(Looper.getMainLooper())

    // Connects (which block for seconds) and writes, in order.
    private val io = Executors.newSingleThreadExecutor()
    private var activity: ActivityPluginBinding? = null
    private var sink: EventChannel.EventSink? = null
    private var permissionResult: MethodChannel.Result? = null

    @Volatile private var socket: BluetoothSocket? = null

    // The socket still connecting, which a close ends.
    private var pending: BluetoothSocket? = null

    // Bumped by every close, so a connect that finishes after one is dropped.
    private val generation = AtomicInteger()

    // Guards [socket] and [pending] with [generation], between closes and a connect.
    private val lock = Any()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methods = MethodChannel(binding.binaryMessenger, "p4n4/drive").also { it.setMethodCallHandler(this) }
        serial = EventChannel(binding.binaryMessenger, "p4n4/drive/serial").also { it.setStreamHandler(this) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        serial.setStreamHandler(null)
        close()
        io.shutdown()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) = onAttachedToActivity(binding)

    override fun onDetachedFromActivity() {
        activity?.removeRequestPermissionsResultListener(this)
        activity = null
        permissionResult?.success(false)
        permissionResult = null
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private val adapter: BluetoothAdapter?
        get() = (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?)?.adapter

    private val permitted: Boolean
        get() =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                context.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "keepScreenOn" -> keepScreenOn(call.arguments == true, result)
            "freeBytes" -> result.success(
                try {
                    StatFs(call.arguments as String).availableBytes
                } catch (e: IllegalArgumentException) {
                    null
                },
            )
            "serialState" -> result.success(
                mapOf(
                    "available" to (adapter != null),
                    "enabled" to (adapter?.isEnabled == true),
                    "permitted" to permitted,
                ),
            )
            "requestPermission" -> requestPermission(result)
            "bondedDevices" -> bondedDevices(result)
            "connect" -> connect(call.arguments as String, result)
            "write" -> write(call.arguments as ByteArray, result)
            "disconnect" -> {
                close()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun keepScreenOn(on: Boolean, result: MethodChannel.Result) {
        val window = activity?.activity?.window ?: return result.success(false)
        if (on) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
        result.success(true)
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val host = activity?.activity
        if (permitted || host == null) return result.success(permitted)
        permissionResult?.success(false)
        permissionResult = result
        host.requestPermissions(arrayOf(Manifest.permission.BLUETOOTH_CONNECT), PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST) return false
        permissionResult?.success(grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED)
        permissionResult = null
        return true
    }

    private fun bondedDevices(result: MethodChannel.Result) {
        val adapter = adapter
        if (adapter == null || !permitted || !adapter.isEnabled) return result.success(emptyList<Map<String, String>>())
        result.success(
            adapter.bondedDevices.orEmpty().map { mapOf("name" to (it.name ?: it.address), "address" to it.address) },
        )
    }

    private fun connect(address: String, result: MethodChannel.Result) {
        val adapter = adapter
        if (adapter == null) return result.error("unavailable", "This device has no Bluetooth", null)
        if (!permitted) return result.error("permission", "Bluetooth permission not granted", null)
        if (!adapter.isEnabled) return result.error("disabled", "Bluetooth is off", null)
        if (!BluetoothAdapter.checkBluetoothAddress(address)) {
            return result.error("address", "Not a Bluetooth address: $address", null)
        }
        close()
        val started = generation.get()
        io.execute {
            // Discovery slows connecting down; nothing here starts one, but another app may have.
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) adapter.cancelDiscovery()
            val device = adapter.getRemoteDevice(address)
            val attempts =
                listOf(
                    { device.createRfcommSocketToServiceRecord(SPP) },
                    { device.createInsecureRfcommSocketToServiceRecord(SPP) },
                    // Some ELM327 clones only answer on channel 1, outside SDP.
                    {
                        device.javaClass
                            .getMethod("createRfcommSocket", Int::class.javaPrimitiveType)
                            .invoke(device, 1) as BluetoothSocket
                    },
                )
            var error: Exception? = null
            for (open in attempts) {
                val s =
                    try {
                        open()
                    } catch (e: Exception) {
                        error = e
                        continue
                    }
                val current = synchronized(lock) { (generation.get() == started).also { if (it) pending = s } }
                if (!current) {
                    closeQuietly(s)
                    break
                }
                val connected =
                    try {
                        s.connect()
                        true
                    } catch (e: IOException) {
                        error = e
                        false
                    }
                val kept =
                    synchronized(lock) {
                        if (pending === s) pending = null
                        (connected && generation.get() == started).also { if (it) socket = s }
                    }
                if (kept) {
                    read(s, started)
                    main.post { result.success(mapOf("name" to (device.name ?: address), "link" to started)) }
                    return@execute
                }
                closeQuietly(s)
                if (generation.get() != started) break
            }
            if (generation.get() != started) {
                main.post { result.error("cancelled", "Disconnected while connecting", null) }
            } else {
                main.post { result.error("connect", error?.message ?: "Could not connect to $address", null) }
            }
        }
    }

    private fun read(s: BluetoothSocket, link: Int) {
        Thread({
            val buffer = ByteArray(1024)
            var reason = "closed"
            try {
                val input = s.inputStream
                while (true) {
                    val n = input.read(buffer)
                    if (n < 0) break
                    val chunk = buffer.copyOf(n)
                    main.post { sink?.success(chunk) }
                }
            } catch (e: IOException) {
                reason = e.message ?: reason
            }
            // Only a drop of the current link is news; Dart closed any other.
            val dropped =
                synchronized(lock) {
                    (socket === s).also {
                        if (it) {
                            generation.incrementAndGet()
                            socket = null
                        }
                    }
                }
            closeQuietly(s)
            if (dropped) main.post { sink?.success(mapOf("closed" to reason, "link" to link)) }
        }, "p4n4-obd-serial").start()
    }

    private fun write(bytes: ByteArray, result: MethodChannel.Result) {
        val s = socket ?: return result.error("closed", "Not connected", null)
        io.execute {
            try {
                s.outputStream.write(bytes)
                s.outputStream.flush()
                main.post { result.success(null) }
            } catch (e: IOException) {
                main.post { result.error("write", e.message, null) }
            }
        }
    }

    private fun close() {
        val (s, p) =
            synchronized(lock) {
                generation.incrementAndGet()
                (socket to pending).also {
                    socket = null
                    pending = null
                }
            }
        if (s != null) closeQuietly(s)
        // Ends its connect() at once, with an IOException.
        if (p != null) closeQuietly(p)
    }

    private fun closeQuietly(s: BluetoothSocket) {
        try {
            s.close()
        } catch (e: IOException) {
            // Already closed.
        }
    }

    private companion object {
        // The Serial Port Profile, which ELM327 adapters speak.
        val SPP: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")
        const val PERMISSION_REQUEST = 2468
    }
}
