// The web implementations behind conditional imports. Run in a browser:
//   flutter test --platform chrome test/web
@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/platform/html_view.dart';
import 'package:p4n4_dashboard/platform/probe.dart';

void main() {
  testWidgets('Grafana and camera views are browser elements', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Expanded(child: HtmlIFrame(uri: Uri.parse('about:blank'))),
            Expanded(child: HtmlImage(uri: Uri.parse('data:image/gif;base64,R0lGODlhAQABAAAAACw='))),
          ],
        ),
      ),
    );
    expect(find.byType(HtmlElementView), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('a probe of a closed port fails without throwing', () async {
    expect(await probeHttp(Uri.parse('http://127.0.0.1:9/')), isFalse);
  });
}
