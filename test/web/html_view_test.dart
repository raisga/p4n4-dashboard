// The web implementations behind conditional imports. Run in a browser:
//   flutter test --platform chrome test/web
@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/core/theme.dart';
import 'package:p4n4_dashboard/l10n/app_localizations.dart';
import 'package:p4n4_dashboard/platform/html_view.dart';
import 'package:p4n4_dashboard/platform/html_view_web.dart' show frameLoadOf, framePageOf;
import 'package:p4n4_dashboard/platform/probe.dart';
import 'package:p4n4_dashboard/widgets/service_viewer.dart';
import 'package:web/web.dart' as web;

void main() {
  testWidgets('frames and camera views are browser elements', (tester) async {
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

  // Widget tests never create platform views, so these use an <iframe> of their own.
  Future<(FrameLoad, Uri?)> loadIn(Uri uri) async {
    final frame = web.document.createElement('iframe') as web.HTMLIFrameElement;
    final loaded = Completer<void>();
    frame.onload = ((web.Event _) => loaded.complete()).toJS;
    frame.src = '$uri';
    web.document.body!.append(frame);
    await loaded.future.timeout(const Duration(seconds: 10));
    final load = (frameLoadOf(frame, uri), framePageOf(frame));
    frame.remove();
    return load;
  }

  test('a same-origin page loads readable, with its address; another origin\'s is opaque', () async {
    final page = Uri.base.resolve('/frame-test.html?theme=light');
    expect(await loadIn(page), (FrameLoad.shown, page));
    // localhost and 127.0.0.1 are different origins.
    final other = Uri.base.replace(host: Uri.base.host == 'localhost' ? '127.0.0.1' : 'localhost', path: '/x.html');
    expect(await loadIn(other), (FrameLoad.opaque, null));
  });

  testWidgets('the service viewer uses an <iframe> on web', (tester) async {
    expect(EmbedSupport.current, EmbedSupport.iframe);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(P4Colors.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ServiceViewer(uri: Uri.base.resolve('/frame-test.html'), title: 'Node-RED'),
        ),
      ),
    );
    final frame = tester.widget<HtmlIFrame>(find.byType(HtmlIFrame));
    expect(frame.title, 'Node-RED');
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Reload'), findsOneWidget);
  });

  test('a probe of a closed port fails without throwing', () async {
    expect(await probeHttp(Uri.parse('http://127.0.0.1:9/')), isFalse);
  });
}
