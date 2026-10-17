import 'package:flutter/foundation.dart';

import '../api/agent_client.dart' show ChatMessage;
import '../api/fleet.dart' show Deployment;
import 'settings.dart';

/// The Assistant conversation, kept by the shell rather than the tab so it
/// outlives the tab being rebuilt, and saved with [AppSettings] per
/// deployment and account so it outlives a reload and signing out and back in.
class ChatHistory extends ChangeNotifier {
  ChatHistory(this._settings, this._deployment, this._who)
    : messages = [
        for (final m in _settings.chatOf(_deployment, _who))
          if (m case {'role': final role, 'content': final content} when content.isNotEmpty) ChatMessage(role, content),
      ];

  final AppSettings _settings;
  final Deployment _deployment;
  final String _who;

  /// Only the most recent messages are saved, to keep within browser storage.
  static const saved = 200;

  /// Oldest first. Change it through [add], [remove], [truncate] and [clear], or call
  /// [changed] after editing a message in place.
  final List<ChatMessage> messages;

  void add(ChatMessage m) {
    messages.add(m);
    changed();
  }

  void remove(ChatMessage m) {
    messages.remove(m);
    changed();
  }

  /// Drops message [from] and everything after it (to ask the last question again).
  void truncate(int from) {
    messages.removeRange(from, messages.length);
    changed();
  }

  void clear() {
    messages.clear();
    changed();
  }

  /// Redraws listeners and, with [save], stores the conversation. A streaming
  /// reply passes false for each chunk and saves once it ends; an empty reply
  /// (cut off by a reload) isn't restored.
  void changed({bool save = true}) {
    notifyListeners();
    if (!save) return;
    final kept = messages.length > saved ? messages.sublist(messages.length - saved) : messages;
    _settings.setChatOf(_deployment, _who, [for (final m in kept) m.toJson()]);
  }
}
