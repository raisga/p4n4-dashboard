package com.raisga.p4n4_dashboard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The Drive features' Android side: lib/drive/drive_channel.dart.
        flutterEngine.plugins.add(DrivePlugin())
    }
}
