import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/stack_control.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';

/// A stack's container logs as they come, or one service's (admins only; the
/// API checks too). Opened from the Services tab.
class LogsPage extends StatefulWidget {
  const LogsPage({super.key, required this.stack, required this.title, this.service, this.follow});

  /// p4n4-api's stack name (`iot`, `ai`, …), and the Compose service, if one.
  final String stack;
  final String? service;

  /// What the logs are of, for the title: the stack's or the service's name.
  final String title;

  /// The stream; [followStackLogs] unless a test passes its own.
  final Stream<String> Function(Uri api, String stack, {String? service})? follow;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  /// Older lines are dropped past this, so a chatty service can't fill memory.
  static const maxLines = 2000;

  final _lines = <String>[];
  final _scroll = ScrollController();
  final _filter = TextEditingController();
  StreamSubscription<String>? _sub;
  Object? _error;
  bool _ended = false;

  /// Keep the newest line in view; off while someone scrolls up to read.
  bool _tail = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final atEnd = _scroll.position.pixels >= _scroll.position.maxScrollExtent - 24;
      if (atEnd != _tail) setState(() => _tail = atEnd);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sub == null && !_ended && _error == null) _connect();
  }

  void _connect() {
    final api = SettingsScope.of(context).apiUri;
    final follow =
        widget.follow ?? (Uri api, String stack, {String? service}) => followStackLogs(api, stack, service: service);
    _sub?.cancel();
    setState(() {
      _error = null;
      _ended = false;
    });
    _sub = follow(api, widget.stack, service: widget.service).listen(
      (line) {
        setState(() {
          _lines.add(line);
          if (_lines.length > maxLines) _lines.removeRange(0, _lines.length - maxLines);
        });
        if (_tail) _toEnd();
      },
      onError: (Object e) => setState(() {
        _error = e;
        _sub = null;
      }),
      onDone: () => setState(() {
        _ended = true;
        _sub = null;
      }),
      cancelOnError: true,
    );
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  });

  @override
  void dispose() {
    _sub?.cancel();
    _scroll.dispose();
    _filter.dispose();
    super.dispose();
  }

  List<String> get _shown {
    final q = _filter.text.trim().toLowerCase();
    return q.isEmpty
        ? _lines
        : [
            for (final line in _lines)
              if (line.toLowerCase().contains(q)) line,
          ];
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _shown.join('\n')));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
  }

  /// Errors and warnings stand out, whatever the service's log format.
  Color _tone(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('error') || lower.contains('fatal') || lower.contains('panic')) return p4.err;
    if (lower.contains('warn')) return p4.warn;
    return p4.text;
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    final (health, status) = switch ((_error, _ended)) {
      (final e?, _) => (Health.down, l.logsFailed('$e')),
      (_, true) => (Health.unknown, l.logsEnded),
      _ when _sub == null => (Health.pending, l.signInConnecting),
      _ => (Health.up, l.logsFollowing),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(l.logsTitle(widget.title)),
        actions: [
          IconButton(
            tooltip: l.copyTooltip,
            onPressed: shown.isEmpty ? null : _copy,
            icon: Icon(Icons.copy_outlined, color: p4.muted),
          ),
          IconButton(
            tooltip: l.clearList,
            onPressed: _lines.isEmpty ? null : () => setState(_lines.clear),
            icon: Icon(Icons.clear_all, color: p4.muted),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: StatusIndicator(health, label: status),
                ),
                if (_error != null || _ended)
                  OutlinedButton.icon(
                    onPressed: _connect,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l.reconnectTooltip),
                  ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _filter,
                    onChanged: (_) => setState(() {}),
                    style: p4.mono(size: 13, color: p4.text, spacing: 0),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.filter_list, size: 18),
                      hintText: l.logsFilter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Stack(
              children: [
                if (shown.isEmpty)
                  Center(
                    child: Text(
                      _lines.isEmpty ? l.logsEmpty : l.logsNoMatch,
                      style: p4.body(size: 14, color: p4.muted),
                    ),
                  )
                else
                  SelectionArea(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: shown.length,
                      itemBuilder: (context, i) =>
                          Text(shown[i], style: p4.mono(size: 12, color: _tone(shown[i]), spacing: 0)),
                    ),
                  ),
                if (!_tail && shown.isNotEmpty)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      tooltip: l.logsLatest,
                      onPressed: () {
                        setState(() => _tail = true);
                        _toEnd();
                      },
                      child: const Icon(Icons.arrow_downward),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
