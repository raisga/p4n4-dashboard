import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/feed.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';

/// Posts [action] on [item], refreshes the feed and returns its items as they are now.
typedef FeedActor = Future<List<FeedItem>> Function(FeedItem item, FeedAction action);

/// One feed item in full, opened from the Feed tab: its picture (the evidence) as large as the
/// screen allows, what it says, its link, and its actions. Made for reviewing alerts one after
/// another from the keyboard: 1–9 take the actions in order, J and K (or the arrows) move to the
/// next and previous item, Esc goes back. After an action it moves on to the next item to review.
class FeedItemPage extends StatefulWidget {
  const FeedItemPage({
    super.key,
    required this.api,
    required this.items,
    required this.index,
    required this.canAct,
    required this.act,
  });

  final FeedApi api;
  final List<FeedItem> items;
  final int index;
  final bool canAct;
  final FeedActor act;

  @override
  State<FeedItemPage> createState() => _FeedItemPageState();
}

class _FeedItemPageState extends State<FeedItemPage> {
  late List<FeedItem> _items = widget.items;
  late int _index = widget.index;
  bool _busy = false;

  FeedItem get _item => _items[_index];

  void _go(int step) {
    final next = _index + step;
    if (next >= 0 && next < _items.length) setState(() => _index = next);
  }

  Future<void> _act(FeedAction action) async {
    if (_busy) return;
    final id = _item.id;
    setState(() => _busy = true);
    final fresh = await widget
        .act(_item, action)
        .then<List<FeedItem>?>(
          (v) => v,
          onError: (Object e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.feedActionFailed('$e'))));
            }
            return null;
          },
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (fresh == null || fresh.isEmpty) return;
      _items = fresh;
      final at = fresh.indexWhere((i) => i.id == id);
      // On to the next item still to review, below this one; else stay on this one, as it is now
      final next = fresh.indexWhere((i) => i.pending && i.id != id, at < 0 ? 0 : at);
      _index = next >= 0 ? next : (at >= 0 ? at : _index.clamp(0, fresh.length - 1));
    });
  }

  Map<ShortcutActivator, VoidCallback> get _keys {
    final actions = widget.canAct ? _item.actions : const <FeedAction>[];
    return {
      for (final (i, a) in actions.take(9).indexed)
        SingleActivator(LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + i)): () => _act(a),
      const SingleActivator(LogicalKeyboardKey.keyJ): () => _go(1),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
      const SingleActivator(LogicalKeyboardKey.keyK): () => _go(-1),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
      const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final item = _item;
    final details = _Details(item: item, canAct: widget.canAct, busy: _busy, onAction: _act);
    return CallbackShortcuts(
      bindings: _keys,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l.feedPosition(_index + 1, _items.length)),
            actions: [
              IconButton(
                tooltip: l.feedPrevious,
                onPressed: _index > 0 ? () => _go(-1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: l.feedNext,
                onPressed: _index < _items.length - 1 ? () => _go(1) : null,
                icon: const Icon(Icons.chevron_right),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, box) {
              final picture = item.image ? _Evidence(key: ValueKey(item.id), api: widget.api, itemId: item.id) : null;
              if (picture != null && box.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Padding(padding: const EdgeInsets.all(16), child: picture),
                    ),
                    SizedBox(
                      width: 400,
                      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(0, 16, 16, 16), child: details),
                    ),
                  ],
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (picture != null) ...[
                      SizedBox(height: (box.maxWidth - 32) * 9 / 16, child: picture),
                      const SizedBox(height: 16),
                    ],
                    details,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.item, required this.canAct, required this.busy, required this.onAction});

  final FeedItem item;
  final bool canAct;
  final bool busy;
  final ValueChanged<FeedAction> onAction;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final status = feedStatus(context, item.status);
    final link = item.link;
    return Panel(
      accent: item.alert ? feedTone(context, item.tone) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (item.badge != null) TagBadge(item.badge!, color: feedTone(context, item.tone)),
              if (status != null) TagBadge(status.$1, color: status.$2),
              if (item.synthetic) TagBadge(l.feedDemoData),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.title, style: p4.display(size: 20)),
          if (item.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(item.subtitle!, style: p4.body(size: 14, color: p4.muted)),
          ],
          if (item.detail != null) ...[
            const SizedBox(height: 14),
            SelectableText(item.detail!, style: p4.body(size: 15)),
          ],
          // When, and the item's own facts, as the card shows them
          if ([?feedWhen(context, item.time), ...item.meta.values] case final facts when facts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(facts.join(' · '), style: p4.mono(size: 12, color: p4.muted)),
          ],
          if (canAct && item.actions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, a) in item.actions.indexed)
                  i == 0
                      ? FilledButton(onPressed: busy ? null : () => onAction(a), child: Text(_keyed(i, a.label)))
                      : OutlinedButton(onPressed: busy ? null : () => onAction(a), child: Text(_keyed(i, a.label))),
              ],
            ),
          ],
          if (link != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => launchUrl(link.url, mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(link.label),
            ),
          ],
          const SizedBox(height: 14),
          Text(l.feedKeys, style: p4.body(size: 12, color: p4.muted)),
        ],
      ),
    );
  }

  /// "1 · Confirm": the key that takes the action, for the first nine.
  static String _keyed(int i, String label) => i < 9 ? '${i + 1} · $label' : label;
}

/// An item's picture, fetched through p4n4-api; pinch or scroll to zoom.
class _Evidence extends StatefulWidget {
  const _Evidence({super.key, required this.api, required this.itemId});

  final FeedApi api;
  final String itemId;

  @override
  State<_Evidence> createState() => _EvidenceState();
}

class _EvidenceState extends State<_Evidence> {
  late final Future<Uint8List> _picture = widget.api.image(widget.itemId);

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Colors.black,
        child: FutureBuilder<Uint8List>(
          future: _picture,
          builder: (context, snap) => switch (snap) {
            AsyncSnapshot(hasData: true, :final data?) => InteractiveViewer(
              maxScale: 6,
              child: Center(
                child: Image.memory(data, fit: BoxFit.contain, semanticLabel: l.feedPicture, gaplessPlayback: true),
              ),
            ),
            AsyncSnapshot(hasError: true) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined, color: p4.muted, size: 32),
                  const SizedBox(height: 8),
                  Text(l.feedPictureFailed, style: p4.body(size: 13, color: p4.muted)),
                ],
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

/// The colour of an item's [FeedTone].
Color feedTone(BuildContext context, FeedTone tone) {
  final p4 = context.p4;
  return switch (tone) {
    FeedTone.review => p4.warn,
    FeedTone.info => p4.blue,
    FeedTone.neutral => p4.muted,
  };
}

/// An item's review status, translated, with its colour; null when it has none.
(String, Color)? feedStatus(BuildContext context, String? status) {
  final p4 = context.p4;
  final l = context.l10n;
  return switch (status) {
    null => null,
    'pending_review' => (l.feedStatusPending, p4.warn),
    'attended' => (l.feedStatusAttended, p4.ok),
    'confirmed' => (l.feedStatusConfirmed, p4.ok),
    'dismissed' => (l.feedStatusDismissed, p4.muted),
    final other => (other, p4.muted),
  };
}

/// When an item happened: the time today, else the date and time.
String? feedWhen(BuildContext context, DateTime? at) {
  final f = context.formats;
  final time = at?.toLocal();
  if (time == null) return null;
  final now = DateTime.now();
  return time.year == now.year && time.month == now.month && time.day == now.day
      ? f.clock(time)
      : '${DateFormat.MMMd(f.locale).format(time)} ${f.clock(time)}';
}
