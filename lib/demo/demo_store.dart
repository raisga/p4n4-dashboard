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
///  "days": [{"date", "items": [{"s": <seconds after midnight>, ...feed item}],
///            "reviews": {"<alert id>": [<seconds>, "attended"]},
///            "summary", "ranking", "purchase", "layout",
///            "series": {"<name>": [[<seconds>, <key>, <value>], ...]}}]}
/// ```
///
/// Camera `url`s in the project may be paths next to the app (`demo/cam.mp4`).
library;

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
      summary = (j['summary'] as Map).cast(),
      ranking = (j['ranking'] as Map).cast(),
      purchase = (j['purchase'] as Map).cast(),
      layout = (j['layout'] as Map).cast(),
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
      _clock = clock ?? DateTime.now;

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
  final DateTime Function() _clock;

  /// Reviews made in the preview, by item id: they win over the recording's.
  final _reviews = <String, String>{};

  DateTime get now => _clock();

  /// The local midnight [back] days before today.
  DateTime midnight(int back) {
    final n = now;
    return DateTime(n.year, n.month, n.day - back);
  }

  /// The recorded day shown on the day [back] days before today.
  DemoDay dayFor(int back) {
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
      final day = dayFor(back);
      final base = midnight(back);
      final stamp = _stamp(base);
      for (final raw in day.items) {
        final at = base.add(Duration(milliseconds: ((raw['s'] as num) * 1000).round()));
        if (at.isAfter(current)) break; // items are in time order
        final sourceId = raw['id'] as String;
        final id = sourceId.replaceFirst(day.stamp, stamp);
        final json = {...raw, 'id': id, 'time': at.toUtc().toIso8601String()}..remove('s');
        if (raw['kind'] == 'alert') {
          final reviewedAt = day.reviews[sourceId];
          final reviewed = reviewedAt != null && !base.add(Duration(seconds: reviewedAt.round())).isAfter(current);
          final status = _reviews[id] ?? (reviewed ? day.reviewStatus[sourceId]! : 'pending_review');
          json['status'] = status;
          json['actions'] = [
            for (final a in status == 'pending_review' ? ['attended', 'dismissed'] : ['pending_review'])
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
        for (final e in dayFor(back).series[name] ?? const <List<dynamic>>[])
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
    _reviews[id] = action;
    return true;
  }

  static String _stamp(DateTime d) =>
      '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
}
