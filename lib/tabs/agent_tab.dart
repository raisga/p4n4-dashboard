import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/agent_client.dart';
import '../core/settings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// Chat with a local Ollama model or a stateful Letta agent.
class AgentTab extends StatefulWidget {
  const AgentTab({super.key});

  @override
  State<AgentTab> createState() => _AgentTabState();
}

class _AgentTabState extends State<AgentTab> {
  P4Colors get p4 => context.p4;

  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _messages = <ChatMessage>[];

  AgentClient? _client;
  String? _clientKey;
  List<AgentOption>? _options;
  Object? _optionsError;
  StreamSubscription<String>? _reply;

  bool get _busy => _reply != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = SettingsScope.of(context);
    final key = '${s.agentBackend}|${s.host}|${s.lettaToken}';
    if (key != _clientKey) {
      _clientKey = key;
      _client = switch (s.agentBackend) {
        AgentBackend.ollama => OllamaClient(s.url(11434)),
        AgentBackend.letta => LettaClient(s.url(8283), token: s.lettaToken),
      };
      _loadOptions();
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

  Future<void> _loadOptions() async {
    final client = _client!;
    setState(() {
      _options = null;
      _optionsError = null;
    });
    try {
      final opts = await client.listOptions();
      if (!mounted || client != _client) return;
      setState(() => _options = opts);
      final s = SettingsScope.of(context);
      final current = _selected(s);
      if (opts.isNotEmpty && !opts.any((o) => o.id == current)) _select(s, opts.first.id);
    } catch (e) {
      if (mounted && client == _client) setState(() => _optionsError = e);
    }
  }

  String _selected(AppSettings s) => s.agentBackend == AgentBackend.ollama ? s.ollamaModel : s.lettaAgentId;

  void _select(AppSettings s, String id) {
    if (s.agentBackend == AgentBackend.ollama) {
      s.ollamaModel = id;
    } else {
      s.lettaAgentId = id;
    }
  }

  void _send() {
    final text = _input.text.trim();
    final s = SettingsScope.of(context);
    final target = _selected(s);
    if (text.isEmpty || _busy || target.isEmpty) return;

    final reply = ChatMessage('assistant', '');
    setState(() {
      _messages.add(ChatMessage('user', text));
      _input.clear();
    });
    final history = List.of(_messages);
    setState(() => _messages.add(reply));
    _scrollToEnd();

    _reply = _client!
        .send(target, history)
        .listen(
          (chunk) {
            setState(() => reply.content += chunk);
            _scrollToEnd();
          },
          onError: (Object e) => _finish(reply, error: e),
          onDone: () => _finish(reply),
          cancelOnError: true,
        );
  }

  void _stop() {
    _reply?.cancel();
    _finish(_messages.last);
  }

  void _finish(ChatMessage reply, {Object? error}) {
    if (!mounted) return;
    setState(() {
      _reply = null;
      if (error != null) {
        if (reply.content.isEmpty) _messages.remove(reply);
        _messages.add(ChatMessage('error', '$error'));
      } else if (reply.content.isEmpty) {
        reply.content = '(stopped)';
      }
    });
    _scrollToEnd();
    _focus.requestFocus();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
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
    final s = SettingsScope.of(context);
    return Column(
      children: [
        _toolbar(s),
        const Divider(height: 1),
        Expanded(child: _messages.isEmpty ? _empty(s) : _list()),
        const Divider(height: 1),
        _composer(s),
      ],
    );
  }

  Widget _toolbar(AppSettings s) {
    final opts = _options;
    final selected = _selected(s);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<AgentBackend>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              shape: const RoundedRectangleBorder(),
              selectedBackgroundColor: p4.accent,
              selectedForegroundColor: p4.onAccent,
              textStyle: p4.mono(size: 11, weight: FontWeight.w600),
              side: BorderSide(color: p4.border2),
            ),
            segments: const [
              ButtonSegment(
                value: AgentBackend.ollama,
                label: Text('OLLAMA'),
                icon: Icon(Icons.psychology_outlined, size: 16),
              ),
              ButtonSegment(
                value: AgentBackend.letta,
                label: Text('LETTA'),
                icon: Icon(Icons.smart_toy_outlined, size: 16),
              ),
            ],
            selected: {s.agentBackend},
            onSelectionChanged: _busy ? null : (v) => s.agentBackend = v.first,
          ),
          if (opts == null && _optionsError == null)
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent))
          else if (_optionsError != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StatusIndicator(Health.down),
                IconButton(tooltip: 'Retry', onPressed: _loadOptions, icon: const Icon(Icons.refresh, size: 18)),
              ],
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
              child: DropdownButtonFormField<String>(
                key: ValueKey('$_clientKey|$selected'),
                initialValue: opts!.any((o) => o.id == selected) ? selected : null,
                isExpanded: true,
                hint: Text(opts.isEmpty ? 'none available' : 'select', style: p4.mono(size: 12)),
                decoration: InputDecoration(labelText: s.agentBackend == AgentBackend.ollama ? 'model' : 'agent'),
                dropdownColor: p4.bg3,
                style: p4.mono(size: 12, color: p4.text),
                items: [
                  for (final o in opts)
                    DropdownMenuItem(
                      value: o.id,
                      child: Text(o.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _busy ? null : (v) => v == null ? null : _select(s, v),
              ),
            ),
          if (_messages.isNotEmpty)
            OutlinedButton.icon(
              onPressed: _busy ? null : () => setState(_messages.clear),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('CLEAR'),
            ),
        ],
      ),
    );
  }

  Widget _empty(AppSettings s) {
    final ollama = s.agentBackend == AgentBackend.ollama;
    if (_optionsError != null) {
      return EmptyState(
        icon: Icons.cloud_off_outlined,
        title: '${ollama ? 'Ollama' : 'Letta'} unreachable',
        message: '${s.url(ollama ? 11434 : 8283)}\n$_optionsError',
        actions: [OutlinedButton(onPressed: _loadOptions, child: const Text('RETRY'))],
      );
    }
    if (_options != null && _options!.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_outlined,
        title: ollama ? 'No models pulled' : 'No agents found',
        message: ollama
            ? 'Pull one first, e.g. `docker exec ollama ollama pull llama3.2`.'
            : 'Create an agent in the Letta ADE, then retry.',
        actions: [OutlinedButton(onPressed: _loadOptions, child: const Text('RETRY'))],
      );
    }
    return EmptyState(
      icon: Icons.forum_outlined,
      title: 'Chat with your ${ollama ? 'local model' : 'agent'}',
      message: ollama
          ? 'Messages go straight to Ollama on ${s.host}. History stays in this session only.'
          : 'Letta agents keep their own memory across sessions.',
    );
  }

  Widget _list() => ListView.builder(
    controller: _scroll,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    itemCount: _messages.length,
    itemBuilder: (context, i) => _Bubble(_messages[i], streaming: _busy && i == _messages.length - 1),
  );

  Widget _composer(AppSettings s) {
    final ready = _selected(s).isNotEmpty && _optionsError == null;
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
                  style: p4.display(size: 14, color: p4.text, weight: FontWeight.w400, spacing: 0),
                  decoration: InputDecoration(
                    hintText: ready ? 'Message… (Shift+Enter for newline)' : 'Select a model or agent first',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: _busy
                  ? OutlinedButton(onPressed: _stop, child: const Icon(Icons.stop, size: 18))
                  : FilledButton(onPressed: ready ? _send : null, child: const Icon(Icons.arrow_upward, size: 18)),
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
    final user = msg.role == 'user';
    final error = msg.role == 'error';
    final label = user ? 'you' : (error ? 'error' : 'agent');
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            color: user ? p4.accent.withValues(alpha: 0.1) : p4.bg2,
            border: Border(
              left: BorderSide(color: error ? p4.err : (user ? p4.border : p4.accent), width: user ? 1 : 2),
              top: BorderSide(color: p4.border),
              right: BorderSide(color: user ? p4.accent.withValues(alpha: 0.5) : p4.border),
              bottom: BorderSide(color: p4.border),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '// ${label.toUpperCase()}',
                style: p4.mono(size: 10, color: error ? p4.err : p4.muted, spacing: 0.12),
              ),
              const SizedBox(height: 6),
              if (msg.content.isEmpty && streaming)
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: p4.accent))
              else
                SelectableText(
                  msg.content,
                  style: error
                      ? p4.mono(size: 12, color: p4.text, spacing: 0)
                      : p4
                            .display(size: 14, color: p4.text, weight: FontWeight.w400, spacing: 0)
                            .copyWith(height: 1.55),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
