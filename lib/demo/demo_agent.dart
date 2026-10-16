/// The demo's assistant: no model, just the questions a store asks most,
/// answered from the recorded analytics with the tool steps a store's agent
/// would show, in the store's language.
library;

import 'dart:math' as math;

import 'demo_store.dart';

/// A reply: the tools it "ran" and its Markdown.
typedef DemoReply = ({List<(String tool, Map<String, String> label)> steps, String text});

const _labels = {
  'get_store_summary': {'en': 'the store summary', 'es': 'el resumen de la tienda', 'fr': 'le résumé du magasin'},
  'get_alerts': {'en': 'the alerts', 'es': 'las alertas', 'fr': 'les alertes'},
  'get_shelves': {'en': 'the shelves', 'es': 'los estantes', 'fr': 'les portants'},
  'get_garment_ranking': {
    'en': 'the garment ranking',
    'es': 'el ranking de prendas',
    'fr': 'le classement des articles',
  },
  'get_purchase_factors': {
    'en': 'what decides a purchase',
    'es': 'qué decide la compra',
    'fr': "ce qui décide l'achat",
  },
  'get_recent_events': {'en': 'the latest activity', 'es': 'la actividad reciente', 'fr': "l'activité récente"},
};

class DemoAgent {
  DemoAgent(this.store);

  final DemoStore store;

  String get _lang => store.lang;

  /// [es], [en] or [fr], whichever the store speaks.
  String _t(String es, String en, String fr) => switch (_lang) {
    'es' => es,
    'fr' => fr,
    _ => en,
  };

  DemoReply answer(String question) {
    final q = _fold(question);
    bool has(List<String> words) => words.any(q.contains);
    final (tools, text) = switch (q) {
      _ when has(['riesgo', 'perdida', 'loss', 'perte', 'robo', 'theft', ' vol', 'revis', 'review']) => (
        ['get_alerts'],
        _toReview(),
      ),
      _ when has(['decide', 'impulsa', 'drive', 'factor', 'reserv', 'achat', 'por que compran', 'why']) => (
        ['get_purchase_factors'],
        _factors(),
      ),
      _ when has(['estante', 'shelf', 'shelves', 'portant', 'menos ventas', 'vende', 'sell', 'vend']) => (
        ['get_shelves'],
        _shelves(),
      ),
      _
          when has([
            'prenda',
            'garment',
            'piece',
            'vestido',
            'gown',
            'depart',
            'llevan',
            'take',
            'essa',
            'prueb',
            'tried',
            'article',
          ]) =>
        (['get_garment_ranking'], _ranking()),
      _ when has(['hoy', 'today', 'aujourd', 'ahora', 'now', 'maintenant']) => (['get_recent_events'], _today()),
      _ when has(['alerta', 'alert']) => (['get_alerts'], _alerts()),
      _ => (['get_store_summary'], _yesterday()),
    };
    return (steps: [for (final t in tools) (t, _labels[t]!)], text: text);
  }

  // ── the answers ──────────────────────────────────────────────────────────

  String _yesterday() {
    final day = store.dayFor(1);
    final s = day.summary;
    final alerts = (s['alerts'] as Map)['total'] as int;
    final attended = day.reviewStatus.values.where((v) => v == 'attended').length;
    final top = s['top_shelf'] as Map?;
    final peak = s['peak_hour'] as Map?;
    return [
      _t('**Ayer** en la tienda:', '**Yesterday** in the store:', '**Hier** en magasin :'),
      '',
      '- ${_t('Visitantes', 'Visitors', 'Visiteurs')}$_colon **${s['visitors']}**',
      '- ${_t('Ventas', 'Sales', 'Ventes')}$_colon **${s['sales_transactions']}** (${_money(s['revenue'] as num)}), '
          '${_t('conversión', 'conversion', 'conversion')} ${_pct(s['conversion_rate'] as num)}',
      '- ${_t('Prendas tomadas', 'Garments taken', 'Articles pris')}$_colon ${s['garments_taken']} · '
          '${_t('visitas al probador', 'fitting room visits', 'passages en cabine')}$_colon ${s['fitting_room_visits']}',
      if (peak != null)
        '- ${_t('Hora punta', 'Peak hour', 'Heure de pointe')}$_colon ${peak['hour']} (${peak['entries']})',
      if (top != null)
        '- ${_t('Estante con más interés', 'Busiest shelf', 'Portant le plus regardé')}$_colon **${top['name']}** '
            '(${top['interactions']} ${_t('interacciones', 'interactions', 'interactions')})',
      '- ${_t('Alertas', 'Alerts', 'Alertes')}$_colon $alerts, ${_t('atendidas', 'attended', 'traitées')} $attended',
      '',
      _t(
        'Puedes preguntarme por los estantes, las prendas, las alertas o qué decide la compra.',
        'Ask me about the shelves, the garments, the alerts or what decides a purchase.',
        "Demandez-moi les portants, les articles, les alertes ou ce qui décide l'achat.",
      ),
    ].join('\n');
  }

  String _today() {
    final today = store.items(span: 1);
    final alerts = today.where((i) => i.alert).toList();
    final pending = alerts.where((i) => i.json['status'] == 'pending_review').length;
    if (today.isEmpty) {
      return _t(
        'Hoy todavía no hay actividad: la tienda abre a las 10:00.',
        'No activity yet today: the store opens at 10:00.',
        "Pas encore d'activité aujourd'hui : le magasin ouvre à 10 h.",
      );
    }
    final byCode = <String, int>{};
    for (final a in alerts) {
      byCode.update(a.badge ?? '?', (n) => n + 1, ifAbsent: () => 1);
    }
    final last = alerts.firstOrNull;
    return [
      _t('**Hoy** hasta ahora:', '**Today** so far:', "**Aujourd'hui** jusqu'ici :"),
      '',
      '- ${_t('Eventos', 'Events', 'Événements')}$_colon ${today.length - alerts.length}',
      '- ${_t('Alertas', 'Alerts', 'Alertes')}$_colon ${alerts.length}, ${_t('pendientes', 'pending', 'en attente')} $pending',
      for (final code in byCode.keys.toList()..sort())
        '  - $code ${store.alertTitles[code] ?? ''}$_colon ${byCode[code]}',
      if (last != null)
        '- ${_t('La última', 'The latest', 'La dernière')}$_colon ${_time(last.at)}, ${last.json['title']}',
    ].join('\n');
  }

  String _alerts() {
    final week = store.items().where((i) => i.alert).toList();
    final byCode = <String, int>{};
    for (final a in week) {
      byCode.update(a.badge ?? '?', (n) => n + 1, ifAbsent: () => 1);
    }
    final pending = week.where((i) => i.json['status'] == 'pending_review').length;
    return [
      _t(
        '**${week.length} alertas** en los últimos 7 días (y hoy), $pending pendientes:',
        '**${week.length} alerts** over the last 7 days (and today), $pending pending:',
        '**${week.length} alertes** ces 7 derniers jours (et aujourd\'hui), $pending en attente :',
      ),
      '',
      for (final code in byCode.keys.toList()..sort())
        '- **$code** ${store.alertTitles[code] ?? ''}$_colon ${byCode[code]}',
    ].join('\n');
  }

  /// The alerts that ask a person to take a look (the feed's `review` tone).
  String _toReview() {
    final review = store.items().where((i) => i.alert && i.json['tone'] == 'review').toList();
    if (review.isEmpty) {
      return _t(
        'No hubo alertas para revisar en la última semana.',
        'There were no alerts to review in the past week.',
        'Aucune alerte à vérifier cette dernière semaine.',
      );
    }
    final badge = review.first.badge;
    final kind = badge == null ? '' : ' **$badge · ${store.alertTitles[badge] ?? ''}**';
    final n = review.length;
    return [
      _t(
        'Hubo **$n** ${n == 1 ? 'alerta' : 'alertas'}$kind en la última semana:',
        'There ${n == 1 ? 'was' : 'were'} **$n**$kind ${n == 1 ? 'alert' : 'alerts'} in the past week:',
        '**$n** ${n == 1 ? 'alerte' : 'alertes'}$kind cette dernière semaine :',
      ),
      '',
      for (final a in review.take(6))
        '- ${_time(a.at)}$_colon ${a.json['subtitle'] ?? a.json['title']} — ${_status(a.json['status'] as String?)}',
      '',
      _t(
        'Es una revisión, nunca una acusación: lo indicado es acercarse con cortesía y ofrecer ayuda.',
        "It's a review, never an accusation: approach politely and offer help.",
        "C'est une vérification, jamais une accusation : s'approcher avec courtoisie et proposer son aide.",
      ),
    ].join('\n');
  }

  String _ranking() {
    final rows = <String, ({String garment, String color, int interactions, int sold})>{};
    final categories = <String, int>{};
    for (final day in _week()) {
      for (final r in (day.ranking['ranking'] as List).cast<Map>()) {
        final key = '${r['garment_type']}|${r['color']}';
        final old = rows[key];
        rows[key] = (
          garment: r['garment_type'] as String,
          color: r['color'] as String,
          interactions: (old?.interactions ?? 0) + (r['interactions'] as num).toInt(),
          sold: (old?.sold ?? 0) + (r['units_sold'] as num).toInt(),
        );
      }
      for (final c in (day.purchase['units_by_category'] as List).cast<Map>()) {
        categories.update(
          c['label'] as String,
          (n) => n + (c['units'] as num).toInt(),
          ifAbsent: () => (c['units'] as num).toInt(),
        );
      }
    }
    final top = rows.values.toList()..sort((a, b) => b.interactions.compareTo(a.interactions));
    final cats = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [
      _t(
        'Lo que más se toca y se lleva en los últimos 7 días:',
        'What shoppers handle and take most over the last 7 days:',
        'Ce qui est le plus touché et pris ces 7 derniers jours :',
      ),
      '',
      for (final (n, r) in top.take(5).indexed)
        '${n + 1}. **${r.garment} ${r.color}**$_colon ${r.interactions} ${_t('interacciones', 'interactions', 'interactions')}, '
            '${r.sold} ${_t('vendidas', 'sold', 'vendus')}',
      if (cats.isNotEmpty) ...[
        '',
        '${_t('Unidades tomadas por categoría', 'Units taken by category', 'Unités prises par catégorie')}$_colon '
            '${cats.map((e) => '${e.key} ${e.value}').join(' · ')}',
      ],
    ].join('\n');
  }

  String _factors() {
    final shares = <String, double>{};
    var weight = 0.0;
    for (final day in _week()) {
      final w = (day.purchase['events_with_factors'] as num?)?.toDouble() ?? 0;
      weight += w;
      for (final f in (day.purchase['factor_share'] as List).cast<Map>()) {
        shares.update(
          f['label'] as String,
          (v) => v + (f['share'] as num) * w,
          ifAbsent: () => (f['share'] as num) * w,
        );
      }
    }
    final ranked = shares.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.isEmpty || weight == 0) return _yesterday();
    return [
      _t(
        'Lo que pesa en la decisión de compra en los últimos 7 días:',
        'What weighs on the decision to buy over the last 7 days:',
        "Ce qui pèse dans la décision d'achat ces 7 derniers jours :",
      ),
      '',
      for (final e in ranked) '- **${e.key}**$_colon ${_pct(e.value / weight)}',
      '',
      _t(
        '**${ranked.first.key}** decide la mayoría de las compras; donde se devuelve una prenda por la talla, conviene revisar el surtido de tallas.',
        '**${ranked.first.key}** decides most purchases; where garments go back for the size, check the size range on that rack.',
        "**${ranked.first.key}** décide la plupart des achats ; là où un article revient pour la taille, vérifiez l'assortiment de tailles.",
      ),
    ].join('\n');
  }

  String _shelves() {
    final shelves = <String, ({String name, int interactions, int sold, double revenue})>{};
    for (final day in _week()) {
      for (final s in (day.layout['shelves'] as List).cast<Map>()) {
        final id = s['shelf_id'] as String;
        final old = shelves[id];
        shelves[id] = (
          name: s['name'] as String,
          interactions: (old?.interactions ?? 0) + (s['interactions'] as num).toInt(),
          sold: (old?.sold ?? 0) + (s['units_sold'] as num).toInt(),
          revenue: (old?.revenue ?? 0) + (s['revenue'] as num).toDouble(),
        );
      }
    }
    // A shelf nobody went near this week isn't worth a line.
    final list = shelves.values.where((s) => s.interactions > 0 || s.sold > 0).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    if (list.isEmpty) return _yesterday();
    final lowest = list.reduce((a, b) => a.sold <= b.sold ? a : b);
    final gap = list.reduce(
      (a, b) => a.interactions / math.max(1, a.sold) >= b.interactions / math.max(1, b.sold) ? a : b,
    );
    return [
      _t(
        'Los estantes en los últimos 7 días:',
        'The shelves over the last 7 days:',
        'Les portants ces 7 derniers jours :',
      ),
      '',
      for (final s in list)
        '- **${s.name}**$_colon ${s.interactions} ${_t('interacciones', 'interactions', 'interactions')}, '
            '${s.sold} ${_t('vendidas', 'sold', 'vendus')}, ${_money(s.revenue)}',
      '',
      _t(
        'El que más vende es **${list.first.name}**; el que menos, **${lowest.name}**. **${gap.name}** atrae interés que no se convierte en venta.',
        'The best seller is **${list.first.name}** and the lowest **${lowest.name}**. **${gap.name}** draws interest that doesn\'t turn into sales.',
        'Le plus vendeur est **${list.first.name}**, le moins **${lowest.name}**. **${gap.name}** attire un intérêt qui ne se transforme pas en ventes.',
      ),
    ].join('\n');
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  /// The last 7 full days.
  Iterable<DemoDay> _week() => [for (var back = 1; back <= 7; back++) store.dayFor(back)];

  String _status(String? status) => switch (status) {
    'attended' => _t('atendida', 'attended', 'traitée'),
    'dismissed' => _t('descartada', 'dismissed', 'ignorée'),
    _ => _t('pendiente', 'pending', 'en attente'),
  };

  /// French sets a colon off with a (thin) space.
  String get _colon => _lang == 'fr' ? '\u202f:' : ':';

  String _pct(num share) => '${(share * 100).round()} %';

  String _money(num amount) {
    final fixed = amount.toStringAsFixed(2);
    final (whole, cents) = (fixed.split('.')[0], fixed.split('.')[1]);
    final sep = _lang == 'fr' ? ' ' : ',';
    final grouped = whole.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => sep);
    return switch (store.currency) {
      'EUR' => '$grouped,$cents €',
      'USD' => '\$$grouped.$cents',
      _ => 'B/. $grouped.$cents',
    };
  }

  String _time(DateTime at) {
    const names = {
      'es': ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'],
      'fr': ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'],
      'en': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    };
    final day = (names[_lang] ?? names['en']!)[at.weekday - 1];
    return '$day ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  }

  /// Lowercase without accents, for matching words.
  static String _fold(String s) {
    const from = 'áàâäéèêëíìîïóòôöúùûüñç';
    const to = 'aaaaeeeeiiiioooouuuunc';
    final lower = ' ${s.toLowerCase()} ';
    return String.fromCharCodes(
      lower.runes.map((r) {
        final i = from.indexOf(String.fromCharCode(r));
        return i < 0 ? r : to.codeUnitAt(i);
      }),
    );
  }
}
