import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:p4n4_dashboard/api/agent_client.dart';
import 'package:p4n4_dashboard/api/edge_metrics.dart';
import 'package:p4n4_dashboard/api/services.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('EdgeMetrics parses the documented JSON', () {
    final m = EdgeMetrics.fromJson({
      'cpu_percent': 23.1,
      'mem_percent': 61,
      'temp_c': 51.3,
      'uptime_s': 90061,
      'load': [0.4, 0.5, 0.6],
    });
    expect(m.cpu, 23.1);
    expect(m.mem, 61.0);
    expect(m.tempC, 51.3);
    expect(m.uptime, const Duration(days: 1, hours: 1, minutes: 1, seconds: 1));
    expect(m.load, [0.4, 0.5, 0.6]);
    expect(m.disk, isNull);
  });

  test('statusFor maps catalog entries to compose services', () {
    const status = {
      'grafana': ComposeService('grafana', 'running', ''),
      'mosquitto': ComposeService('mosquitto', 'exited', ''),
    };
    final grafana = stacks.first.services.first;
    final mqtt = stacks.first.services.firstWhere((s) => s.name == 'MQTT');
    expect(statusFor(grafana, status)?.running, isTrue);
    expect(statusFor(mqtt, status)?.running, isFalse);
  });

  test('ChatMessage serializes for Ollama', () {
    expect(ChatMessage('user', 'hi').toJson(), {'role': 'user', 'content': 'hi'});
  });
}
