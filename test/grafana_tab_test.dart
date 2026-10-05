import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4n4_dashboard/tabs/grafana_tab.dart';

void main() {
  group('themedGrafanaUri', () {
    test('adds the app\'s mode and keeps the other parameters', () {
      final uri = Uri.parse('http://pi.lan:3000/d/retail-vision/store?kiosk=1&var-store=demo-store');
      expect(
        themedGrafanaUri(uri, Brightness.light).toString(),
        'http://pi.lan:3000/d/retail-vision/store?kiosk=1&var-store=demo-store&theme=light',
      );
    });

    test('replaces a theme already in the URL', () {
      final uri = Uri.parse('https://edge.lan/grafana/?theme=light');
      expect(themedGrafanaUri(uri, Brightness.dark), Uri.parse('https://edge.lan/grafana/?theme=dark'));
    });
  });
}
