// lib/services/push_interop.dart
import 'dart:js_interop';

import 'package:flutter/material.dart';

@JS('setOneSignalExternalId')
external JSPromise<JSAny?> _setOneSignalExternalId(JSString userId);

@JS('showNotificationPrompt')
external JSPromise<JSAny?> _showNotificationPrompt();

Future<void> linkOneSignalUser(String userId) async {
  try {
    await _setOneSignalExternalId(userId.toJS).toDart;
  } catch (e) {
   debugPrint('OneSignal external ID link failed: $e');
  }
}

Future<void> promptForNotifications() async {
  try {
    await _showNotificationPrompt().toDart;
  } catch (e) {
    // ignore: avoid_print
    print('OneSignal prompt failed: $e');
  }
}