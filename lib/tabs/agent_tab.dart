import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/agent_client.dart';
import '../core/brand.dart';
import '../core/session.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/common.dart';

/// Chat with the deployment's assistant, an Ollama model or a Letta agent,
/// through p4n4-api.
///
/// Which one is a deployment-wide setting kept by the API. Admins and power
/// users choose it here; viewers just chat, and the API holds them to the
/// chosen one whatever this screen shows.
class AgentTab extends StatefulWidget {
  const AgentTab({super.key});

  @override
  State<AgentTab> createState() => _AgentTabState();
}

class _AgentTabState extends State<AgentTab> {
  P4Colors get p4 => context.p4;
  AppLocalizations get l => context.l10n;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _messages = <ChatMessage>[];

  AgentApi? _api;
  AssistantConfig? _config;
  List<AgentOption>? _options;
  Object? _loadError;
  bool _saving = false;
  StreamSubscription<String>? _reply;

  bool get _busy => _reply != null;
  bool get _technical => SessionScope.of(context).isTechnical;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = SettingsScope.of(context).apiUri;
    if (api != _api?.api) {
      _api = AgentApi(api);
      _load();
    }
  }

  @override
  void dispose() {
    _reply?.cancel();
    _input.dispose();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// The assistant's config, then what can be chosen for its backend.
  Future<void> _load() async {
    final api = _api!;
    // Admins and power users hand the brand's assistant to a deployment that
    // never chose one (the API lets only them choose).
    final seed = _technical ? SettingsScope.of(context).assistantDefault : null;
    setState(() {
      _config = null;
      _options = null;
      _loadError = null;
    });
    try {
      var config = await api.config();
      if (seed != null && !config.everChosen) config = await _seed(api, seed) ?? config;
      final options = await api.listOptions(config.backend);
      if (!mounted || api != _api) return;
      setState(() {
        _config = config;
        _options = options;
      });
    } catch (e) {
      if (mounted && api == _api) setState(() => _loadError = e);
    }
  }

  /// Saves [seed] as the deployment's assistant if it's installed there; a
  /// failure only means the API's own default stays.
  static Future<AssistantConfig?> _seed(AgentApi api, AssistantConfig seed) async {
    try {
      if (!seedAvailable(seed, await api.listOptions(seed.backend))) return null;
      return await api.setConfig(seed);
    } on AgentException {
      return null;
    }
  }

  /// Who the conversation goes to: the chosen model or agent, else the first
  /// one listed (as the API does).
  String? get _target {
    final options = _options;
    if (options == null || options.isEmpty) return null;
    final chosen = _config?.chosen;
    return options.any((o) => o.id == chosen) ? chosen : options.first.id;
  }

  /// Saves a new choice for everyone, then reloads what can be chosen.
  Future<void> _choose(AssistantConfig next) async {
    final api = _api!;
    final backendChanged = next.backend != _config?.backend;
    setState(() {
      _saving = true;
      _config = next;
      if (backendChanged) _options = null;
    });
    try {
      final saved = await api.setConfig(next);
      final options = backendChanged ? await api.listOptions(saved.backend) : _options;
      if (!mounted || api != _api) return;
      setState(() {
        _config = saved;
        _options = options;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.assistantSaveFailed('$e'))));
      await _load();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _send([String? suggestion]) {
    final text = (suggestion ?? _input.text).trim();
    final target = _target;
    final config = _config;
    if (text.isEmpty || _busy || target == null || config == null) return;

    final reply = ChatMessage('assistant', '');
    setState(() {
      _messages.add(ChatMessage('user', text));
      _input.clear();
    });
    final history = List.of(_messages);
    setState(() => _messages.add(reply));
    _scrollToEnd();

    _reply = _api!
        .send(config.backend, target, history)
        .listen(
          (chunk) {
            setState(() => reply.content += chunk);
            _scrollToEnd();
          },
          onError: (Object e) => _finish(reply, error: e is AgentException ? e : AgentException('$e')),
          onDone: () => _finish(reply),
          cancelOnError: true,
        );
  }

  void _stop() {
    _reply?.cancel();
    _finish(_messages.last);
  }

  void _finish(ChatMessage reply, {AgentException? error}) {
    if (!mounted) return;
    setState(() {
      _reply = null;
      if (error != null) {
        if (reply.content.isEmpty) _messages.remove(reply);
        _messages.add(ChatMessage('error', _describe(error), error: error));
      } else if (reply.content.isEmpty) {
        reply.content = l.agentStopped;
      }
    });
    // Someone changed the assistant meanwhile: pick up the new one.
    if (error?.code == 'assistant_restricted') _load();
    _scrollToEnd();
    _focus.requestFocus();
  }

  /// What went wrong, in words that fit who's reading: the API's own message
  /// for admins and power users, plain language for viewers.
  String _describe(AgentException e) => switch (e) {
    _ when _technical => e.message,
    AgentException(statusCode: 401) => l.sessionExpired,
    AgentException(code: 'assistant_restricted') => l.assistantErrorChanged,
    _ when e.unavailable => l.assistantErrorUnavailable,
    _ => l.assistantErrorGeneric,
  };

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients || !mounted) return;
      // Settings → Accessibility → Reduce motion, or the device's own setting.
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      } else {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _toolbar(),
        const Divider(height: 1),
        Expanded(child: _messages.isEmpty ? _empty() : _list()),
        const Divider(height: 1),
        _composer(),
      ],
    );
  }

  Widget _toolbar() {
    final config = _config;
    final options = _options;
    final ollama = (config?.backend ?? AgentBackend.ollama) == AgentBackend.ollama;
    final health = switch ((_loadError, options)) {
      (_?, _) => Health.down,
      (_, null) => Health.pending,
      (_, []) => Health.unknown,
      _ => Health.up,
    };
    return Container(
      width: double.infinity,
      color: p4.bg2,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, color: p4.accent, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(l.navAgent, overflow: TextOverflow.ellipsis, style: p4.display(size: 17)),
              ),
              const SizedBox(width: 12),
              Flexible(child: StatusIndicator(health)),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Choosing the assistant is configuration: not for viewers, and
              // the API refuses it from them too.
              if (_technical && config != null) ...[
                SegmentedButton<AgentBackend>(
                  showSelectedIcon: false,
                  // Product names: not translated.
                  segments: const [
                    ButtonSegment(
                      value: AgentBackend.ollama,
                      label: Text('Ollama'),
                      icon: Icon(Icons.psychology_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: AgentBackend.letta,
                      label: Text('Letta'),
                      icon: Icon(Icons.smart_toy_outlined, size: 16),
                    ),
                  ],
                  selected: {config.backend},
                  onSelectionChanged: _busy || _saving ? null : (v) => _choose(config.copyWith(backend: v.first)),
                ),
                if (options != null && options.isNotEmpty)
                  Tooltip(
                    message: ollama ? l.assistantSharedModel : l.assistantSharedAgent,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('${config.backend}|$_target'),
                        initialValue: _target,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: ollama ? l.agentModel : l.agentAgent),
                        dropdownColor: p4.bg2,
                        style: p4.mono(size: 13, color: p4.text, spacing: 0),
                        items: [
                          for (final o in options)
                            DropdownMenuItem(
                              value: o.id,
                              child: Text(o.label, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: _busy || _saving
                            ? null
                            : (v) => v == null || v == _target ? null : _choose(config.copyWith(id: v)),
                      ),
                    ),
                  ),
              ],
              if (_messages.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => setState(_messages.clear),
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  label: Text(l.clear),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    final config = _config;
    final options = _options;
    final ollama = (config?.backend ?? AgentBackend.ollama) == AgentBackend.ollama;
    if (_loadError case final error?) {
      return _technical
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              color: p4.err,
              title: l.agentUnreachable(ollama ? 'Ollama' : 'Letta'),
              message: l.assistantUnavailableMsg,
              details: '$error',
              actions: [OutlinedButton(onPressed: _load, child: Text(l.retry))],
            )
          : EmptyState(
              icon: Icons.cloud_off_outlined,
              color: p4.err,
              title: l.assistantUnavailable,
              message: l.assistantUnavailableMsg,
              actions: [OutlinedButton(onPressed: _load, child: Text(l.retry))],
            );
    }
    if (config == null || options == null) return LoadingState(l.signInConnecting);
    if (options.isEmpty) {
      return _technical
          ? EmptyState(
              icon: Icons.inbox_outlined,
              title: ollama ? l.agentNoModels : l.agentNoAgents,
              message: ollama ? l.agentNoModelsMsg : l.agentNoAgentsMsg,
              actions: [OutlinedButton(onPressed: _load, child: Text(l.retry))],
            )
          : EmptyState(icon: Icons.inbox_outlined, title: l.assistantNotSetUp, message: l.assistantNotSetUpMsg);
    }
    return EmptyState(
      icon: Icons.forum_outlined,
      title: l.assistantChat,
      message: l.assistantChatMsg,
      details: _technical ? (ollama ? l.agentOllamaMsg(BrandScope.of(context).platform) : l.agentLettaMsg) : null,
      actions: [
        for (final q in [l.assistantSuggestStatus, l.assistantSuggestDevice, l.assistantSuggestHelp])
          ActionChip(
            avatar: Icon(Icons.chat_bubble_outline, size: 16, color: p4.accent),
            label: Text(q),
            onPressed: () => _send(q),
          ),
      ],
    );
  }

  Widget _list() => ListView.builder(
    controller: _scroll,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    itemCount: _messages.length,
    itemBuilder: (context, i) => _Bubble(_messages[i], streaming: _busy && i == _messages.length - 1),
  );

  Widget _composer() {
    final ready = _target != null && _loadError == null && !_saving;
    final hint = switch (ready) {
      true => l.agentMessageHint,
      false when _config == null && _loadError == null => l.signInConnecting,
      false => _technical ? l.agentSelectFirst : l.assistantInputUnavailable,
    };
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CallbackShortcuts(
                bindings: {const SingleActivator(LogicalKeyboardKey.enter): _send},
                child: TextField(
                  controller: _input,
                  focusNode: _focus,
                  enabled: ready,
                  minLines: 1,
                  maxLines: 6,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  style: p4.body(size: 15),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: p4.body(size: 14, color: p4.muted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              width: 46,
              child: _busy
                  ? IconButton.outlined(
                      tooltip: l.stopTooltip,
                      onPressed: _stop,
                      icon: const Icon(Icons.stop, size: 20),
                    )
                  : IconButton.filled(
                      tooltip: l.sendTooltip,
                      onPressed: ready ? _send : null,
                      style: IconButton.styleFrom(backgroundColor: p4.accent, foregroundColor: p4.onAccent),
                      icon: const Icon(Icons.arrow_upward, size: 20),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.msg, {required this.streaming});

  final ChatMessage msg;
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final p4 = context.p4;
    final l = context.l10n;
    final user = msg.role == 'user';
    final error = msg.role == 'error';
    final label = user ? l.bubbleYou : (error ? l.bubbleError : l.bubbleAgent);
    final (fill, border) = switch ((user, error)) {
      (true, _) => (p4.accent.withValues(alpha: 0.12), p4.accent.withValues(alpha: 0.35)),
      (_, true) => (p4.err.withValues(alpha: 0.08), p4.err.withValues(alpha: 0.5)),
      _ => (p4.bg2, p4.border),
    };
    const r = Radius.circular(14);
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
            borderRadius: BorderRadius.only(
              topLeft: r,
              topRight: r,
              bottomLeft: user ? r : const Radius.circular(4),
              bottomRight: user ? const Radius.circular(4) : r,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (error) ...[Icon(Icons.error_outline, size: 14, color: p4.err), const SizedBox(width: 6)],
                  Text(
                    label,
                    style: p4.display(size: 12, color: error ? p4.err : p4.muted, weight: FontWeight.w600, spacing: 0),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (msg.content.isEmpty && streaming)
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent))
              else
                SelectableText(msg.content, style: p4.body(size: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
