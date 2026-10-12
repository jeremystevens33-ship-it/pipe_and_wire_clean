import 'package:flutter/services.dart';

/// Opens the phone's share sheet. The user chooses the app and recipient.
class AppShare {
  static const _channel = MethodChannel('pipe_and_wire/share');

  static Future<void> text({required String title, required String text}) =>
      _channel.invokeMethod<void>('shareText', {'title': title, 'text': text});
}
