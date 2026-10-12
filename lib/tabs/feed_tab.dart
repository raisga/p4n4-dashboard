import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/feed.dart';
import '../core/format.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';

const _interval = Duration(seconds: 10);
const _pageSize = 50;

enum _Filter { all, alerts, pending }

/// The project's live events and alerts (`.p4n4.json` `dashboard.feed`, through
/// p4n4-api): what happened, and what asks a person to do something. Operators
/// and admins act on alerts (attend, dismiss); viewers only read.
class FeedTab extends StatefulWidget {
  const FeedTab({super.key, required this.active});

  final bool active;

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  FeedApi? _api;
  FeedPage? _first;
  final _older = <FeedItem>[];
  Object? _olderCursor;
  Object? _error;
  Timer? _timer;
  bool _loading = false;
  bool _loadingOlder = false;
  final _acting = <String>{};
  _Filter _filter = _Filter.all;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = SettingsScope.of(context).apiUri;
    if (api != _api?.api) {
      _api = FeedApi(api);
      _first = null;
      _older.clear();
      _olderCursor = null;
      _error = null;
      _refresh();
    }
    _schedule();
  }

  @override
  void didUpdateWidget(FeedTab old) {
    super.didUpdateWidget(old);
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    if (!widget.active) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(_interval, (_) => _refresh());
    }
  }

  /// The newest page; older pages already loaded stay below it.
  Future<void> _refresh() async {
    final api = _api;
    if (api == null || _loading) return;
    setState(() => _loading = true);
    try {
      final page = await api.page(limit: _pageSize);
      if (!mounted || api != _api) return;
      setState(() {
        _first = page;
        _olderCursor ??= page.nextBefore;
        _error = null;
      });
    } catch (e) {
      if (mounted && api == _api) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOlder() async {
    final api = _api, cursor = _olderCursor;
    if (api == null || cursor == null || _loadingOlder) return;
    setState(() => _loadingOlder = true);
    try {
      final page = await api.page(limit: _pageSize, before: cursor);
      if (!mounted || api != _api) return;
      setState(() {
        _older.addAll(page.items);
        _olderCursor = page.nextBefore;
      });
    } catch (e) {
      if (mounted) _snack(l.feedActionFailed('$e'));
    } finally {
      if (mounted) setState(() => _loadingOlder = false);
    }
  }

  Future<void> _act(FeedItem item, FeedAction action) async {
    setState(() => _acting.add(item.id));
    try {
      await _api!.act(item.id, action.id);
      _older.removeWhere((i) => i.id == item.id);
      await _refresh();
    } catch (e) {
      if (mounted) _snack(l.feedActionFailed('$e'));
    } finally {
      if (mounted) setState(() => _acting.remove(item.id));
    }
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  List<FeedItem> get _items {
    final seen = <String>{};
    return [
      for (final i in [...?_first?.items, ..._older])
        if (seen.add(i.id) &&
            switch (_filter) {
              _Filter.all => true,
              _Filter.alerts => i.alert,
              _Filter.pending => i.pending,
            })
          i,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final technical = SessionScope.of(context).isTechnical;
    final page = _first;
    final error = _error;
    final header = PageHeader(
      title: page?.title ?? l.navFeed,
      subtitle: page?.pending != null && page!.pending! > 0 ? l.feedPending(page.pending!) : null,
      trailing: RefreshButton(busy: _loading, onPressed: _refresh),
    );

    if (page == null) {
      return PageBody(
        children: [
          header,
          const SizedBox(height: 24),
          if (error is FeedException && error.notConfigured)
            EmptyState(
              icon: Icons.dynamic_feed_outlined,
              title: l.feedNotSetUp,
              message: technical ? l.feedNotSetUpTechnical : l.feedNotSetUpMsg,
            )
          else if (error != null)
            EmptyState(
              icon: Icons.cloud_off_outlined,
              title: l.feedUnavailable,
              message: technical ? '$error' : l.feedUnavailableMsg,
              actions: [OutlinedButton(onPressed: _refresh, child: Text(l.retry))],
            )
          else
            LoadingState(l.signInConnecting),
        ],
      );
    }

    final items = _items;
    return PageBody(
      onRefresh: _refresh,
      children: [
        header,
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (f, label) in [
              (_Filter.all, l.feedFilterAll),
              (_Filter.alerts, l.feedFilterAlerts),
              (_Filter.pending, l.feedFilterPending),
            ])
              ChoiceChip(label: Text(label), selected: _filter == f, onSelected: (_) => setState(() => _filter = f)),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          EmptyState(icon: Icons.dynamic_feed_outlined, title: l.feedEmpty, message: l.feedEmptyMsg)
        else
          for (final item in items) ...[
            _FeedCard(item: item, canAct: page.canAct, busy: _acting.contains(item.id), onAction: (a) => _act(item, a)),
            const SizedBox(height: 10),
          ],
        if (_olderCursor != null && items.isNotEmpty)
          Center(
            child: TextButton.icon(
              onPressed: _loadingOlder ? null : _loadOlder,
              icon: const Icon(Icons.expand_more, size: 18),
              label: Text(l.feedOlder),
            ),
          ),
      ],
    );
  }
}

class _FeedCard extends StatelessWidget {
  const _FeedCard({required this.item, required this.canAct, required this.busy, required this.onAction});

  final FeedItem item;
  final bool canAct;
  final bool busy;
  final ValueChanged<FeedAction> onAction;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final f = context.formats;
    final tone = switch (item.tone) {
      FeedTone.review => p4.warn,
      FeedTone.info => p4.blue,
      FeedTone.neutral => p4.muted,
    };
    final time = item.time?.toLocal();
    final now = DateTime.now();
    final when = time == null
        ? null
        : time.year == now.year && time.month == now.month && time.day == now.day
        ? f.clock(time)
        : '${DateFormat.MMMd(f.locale).format(time)} ${f.clock(time)}';
    final status = switch (item.status) {
      null => null,
      'pending_review' => (l.feedStatusPending, p4.warn),
      'attended' => (l.feedStatusAttended, p4.ok),
      'dismissed' => (l.feedStatusDismissed, p4.muted),
      final other => (other, p4.muted),
    };
    final meta = [?when, ...item.meta.values];

    return Panel(
      accent: item.alert ? tone : null,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.badge != null) ...[TagBadge(item.badge!, color: tone), const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: p4.display(size: 16)),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(item.subtitle!, style: p4.body(size: 14, color: p4.muted)),
                    ],
                  ],
                ),
              ),
              if (status != null) ...[const SizedBox(width: 10), TagBadge(status.$1, color: status.$2)],
            ],
          ),
          if (item.detail != null) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: tone),
                const SizedBox(width: 8),
                Expanded(child: Text(item.detail!, style: p4.body(size: 14))),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (meta.isNotEmpty) Text(meta.join(' · '), style: p4.mono(size: 12, color: p4.muted)),
              if (item.synthetic) TagBadge(l.feedDemoData),
            ],
          ),
          if (canAct && item.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, a) in item.actions.indexed)
                  i == 0
                      ? FilledButton(onPressed: busy ? null : () => onAction(a), child: Text(a.label))
                      : OutlinedButton(onPressed: busy ? null : () => onAction(a), child: Text(a.label)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
