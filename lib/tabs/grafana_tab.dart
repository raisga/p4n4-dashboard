import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../platform/html_view.dart';
import '../widgets/common.dart';

/// webview_flutter ships implementations for Android, iOS and macOS only,
/// registered at startup (so never in widget tests). On web, Grafana goes in
/// an `<iframe>` instead; Linux and Windows open it in the browser.
bool get webViewSupported =>
    !kIsWeb &&
    const {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS}.contains(defaultTargetPlatform) &&
    WebViewPlatform.instance != null;

/// [uri] in the app's light or dark mode: Grafana's `theme` parameter
/// overrides the signed-in user's own theme for that page load.
Uri themedGrafanaUri(Uri uri, Brightness brightness) =>
    uri.replace(queryParameters: {...uri.queryParameters, 'theme': brightness.name});

/// Embedded Grafana (kiosk mode by default), in the app's light or dark mode.
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

  /// Web: bumped by Home/Reload to recreate the `<iframe>`.
  int _frame = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!webViewSupported) return;
    // Switching the app's theme changes the URL, so Grafana reloads in it.
    final uri = _uri;
    if (uri == _loaded) return;
    _loaded = uri;
    _controller ??= WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => _progress = p),
          onPageStarted: (_) => setState(() => _error = null),
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) setState(() => _error = e.description);
          },
        ),
      );
    _controller!
      ..setBackgroundColor(p4.bg)
      ..loadRequest(uri);
  }

  Uri get _uri => themedGrafanaUri(SettingsScope.of(context).grafanaUri, Theme.of(context).brightness);

  Future<void> _openExternal(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final uri = _uri;
    final technical = SessionScope.of(context).isTechnical;
    final l = context.l10n;
    final toolbar = Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      color: p4.bg2,
      child: Row(
        children: [
          Icon(Icons.show_chart, color: p4.accent, size: 20),
          const SizedBox(width: 10),
          Text(l.grafanaDashboards, style: p4.display(size: 15, weight: FontWeight.w600, spacing: 0)),
          const SizedBox(width: 12),
          Expanded(
            // Admins and power users see which page this is; viewers don't need the URL.
            child: technical
                ? Text(uri.toString(), overflow: TextOverflow.ellipsis, style: p4.mono(size: 12, spacing: 0))
                : const SizedBox.shrink(),
          ),
          if (kIsWeb)
            IconButton(
              tooltip: l.reloadTooltip,
              onPressed: () => setState(() => _frame++),
              icon: const Icon(Icons.refresh, size: 18),
            ),
          if (_controller != null) ...[
            IconButton(
              tooltip: l.backTooltip,
              onPressed: () => _controller!.goBack(),
              icon: const Icon(Icons.arrow_back, size: 18),
            ),
            IconButton(
              tooltip: l.navHome,
              onPressed: () => _controller!.loadRequest(uri),
              icon: const Icon(Icons.home_outlined, size: 18),
            ),
            IconButton(
              tooltip: l.reloadTooltip,
              onPressed: () => _controller!.reload(),
              icon: const Icon(Icons.refresh, size: 18),
            ),
          ],
          IconButton(
            tooltip: l.openInBrowser,
            onPressed: () => _openExternal(uri),
            icon: const Icon(Icons.open_in_new, size: 18),
          ),
        ],
      ),
    );

    return Column(
      children: [
        toolbar,
        if (!kIsWeb && _controller != null && _progress < 100)
          LinearProgressIndicator(value: _progress / 100, minHeight: 2, color: p4.accent, backgroundColor: p4.bg2)
        else
          const Divider(height: 2, thickness: 2),
        Expanded(
          child: switch ((_controller, _error)) {
            // Grafana must allow framing (GF_SECURITY_ALLOW_EMBEDDING=true), or
            // the frame stays blank; Open in browser still works.
            _ when kIsWeb => HtmlIFrame(key: ValueKey((uri, _frame)), uri: uri),
            (null, _) => EmptyState(
              icon: Icons.desktop_windows_outlined,
              title: l.embedUnavailable(defaultTargetPlatform.name),
              message: l.embedUnavailableMsg,
              actions: [FilledButton(onPressed: () => _openExternal(uri), child: Text(l.openGrafana))],
            ),
            (_, final String err) => EmptyState(
              icon: Icons.cloud_off_outlined,
              color: p4.err,
              title: technical ? l.grafanaUnreachable : l.dashboardsUnavailable,
              message: l.dashboardsUnavailableMsg,
              details: technical ? '$uri\n$err' : null,
              actions: [OutlinedButton(onPressed: () => _controller!.loadRequest(uri), child: Text(l.retry))],
            ),
            (final c?, _) => WebViewWidget(controller: c),
          },
        ),
      ],
    );
  }
}
