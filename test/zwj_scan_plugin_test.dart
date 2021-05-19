import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zwj_scan_plugin/zwj_scan_plugin.dart';

void main() {
  const MethodChannel channel = MethodChannel('zwj_scan_plugin');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

}
