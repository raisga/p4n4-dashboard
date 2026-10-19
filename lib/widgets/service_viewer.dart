import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../api/services.dart' show blockedAsMixedContent;
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../platform/html_view.dart';
import 'common.dart';

/// webview_flutter ships implementations for Android, iOS and macOS only,
/// registered at startup (so never in widget tests). On web, pages go in an
/// `<iframe>` instead; Linux and Windows open them in the browser.
bool get webViewSupported =>
    !kIsWeb &&
    const {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS}.contains(defaultTargetPlatform) &&
    WebViewPlatform.instance != null;

/// How this platform shows a web page inside the app.
enum EmbedSupport {
  /// An `<iframe>` (web).
  iframe,

  /// webview_flutter (Android, iOS, macOS).
  webView,

  /// None (Windows, Linux): pages open in the browser.
  none;

  static EmbedSupport get current => kIsWeb
      ? iframe
      : webViewSupported
      ? webView
      : none;
}

/// Builds the `<iframe>` for [uri]: [HtmlIFrame], or a stand-in in tests.
typedef FrameBuilder = Widget Function(Uri uri, String title, ValueChanged<FrameLoad> onLoad, ValueChanged<Uri> onPage);

/// Wording a caller can change from the viewer's own (the Grafana tab keeps
/// saying "Charts" to normies). Null takes the viewer's.
class ViewerTexts {
  const ViewerTexts({this.unsupportedMessage, this.openLabel, this.failedTitle, this.failedMessage});

  /// Under "Embedded view not available" on Windows and Linux.
  final String? unsupportedMessage;

  /// That page's button.
  final String? openLabel;

  /// When the page doesn't load.
  final String? failedTitle;
  final String? failedMessage;
}

/// A service's web app inside the app, under a toolbar: back to where it
/// came from ([onClose]), reload, open in the browser and, where the web view
/// has a history (Android, iOS, macOS), back and home within the page.
///
/// Instead of an empty frame it says when the service is down ([health]),
/// when this platform can't embed pages (Windows, Linux), when the page
/// failed or refused to be framed, and when it's taking long enough that
/// framing may be blocked. Only [technical] users see the URL and raw errors.
class ServiceViewer extends StatefulWidget {
  const ServiceViewer({
    super.key,
    required this.uri,
    required this.title,
    this.icon = Icons.web_outlined,
    this.health = Health.unknown,
    this.technical = false,
    this.onClose,
    this.onRetry,
    this.sameOriginOnly = false,
    this.texts = const ViewerTexts(),
    this.slowAfter = const Duration(seconds: 15),
    this.keepQuery = const {},
    this.support,
    this.page,
    this.frameBuilder,
  });

  /// The page it opens, and Home goes back to.
  final Uri uri;

  /// The service's name, for the toolbar, the frame and the messages.
  final String title;
  final IconData icon;

  /// From the Services tab's status: down shows that instead of an empty
  /// page, and coming back up loads it.
  final Health health;

  /// Admins and power users: the URL in the toolbar, and raw errors.
  final bool technical;

  /// Leaves the viewer (the toolbar's leading back arrow); null shows none.
  final VoidCallback? onClose;

  /// Run by Try again before reloading, e.g. to re-check the service's status.
  final Future<void> Function()? onRetry;

  /// The service refuses frames from other origins (n8n): on web it's only
  /// tried on the dashboard's own origin, through its proxy.
  final bool sameOriginOnly;
  final ViewerTexts texts;

  /// How long a page may take before the viewer suggests framing is blocked.
  final Duration slowAfter;

  /// Query parameters of [uri] each page needs when it loads, e.g. Grafana's
  /// `theme`, which its sign-in drops (it lands on its home without it). A
  /// page that loads without one gets [uri] loaded again, unless doing that
  /// just landed there (the sign-in page itself). Only pages the viewer can
  /// read count: same-origin frames on web, and the native web views.
  final Set<String> keepQuery;

  /// Overrides [EmbedSupport.current].
  @visibleForTesting
  final EmbedSupport? support;

  /// Overrides the page's own URL (`Uri.base`), which decides mixed content.
  @visibleForTesting
  final Uri? page;

  /// Overrides [HtmlIFrame] when [support] is [EmbedSupport.iframe].
  @visibleForTesting
  final FrameBuilder? frameBuilder;

  @override
  State<ServiceViewer> createState() => _ServiceViewerState();
}

enum _Phase { loading, shown, blocked, failed }

class _ServiceViewerState extends State<ServiceViewer> {
  P4Colors get p4 => context.p4;

  /// Origins whose "blank?" hint was dismissed, for the rest of the session.
  static final _hintDismissed = <String>{};

  WebViewController? _controller;
  _Phase _phase = _Phase.loading;

  /// Still loading after [ServiceViewer.slowAfter].
  bool _slow = false;

  /// Loaded from another origin on web: it may have refused the frame.
  bool _opaque = false;
  String? _error;
  int _progress = 0;
  Timer? _timer;

  /// Web: bumped to recreate the `<iframe>`.
  int _frame = 0;
  bool _started = false;

  EmbedSupport get _support => widget.support ?? EmbedSupport.current;

  bool get _down => widget.health == Health.down;

  /// On web, a service that only allows its own origin can't be framed from
  /// elsewhere: no point trying.
  bool get _crossOriginRefused => _support == EmbedSupport.iframe && widget.sameOriginOnly && !_sameOrigin(widget.uri);

  /// On an HTTPS page, the browser blocks a plain-HTTP frame (mixed content)
  /// and leaves it empty, without saying so.
  bool get _insecure => _support == EmbedSupport.iframe && blockedAsMixedContent(widget.uri, widget.page);

  /// Known not to show before trying: [_crossOriginRefused] or [_insecure].
  bool get _refused => _crossOriginRefused || _insecure;

  static bool _sameOrigin(Uri uri) =>
      (uri.isScheme('http') || uri.isScheme('https')) &&
      (Uri.base.isScheme('http') || Uri.base.isScheme('https')) &&
      uri.origin == Uri.base.origin;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _start();
    }
  }

  @override
  void didUpdateWidget(ServiceViewer old) {
    super.didUpdateWidget(old);
    // A new page (Grafana's theme follows the app's), or the service is back.
    if (old.uri != widget.uri || (old.health == Health.down && !_down)) {
      _start();
    } else if (_down) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// (Re)loads [ServiceViewer.uri], unless there's nothing to load it in.
  void _start() {
    _timer?.cancel();
    _phase = _Phase.loading;
    _slow = _opaque = false;
    _error = null;
    _progress = 0;
    if (_down || _support == EmbedSupport.none || _refused) return;
    _watchSlow();
    switch (_support) {
      case EmbedSupport.iframe:
        _frame++;
      case EmbedSupport.webView:
        _controller ??= WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (p) {
                if (!mounted) return;
                setState(() => _progress = p);
                if (p == 100) _shown();
              },
              onPageStarted: (_) {
                if (mounted && _phase == _Phase.failed) setState(() => _phase = _Phase.loading);
              },
              onPageFinished: (url) {
                _shown();
                if (Uri.tryParse(url) case final at?) _onPage(at);
              },
              onWebResourceError: (e) {
                if (!mounted || !(e.isForMainFrame ?? true)) return;
                _timer?.cancel();
                setState(() {
                  _phase = _Phase.failed;
                  _error = e.description;
                });
              },
            ),
          );
        _controller!
          ..setBackgroundColor(p4.bg)
          ..loadRequest(widget.uri);
      case EmbedSupport.none:
    }
  }

  /// Says so if the page is still loading after [ServiceViewer.slowAfter].
  void _watchSlow() {
    _timer?.cancel();
    _timer = Timer(widget.slowAfter, () {
      if (mounted && _phase == _Phase.loading) setState(() => _slow = true);
    });
  }

  void _shown() {
    if (!mounted || _phase == _Phase.failed) return;
    _timer?.cancel();
    setState(() {
      _phase = _Phase.shown;
      _slow = false;
    });
  }

  void _onFrameLoad(FrameLoad load) {
    if (!mounted) return;
    _timer?.cancel();
    setState(() {
      _slow = false;
      _phase = load == FrameLoad.blocked ? _Phase.blocked : _Phase.shown;
      _opaque = load == FrameLoad.opaque;
    });
  }

  /// The path of the page that loaded without one of
  /// [ServiceViewer.keepQuery], when that made the viewer load
  /// [ServiceViewer.uri] again.
  String? _reloadedFrom;

  void _onPage(Uri at) {
    if (!mounted) return;
    final want = widget.uri.queryParameters;
    if (widget.keepQuery.every((k) => !want.containsKey(k) || at.queryParameters[k] == want[k])) {
      _reloadedFrom = null;
      return;
    }
    if (_reloadedFrom == at.path) return;
    _reloadedFrom = at.path;
    setState(_start);
  }

  void _reload() {
    if (_support == EmbedSupport.webView && _controller != null && _phase != _Phase.failed) {
      _controller!.reload();
      setState(() => _phase = _Phase.loading);
      _watchSlow();
      return;
    }
    setState(_start);
  }

  Future<void> _retry() async {
    await widget.onRetry?.call();
    if (mounted) setState(_start);
  }

  Future<void> _openExternal() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final opened = await launchUrl(widget.uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!opened) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text(widget.technical ? l.couldNotOpen('${widget.uri}') : l.couldNotOpenService(widget.title)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final loading = _phase == _Phase.loading && !_down && _support != EmbedSupport.none && !_refused;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(l),
        if (loading && !reduceMotion)
          LinearProgressIndicator(
            value: _support == EmbedSupport.webView ? _progress / 100 : null,
            minHeight: 2,
            color: p4.accent,
            backgroundColor: p4.bg2,
            semanticsLabel: l.viewerLoading(widget.title),
          )
        else if (loading)
          // No moving bar with reduce motion: say it instead.
          Container(
            color: p4.bg2,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Semantics(
              liveRegion: true,
              child: Text(l.viewerLoading(widget.title), style: p4.body(size: 12, color: p4.muted)),
            ),
          )
        else
          const Divider(height: 2, thickness: 2),
        if (_opaque && !_hintDismissed.contains(_originOf(widget.uri)) && _phase == _Phase.shown) _blankHint(l),
        Expanded(child: _body(l)),
      ],
    );
  }

  static String _originOf(Uri uri) => '${uri.scheme}://${uri.authority}';

  Widget _toolbar(AppLocalizations l) {
    final native = _support == EmbedSupport.webView && _controller != null;
    final canLoad = !_down && _support != EmbedSupport.none && !_refused;
    return Container(
      padding: EdgeInsets.fromLTRB(widget.onClose == null ? 16 : 4, 6, 8, 6),
      color: p4.bg2,
      child: Row(
        children: [
          if (widget.onClose != null)
            IconButton(tooltip: l.viewerClose, onPressed: widget.onClose, icon: const Icon(Icons.arrow_back))
          else
            ExcludeSemantics(child: Icon(widget.icon, color: p4.accent, size: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: p4.display(size: 15, weight: FontWeight.w600, spacing: 0),
                  ),
                ),
                // Admins and power users see which page this is; viewers don't need the URL.
                if (widget.technical)
                  Text(
                    widget.uri.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: p4.mono(size: 11, color: p4.muted, spacing: 0),
                  ),
              ],
            ),
          ),
          if (native) ...[
            IconButton(
              tooltip: l.backTooltip,
              onPressed: () => _controller!.goBack(),
              icon: const Icon(Icons.chevron_left, size: 20),
            ),
            IconButton(
              tooltip: l.navHome,
              onPressed: () => setState(_start),
              icon: const Icon(Icons.home_outlined, size: 18),
            ),
          ],
          if (canLoad)
            IconButton(tooltip: l.reloadTooltip, onPressed: _reload, icon: const Icon(Icons.refresh, size: 18)),
          IconButton(tooltip: l.openInBrowser, onPressed: _openExternal, icon: const Icon(Icons.open_in_new, size: 18)),
        ],
      ),
    );
  }

  /// Web, another origin: the browser doesn't say whether the page refused
  /// the frame, so say what a blank one means.
  Widget _blankHint(AppLocalizations l) => Container(
    color: p4.bg3,
    padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
    child: Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: p4.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(l.viewerBlankHint(widget.title), style: p4.body(size: 13, color: p4.muted)),
        ),
        IconButton(tooltip: l.openInBrowser, onPressed: _openExternal, icon: const Icon(Icons.open_in_new, size: 16)),
        IconButton(
          tooltip: l.viewerDismissHint,
          onPressed: () => setState(() => _hintDismissed.add(_originOf(widget.uri))),
          icon: const Icon(Icons.close, size: 16),
        ),
      ],
    ),
  );

  Widget _body(AppLocalizations l) {
    final name = widget.title;
    final retry = OutlinedButton(onPressed: _retry, child: Text(l.retry));
    final open = FilledButton(onPressed: _openExternal, child: Text(widget.texts.openLabel ?? l.openService(name)));
    if (_down) {
      return EmptyState(
        icon: Icons.power_off_outlined,
        color: p4.err,
        title: l.viewerDownTitle(name),
        message: widget.technical ? l.viewerDownMsg : l.viewerDownMsgPlain,
        actions: [retry],
      );
    }
    if (_support == EmbedSupport.none) {
      return EmptyState(
        icon: Icons.desktop_windows_outlined,
        title: l.embedUnavailable(defaultTargetPlatform.name),
        message: widget.texts.unsupportedMessage ?? l.viewerUnsupportedMsg(name),
        actions: [open],
      );
    }
    if (_refused || _phase == _Phase.blocked) {
      return EmptyState(
        icon: Icons.web_asset_off_outlined,
        color: p4.warn,
        title: l.viewerBlockedTitle(name),
        message: switch (widget.technical) {
          false => l.viewerBlockedMsgPlain(name),
          true when _insecure => l.viewerInsecureMsg(name),
          true => l.viewerBlockedMsg(name),
        },
        details: widget.technical ? '${widget.uri}' : null,
        // Known before trying: trying again changes nothing.
        actions: [open, if (!_refused) retry],
      );
    }
    if (_phase == _Phase.failed) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        color: p4.err,
        title: widget.texts.failedTitle ?? (widget.technical ? l.viewerUnreachable(name) : l.viewerUnavailable(name)),
        message: widget.texts.failedMessage ?? l.viewerUnavailableMsg,
        details: widget.technical ? '${widget.uri}\n${_error ?? ''}'.trim() : null,
        actions: [
          retry,
          OutlinedButton(onPressed: _openExternal, child: Text(l.openInBrowser)),
        ],
      );
    }
    final page = switch (_support) {
      EmbedSupport.iframe => KeyedSubtree(
        key: ValueKey((widget.uri, _frame)),
        child: (widget.frameBuilder ?? _htmlFrame)(widget.uri, name, _onFrameLoad, _onPage),
      ),
      _ => WebViewWidget(controller: _controller!),
    };
    if (!_slow) return page;
    // Keep the page underneath: it may still turn up.
    return Stack(
      fit: StackFit.expand,
      children: [
        page,
        ColoredBox(
          color: p4.bg.withValues(alpha: 0.94),
          child: EmptyState(
            icon: Icons.hourglass_empty,
            color: p4.warn,
            title: l.viewerSlowTitle(name),
            message: l.viewerSlowMsg(name),
            details: widget.technical ? l.viewerSlowDetails : null,
            actions: [
              open,
              retry,
              TextButton(onPressed: () => setState(() => _slow = false), child: Text(l.viewerKeepWaiting)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _htmlFrame(Uri uri, String title, ValueChanged<FrameLoad> onLoad, ValueChanged<Uri> onPage) =>
      HtmlIFrame(uri: uri, title: title, onLoad: onLoad, onPage: onPage);
}
