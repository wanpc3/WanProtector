import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

const platform = MethodChannel('com.ilhanidriss.wan_protector/screen');

//Toggle Screenshot
Future<void> toggleScreenshot(bool allow) async {
  try {
    await platform.invokeMethod(allow ? 'enableScreenshot' : 'disableScreenshot');
  } catch (e) {
    debugPrint('Failed to toggle screenshot: $e');
  }
}