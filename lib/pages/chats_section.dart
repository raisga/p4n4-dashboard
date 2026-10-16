import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/chats.dart';
import '../core/format.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Settings → chats: the messaging chats linked to the project's bot (e.g.
/// on Telegram), which get its alerts and may ask it about the project.
/// Admins make a one-time code to link one, and unlink any. Admins only; the
/// API checks that too.
class ChatsSection extends StatefulWidget {
  const ChatsSection({super.key, this.watchEvery = const Duration(seconds: 4)});

  /// How often the list is read while a code is showing, to see its chat arrive.
  final Duration watchEvery;

  @override
  State<ChatsSection> createState() => _ChatsSectionState();
}

class _ChatsSectionState extends State<ChatsSection> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  ChatsPage? _page;
  Object? _loadError;
  String? _actionError;
  bool _busy = false;
  Uri? _api;

  /// The code on screen, and how many chats there were when it was made.
  LinkCode? _code;
  int _before = 0;
  Timer? _watch;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = SettingsScope.of(context).apiUri;
    if (api != _api) {
      _api = api;
      _clearCode();
      _load();
    }
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = _api!;
    try {
      final page = await ChatsApi(api).list();
      if (!mounted || api != _api) return;
      setState(() {
        _page = page;
        _loadError = null;
      });
      // The code was used: its chat is in the list now
      if (_code != null && page.chats.length > _before) _clearCode();
    } catch (e) {
      if (mounted && api == _api) setState(() => _loadError = e);
    }
  }

  Future<void> _run(Future<void> Function(ChatsApi api) change) async {
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await change(ChatsApi(_api!));
    } catch (e) {
      if (mounted) setState(() => _actionError = '$e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _newCode() => _run((api) async {
    final code = await api.newCode();
    if (!mounted) return;
    setState(() {
      _code = code;
      _before = _page?.chats.length ?? 0;
    });
    _watch?.cancel();
    _watch = Timer.periodic(widget.watchEvery, (_) {
      final expires = _code?.expiresAt;
      if (expires != null && DateTime.now().isAfter(expires)) {
        setState(_clearCode);
      } else {
        _load();
      }
    });
  });

  void _clearCode() {
    _watch?.cancel();
    _watch = null;
    _code = null;
  }

  Future<void> _unlink(LinkedChat chat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.chatsUnlinkTitle(chat.name ?? chat.id)),
        content: Text(l.chatsUnlinkBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.chatsUnlink)),
        ],
      ),
    );
    if (ok != true) return;
    await _run((api) => api.unlink(chat.id));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final page = _page;
    final muted = p4.body(size: 13, color: p4.muted);
    final error = p4.mono(color: p4.err, spacing: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.chatsNote, style: muted),
        const SizedBox(height: 12),
        for (final channel in page?.channels ?? const <ChatChannel>[]) ...[
          _ChannelLine(channel: channel),
          const SizedBox(height: 8),
        ],
        if (_actionError case final message?) ...[Text(message, style: error), const SizedBox(height: 8)],
        if (_loadError != null && page == null)
          Row(
            children: [
              Expanded(child: Text(l.chatsLoadFailed('$_loadError'), style: error)),
              TextButton(onPressed: _load, child: Text(l.retry)),
            ],
          )
        else if (page == null)
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent)),
          )
        else ...[
          if (page.chats.isEmpty) Text(l.chatsNone, style: muted),
          for (final chat in page.chats) _ChatRow(chat: chat, onUnlink: _busy ? null : () => _unlink(chat)),
          const SizedBox(height: 4),
          if (_code case final code?)
            _CodeCard(code: code, channels: page.channels)
          else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _busy ? null : _newCode,
                icon: const Icon(Icons.add_link, size: 18),
                label: Text(l.chatsLink),
              ),
            ),
        ],
      ],
    );
  }
}

/// The channel, its bot, and whether it really sends.
class _ChannelLine extends StatelessWidget {
  const _ChannelLine({required this.channel});

  final ChatChannel channel;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final note = switch (channel.state) {
      'mock' => l.chatsMock,
      'off' => l.chatsOff,
      _ => null,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.send_outlined, size: 16, color: p4.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [channel.name ?? channel.id, ?channel.bot].join(' · '),
                style: p4.display(size: 14, weight: FontWeight.w500, spacing: 0),
              ),
              if (note != null) Text(note, style: p4.body(size: 12, color: p4.warn)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.chat, this.onUnlink});

  final LinkedChat chat;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final f = context.formats;
    final at = chat.linkedAt;
    final date = at == null ? null : '${DateFormat.yMMMd(f.locale).format(at)} ${f.clock(at)}';
    final details = [
      if (date != null) chat.linkedBy == null ? l.chatsLinkedOn(date) : l.chatsLinkedBy(date, chat.linkedBy!),
      if (chat.muted.isNotEmpty) l.chatsMuted(chat.muted.join(', ')),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chat.name ?? chat.id,
                  overflow: TextOverflow.ellipsis,
                  style: p4.display(size: 14, weight: FontWeight.w500, spacing: 0),
                ),
                if (details.isNotEmpty) Text(details.join(' · '), style: p4.body(size: 12, color: p4.muted)),
              ],
            ),
          ),
          IconButton(
            tooltip: l.chatsUnlink,
            onPressed: onUnlink,
            icon: Icon(Icons.link_off, size: 18, color: p4.muted),
          ),
        ],
      ),
    );
  }
}

/// A fresh code: its link to open on the phone, the command to send by hand,
/// and until when it works.
class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code, required this.channels});

  final LinkCode code;
  final List<ChatChannel> channels;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final f = context.formats;
    final link = code.links.firstOrNull;
    final bot = channels.where((c) => c.id == link?.channel).firstOrNull?.bot ?? channels.firstOrNull?.bot;
    final command = code.command ?? code.code;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p4.bg2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p4.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.chatsLinkHow(bot ?? l.chatsTheBot), style: p4.body(size: 13, color: p4.muted)),
          const SizedBox(height: 10),
          SelectableText(
            command,
            style: p4.mono(size: 18, color: p4.text, weight: FontWeight.w600, spacing: 0.08),
          ),
          if (code.expiresAt case final expires?) ...[
            const SizedBox(height: 4),
            Text(l.chatsCodeExpires(f.clock(expires)), style: p4.body(size: 12, color: p4.muted)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (link != null) ...[
                FilledButton.icon(
                  onPressed: () => launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l.open),
                ),
                OutlinedButton.icon(
                  onPressed: () => Clipboard.setData(ClipboardData(text: link.url)),
                  icon: const Icon(Icons.link, size: 16),
                  label: Text(l.chatsCopyLink),
                ),
              ],
              OutlinedButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: command)),
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l.chatsCopyCommand),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
