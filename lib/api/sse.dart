import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_error.dart';

/// One server-sent event: its type (`message` unless the server named one)
/// and its data, lines joined with `\n`.
typedef SseEvent = ({String event, String data});

/// The events in an `text/event-stream` body. Comments (keep-alives) are
/// skipped; an event is dispatched at the blank line that ends it.
Stream<SseEvent> parseSse(Stream<List<int>> bytes) async* {
  var event = '';
  final data = <String>[];
  await for (final line in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) yield (event: event.isEmpty ? 'message' : event, data: data.join('\n'));
      event = '';
      data.clear();
      continue;
    }
    if (line.startsWith(':')) continue;
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        event = value;
      case 'data':
        data.add(value);
    }
  }
}

/// Follows p4n4-api's event stream at [url] until the server ends it or the
/// listener cancels, which closes the connection.
///
/// Read with `fetch` through the app's client rather than `EventSource`, which
/// can't send the `Authorization` header [AuthClient] adds. Throws an
/// [ApiException] when the API turns the request down.
Stream<SseEvent> sseGet(Uri url) async* {
  final client = http.Client();
  try {
    final http.StreamedResponse res;
    try {
      res = await client
          .send(http.Request('GET', url)..headers['Accept'] = 'text/event-stream')
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ApiException('No answer in time.', statusCode: 504);
    } on http.ClientException catch (e) {
      throw ApiException(e.message);
    }
    if (res.statusCode != 200) {
      throw ApiException.from(http.Response(await res.stream.bytesToString(), res.statusCode, headers: res.headers));
    }
    yield* parseSse(res.stream);
  } finally {
    client.close();
  }
}
