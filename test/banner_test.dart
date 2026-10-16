import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:p4n4_dashboard/api/banner.dart';
import 'package:p4n4_dashboard/core/secrets.dart';
import 'package:p4n4_dashboard/core/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _api = Uri.parse('http://pi:8000/');

Future<AppSettings> _load() {
  SharedPreferences.setMockInitialValues({});
  return AppSettings.load(defaults: const {}, secrets: MemorySecretStore());
}

void main() {
  test('reads the API banner, and knows when it is over', () async {
    final banner = await http.runWithClient(
      () => fetchBanner(_api),
      () => MockClient((r) async {
        expect((r.method, r.url.path), ('GET', '/api/v1/dashboard/banner'));
        // No charset, as FastAPI sends it: the "–" must still read as UTF-8.
        return http.Response.bytes(
          utf8.encode(jsonEncode({'text': ' Maintenance 3–4 pm ', 'tone': 'warning', 'until': '2026-10-15T20:00:00Z'})),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    expect((banner.text, banner.tone), ('Maintenance 3–4 pm', BannerTone.warning));
    expect(banner.showsAt(DateTime.utc(2026, 10, 15, 19, 59)), isTrue);
    expect(banner.showsAt(DateTime.utc(2026, 10, 15, 20)), isFalse);
    expect(const DashboardBanner().showsAt(DateTime.now()), isFalse, reason: 'empty text: no banner');
    expect(const DashboardBanner(text: 'Hi').showsAt(DateTime(2100)), isTrue, reason: 'no end: until cleared');
  });

  test('saves a banner in UTC, and explains a refusal', () async {
    final sent = <Object?>[];
    final until = DateTime.utc(2026, 10, 15, 20).toLocal();
    final saved = await http.runWithClient(
      () => saveBanner(_api, DashboardBanner(text: 'Back at 4', until: until)),
      () => MockClient((r) async {
        sent.add(jsonDecode(r.body));
        return http.Response(r.body, 200);
      }),
    );
    expect(sent, [
      {'text': 'Back at 4', 'tone': 'info', 'until': '2026-10-15T20:00:00.000Z'},
    ]);
    expect(saved, DashboardBanner(text: 'Back at 4', until: until));

    await expectLater(
      http.runWithClient(
        () => saveBanner(_api, const DashboardBanner(text: 'x')),
        () => MockClient(
          (_) async => http.Response('{"error": {"code": "forbidden", "message": "Requires the admin role."}}', 403),
        ),
      ),
      throwsA(isA<BannerException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
  });

  // testWidgets for its fake clock: the watcher's timers run as the test pumps.
  testWidgets('BannerWatcher asks again every minute, and only a new banner notifies', (tester) async {
    final settings = await _load();
    var text = 'First';
    var reads = 0;
    var notified = 0;
    settings.addListener(() => notified++);
    final watcher = BannerWatcher(
      settings,
      fetch: (_) async {
        reads++;
        return DashboardBanner(text: text);
      },
    );
    await tester.pump();
    expect((reads, settings.banner?.text), (1, 'First'));
    final before = notified;

    await tester.pump(const Duration(minutes: 1));
    expect(reads, 2);
    expect(notified, before, reason: 'the same banner again: nothing to rebuild');

    text = 'Second';
    await tester.pump(const Duration(minutes: 1));
    expect((reads, settings.banner?.text), (3, 'Second'));
    expect(notified, before + 1);
    watcher.dispose(); // before the test ends: it checks for timers before tear-downs run
  });

  testWidgets('a failed read retries; an unrelated settings change does not read again', (tester) async {
    final settings = await _load();
    var reads = 0;
    var fail = true;
    final watcher = BannerWatcher(
      settings,
      retry: const Duration(seconds: 30),
      fetch: (_) async {
        reads++;
        if (fail) throw http.ClientException('refused');
        return const DashboardBanner(text: 'Up');
      },
    );
    await tester.pump();
    expect(reads, 1);
    fail = false;
    await tester.pump(const Duration(seconds: 30));
    expect((reads, settings.banner?.text), (2, 'Up'));

    settings.alertSound = !settings.alertSound; // any settings change
    await tester.pump();
    expect(reads, 2, reason: 'waiting for the next minute, not retrying');
    watcher.dispose();
  });
}
