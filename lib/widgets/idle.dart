import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Calls [onIdle] once [timeout] passes without a touch, click, scroll,
/// mouse move or key anywhere under it (dialogs included, when it's above the
/// app's navigator). It's called once per quiet spell: the next input starts
/// the count again. A null [timeout] or [onIdle] turns it off.
class IdleWatcher extends StatefulWidget {
  const IdleWatcher({super.key, required this.timeout, required this.onIdle, required this.child});

  final Duration? timeout;
  final VoidCallback? onIdle;
  final Widget child;

  @override
  State<IdleWatcher> createState() => _IdleWatcherState();
}

class _IdleWatcherState extends State<IdleWatcher> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _arm();
  }

  @override
  void didUpdateWidget(IdleWatcher old) {
    super.didUpdateWidget(old);
    // A new timeout (or turning it on or off) counts from now.
    if (widget.timeout != old.timeout || (widget.onIdle == null) != (old.onIdle == null)) _arm();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    _timer = null;
    final timeout = widget.timeout;
    if (timeout == null || widget.onIdle == null) return;
    // Read at the time it fires: the action may have changed since.
    _timer = Timer(timeout, () => widget.onIdle?.call());
  }

  bool _onKey(KeyEvent _) {
    _arm();
    return false; // only watching: the key still goes where it was going
  }

  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.translucent,
    onPointerDown: (_) => _arm(),
    onPointerMove: (_) => _arm(),
    onPointerHover: (_) => _arm(),
    onPointerSignal: (_) => _arm(),
    child: widget.child,
  );
}
