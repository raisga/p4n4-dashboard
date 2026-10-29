/// The demo's store: the days a project recorded for it (`demo/store.json`),
/// laid over the viewer's calendar.
///
/// The file, which the project generates from its own simulator:
///
/// ```json
/// {"lang": "en", "currency": "USD", "anchor": "2026-09-21",
///  "project": {...GET /api/v1/project...}, "model": "an-ollama-model",
///  "feed_title": "...", "actions": {"attended": "Attend", ...},
///  "alert_titles": {"<badge>": "..."}, "home": {"": "# Markdown", "es": "..."},
///  "banner": {"en": "..."}, "vision": {...GET /api/v1/project/vision...},
///  "stacks": [{"name": "iot", "services": [["grafana", "grafana/grafana-oss:12"]]}],
///  "chats": {...GET /api/v1/chats...}, "charts": {...the Charts tab: demo_charts.dart...},
///  "repeat": true,
///  "review": {"pending": ["attended", "dismissed"], "done": ["pending_review"], "status": {}},
///  "answers": [{"q": ["How are we doing?", ...], "steps": [["tool", {"en": "label"}]], "text": "Markdown"}],
///  "days": [{"date", "items": [{"s": <seconds after midnight>, ...feed item}],
///            "reviews": {"<alert id>": [<seconds>, "attended"]},
///            "summary", "ranking", "purchase", "layout",
///            "series": {"<name>": [[<seconds>, <key>, <value>], ...]}}]}
/// ```
///
/// Camera `url`s in the project may be paths next to the app (`demo/cam.mp4`).
/// The recorded days repeat over the calendar, unless `repeat` is false: then
/// the last one is today, the one before it yesterday, and so on. `review`
/// says which actions an alert offers while pending and once reviewed, and the
/// status each action leaves it in (the action's own id by default). A
/// project with `answers` has the assistant answer from them (demo_agent.dart),
/// not from the analytics, and a day's `summary`, `ranking`, `purchase` and
/// `layout` may then be left out. A feed item with `"image": true` has its
/// picture at `demo/feed/<item id>.jpg`, the id's `:` and `/` as `_`.
library;

import 'dart:math' as math;

/// One recorded day: its feed (times in seconds after midnight), the staff's
/// reviews and the analytics the assistant answers from.
class DemoDay {
  DemoDay(Map<String, dynamic> j)
    : date = j['date'] as String,
      items = [for (final i in j['items'] as List) (i as Map).cast<String, dynamic>()],
      reviews = {
        for (final MapEntry(:key, :value) in (j['reviews'] as Map).entries)
          key as String: ((value as List)[0] as num).toDouble(),
      },
      reviewStatus = {
        for (final MapEntry(:key, :value) in (j['reviews'] as Map).entries) key as String: (value as List)[1] as String,
      },
      summary = ((j['summary'] as Map?) ?? const {}).cast(),
      ranking = ((j['ranking'] as Map?) ?? const {}).cast(),
      purchase = ((j['purchase'] as Map?) ?? const {}).cast(),
      layout = ((j['layout'] as Map?) ?? const {}).cast(),
      series = {
        for (final MapEntry(:key, :value) in ((j['series'] as Map?) ?? const {}).entries)
          key as String: [for (final e in value as List) e as List],
      };

  final String date;
  final List<Map<String, dynamic>> items;

  /// Alert id → when staff reviewed it, and how.
  final Map<String, double> reviews;
  final Map<String, String> reviewStatus;

  final Map<String, dynamic> summary;
  final Map<String, dynamic> ranking;
  final Map<String, dynamic> purchase;
  final Map<String, dynamic> layout;

  /// Named series for the charts: `[seconds after midnight, key?, value?]` per entry.
  final Map<String, List<List<dynamic>>> series;

  /// `20261014`, as the recorded ids have it.
  String get stamp => date.replaceAll('-', '');
}

/// A recorded answer of the assistant: the questions it answers, the tools it
/// ran (each with its label by language) and its Markdown.
class DemoAnswer {
  DemoAnswer(Map<String, dynamic> j)
    : questions = [for (final q in j['q'] as List) q as String],
      steps = [
        for (final s in (j['steps'] as List?) ?? const [])
          ((s as List)[0] as String, ((s[1] as Map?) ?? const {}).cast<String, String>()),
      ],
      text = j['text'] as String;

  final List<String> questions;
  final List<(String, Map<String, String>)> steps;
  final String text;
}

/// A feed item placed on the viewer's calendar.
class DemoItem {
  DemoItem(this.json, this.at);

  final Map<String, dynamic> json;
  final DateTime at;

  String get id => json['id'] as String;
  bool get alert => json['kind'] == 'alert';
  String? get badge => json['badge'] as String?;
}

class DemoStore {
  DemoStore(Map<String, dynamic> j, {DateTime Function()? clock})
    : lang = j['lang'] as String,
      currency = j['currency'] as String,
      feedTitle = j['feed_title'] as String,
      actionLabels = (j['actions'] as Map).cast(),
      alertTitles = (j['alert_titles'] as Map).cast(),
      home = (j['home'] as Map).cast(),
      banner = ((j['banner'] as Map?) ?? const {}).cast(),
      project = (j['project'] as Map).cast(),
      model = j['model'] as String? ?? 'llama3.2',
      vision = (j['vision'] as Map?)?.cast(),
      stacks = [for (final s in (j['stacks'] as List?) ?? const []) (s as Map).cast<String, dynamic>()],
      chats = ((j['chats'] as Map?) ?? const {}).cast(),
      charts = (j['charts'] as Map?)?.cast(),
      anchor = DateTime.parse(j['anchor'] as String),
      days = [for (final d in j['days'] as List) DemoDay((d as Map).cast())],
      repeat = j['repeat'] as bool? ?? true,
      pendingActions = [for (final a in ((j['review'] as Map?)?['pending'] as List?) ?? _pending) a as String],
      doneActions = [for (final a in ((j['review'] as Map?)?['done'] as List?) ?? _done) a as String],
      actionStatus = (((j['review'] as Map?)?['status'] as Map?) ?? const {}).cast(),
      answers = [for (final a in (j['answers'] as List?) ?? const []) DemoAnswer((a as Map).cast())],
      _clock = clock ?? DateTime.now;

  static const _pending = ['attended', 'dismissed'];
  static const _done = ['pending_review'];

  final String lang;
  final String currency;
  final String feedTitle;
  final Map<String, String> actionLabels;
  final Map<String, String> alertTitles;

  /// HOME.md by language code (`''` for the default).
  final Map<String, String> home;

  /// The note above every view, by language code; the dashboard's own when empty.
  final Map<String, String> banner;

  /// What p4n4-api would answer for `GET /api/v1/project`.
  final Map<String, dynamic> project;

  /// The assistant's model, as Ollama would list it.
  final String model;
  final Map<String, dynamic>? vision;

  /// The deployment's Compose stacks and their services (name, image).
  final List<Map<String, dynamic>> stacks;

  /// Its messaging channels and linked chats.
  final Map<String, dynamic> chats;

  /// The Charts tab's panels, when the project has them.
  final Map<String, dynamic>? charts;

  /// The first recorded day: recorded days repeat from it, weekday for weekday.
  final DateTime anchor;
  final List<DemoDay> days;

  /// Whether the recorded days repeat over the calendar (else they end today).
  final bool repeat;

  /// The actions an alert offers while pending review, and once reviewed.
  final List<String> pendingActions;
  final List<String> doneActions;

  /// The status an action leaves an alert in, when it isn't the action's id.
  final Map<String, String> actionStatus;

  /// The assistant's recorded answers; empty for one that answers from the analytics.
  final List<DemoAnswer> answers;
  final DateTime Function() _clock;

  /// Reviews made in the preview, by item id: they win over the recording's.
  final _reviews = <String, String>{};

  DateTime get now => _clock();

  /// The local midnight [back] days before today.
  DateTime midnight(int back) {
    final n = now;
    return DateTime(n.year, n.month, n.day - back);
  }

  /// The recorded day shown on the day [back] days before today; without
  /// [repeat], none before the first.
  DemoDay? dayAt(int back) {
    if (!repeat) return back < days.length ? days[days.length - 1 - back] : null;
    return dayFor(back);
  }

  /// The recorded day shown on the day [back] days before today.
  DemoDay dayFor(int back) {
    if (!repeat) return days[(days.length - 1 - back).clamp(0, days.length - 1)];
    final m = midnight(back);
    final index = DateTime.utc(
      m.year,
      m.month,
      m.day,
    ).difference(DateTime.utc(anchor.year, anchor.month, anchor.day)).inDays;
    return days[index % days.length];
  }

  /// Everything that has happened in the last [span] days (today included),
  /// newest first: today's only up to now, the rest arriving as its time comes.
  List<DemoItem> items({int span = 8}) {
    final out = <DemoItem>[];
    final current = now;
    for (var back = 0; back < span; back++) {
      final day = dayAt(back);
      if (day == null) break;
      final base = midnight(back);
      final stamp = _stamp(base);
      for (final raw in day.items) {
        final at = base.add(Duration(milliseconds: ((raw['s'] as num) * 1000).round()));
        if (at.isAfter(current)) break; // items are in time order
        final sourceId = raw['id'] as String;
        // Repeated days get their own ids; days that don't repeat keep the recording's.
        final id = repeat ? sourceId.replaceFirst(day.stamp, stamp) : sourceId;
        final json = {...raw, 'id': id, 'time': at.toUtc().toIso8601String()}..remove('s');
        if (raw['kind'] == 'alert') {
          final reviewedAt = day.reviews[sourceId];
          final reviewed = reviewedAt != null && !base.add(Duration(seconds: reviewedAt.round())).isAfter(current);
          final status = _reviews[id] ?? (reviewed ? day.reviewStatus[sourceId]! : 'pending_review');
          json['status'] = status;
          json['actions'] = [
            for (final a in status == 'pending_review' ? pendingActions : doneActions)
              {'id': a, 'label': actionLabels[a] ?? a},
          ];
        }
        out.add(DemoItem(json, at));
      }
    }
    out.sort((a, b) => b.at.compareTo(a.at));
    return out;
  }

  /// Series [name]'s entries over the last [span] days (today included, up
  /// to now), each with its time.
  List<(DateTime, List<dynamic>)> entries(String name, {int span = 1}) {
    final current = now;
    return [
      for (var back = span - 1; back >= 0; back--)
        for (final e in dayAt(back)?.series[name] ?? const <List<dynamic>>[])
          if (midnight(back).add(Duration(seconds: (e[0] as num).round())) case final at when !at.isAfter(current))
            (at, e),
    ];
  }

  /// `GET /api/v1/feed`; without [canAct] (viewers), items carry no actions.
  Map<String, dynamic> feed({int limit = 50, double? before, bool canAct = true}) {
    final all = items();
    final page = [
      for (final i in all)
        if (before == null || i.at.millisecondsSinceEpoch / 1000 < before) i,
    ].take(limit).toList();
    return {
      'title': feedTitle,
      'items': [
        for (final i in page) canAct ? i.json : ({...i.json}..remove('actions')),
      ],
      'counts': {'pending': all.where((i) => i.alert && i.json['status'] == 'pending_review').length},
      'next_before': page.length == limit ? page.last.at.millisecondsSinceEpoch / 1000 : null,
      'can_act': canAct,
    };
  }

  /// `POST /api/v1/feed/<id>/action`: false when there's no such alert.
  bool act(String id, String action) {
    if (!items().any((i) => i.id == id && i.alert)) return false;
    _reviews[id] = actionStatus[action] ?? action;
    return true;
  }

  /// The recorded answer to [question]: the one asked in the same words
  /// (case, accents and punctuation aside), else the one sharing most of its
  /// words; null when none shares any.
  DemoAnswer? answerTo(String question) {
    final words = _words(question);
    DemoAnswer? best;
    var score = 0.0;
    for (final a in answers) {
      for (final q in a.questions) {
        final asked = _words(q);
        if (asked.join(' ') == words.join(' ')) return a;
        final shared = asked.toSet().intersection(words.toSet()).length;
        final s = shared / math.max(asked.length, words.length);
        if (s > score) (best, score) = (a, s);
      }
    }
    return score >= 0.5 ? best : null;
  }

  static const _plain = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n'};

  static List<String> _words(String text) => [
    for (final w in text.toLowerCase().split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)))
      if (w.isNotEmpty) w.split('').map((c) => _plain[c] ?? c).join(),
  ];

  static String _stamp(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}
