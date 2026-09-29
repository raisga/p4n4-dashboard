import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// webview_flutter ships implementations for Android, iOS and macOS only.
bool get webViewSupported => Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

/// Embedded Grafana (kiosk mode by default).
class GrafanaTab extends StatefulWidget {
  const GrafanaTab({super.key});

  @override
  State<GrafanaTab> createState() => _GrafanaTabState();
}

class _GrafanaTabState extends State<GrafanaTab> {
  P4Colors get p4 => context.p4;

  WebViewController? _controller;
  Uri? _loaded;
  int _progress = 0;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!webViewSupported) return;
    final uri = SettingsScope.of(context).grafanaUri;
    if (uri == _loaded) return;
    _loaded = uri;
    _controller ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(p4.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() => _error = null),
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) setState(() => _error = e.description);
          },
        ),
      );
    _controller!.loadRequest(uri);
  }

  Future<void> _openExternal(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final uri = SettingsScope.of(context).grafanaUri;
    final toolbar = Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      color: p4.bg2,
      child: Row(
        children: [
          Icon(Icons.show_chart, color: p4.blue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(uri.toString(), overflow: TextOverflow.ellipsis, style: p4.mono()),
          ),
          if (_controller != null) ...[
            IconButton(
              tooltip: 'Back',
              onPressed: () => _controller!.goBack(),
              icon: const Icon(Icons.arrow_back, size: 18),
            ),
            IconButton(
              tooltip: 'Home',
              onPressed: () => _controller!.loadRequest(uri),
              icon: const Icon(Icons.home_outlined, size: 18),
            ),
            IconButton(
              tooltip: 'Reload',
              onPressed: () => _controller!.reload(),
              icon: const Icon(Icons.refresh, size: 18),
            ),
          ],
          IconButton(
            tooltip: 'Open in browser',
            onPressed: () => _openExternal(uri),
            icon: const Icon(Icons.open_in_new, size: 18),
          ),
        ],
      ),
    );

    return Column(
      children: [
        toolbar,
        if (_controller != null && _progress < 100)
          LinearProgressIndicator(value: _progress / 100, minHeight: 2, color: p4.accent, backgroundColor: p4.bg2)
        else
          const Divider(height: 2, thickness: 2),
        Expanded(
          child: switch ((_controller, _error)) {
            (null, _) => EmptyState(
              icon: Icons.desktop_windows_outlined,
              title: 'Embedded view not available on ${Platform.operatingSystem}',
              message:
                  'Flutter\'s WebView supports Android, iOS and macOS. '
                  'On this platform Grafana opens in your default browser.',
              actions: [FilledButton(onPressed: () => _openExternal(uri), child: const Text('OPEN GRAFANA'))],
            ),
            (_, final String err) => EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Grafana unreachable',
              message: '$uri\n$err',
              actions: [OutlinedButton(onPressed: () => _controller!.loadRequest(uri), child: const Text('RETRY'))],
            ),
            (final c?, _) => WebViewWidget(controller: c),
          },
        ),
      ],
    );
  }
}
