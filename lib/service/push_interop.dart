// lib/services/push_interop.dart
// This file is ONLY a bridge — it declares JS functions Dart can call.
// The actual logic lives in web/index.html's <script> block.

import 'dart:js_interop';

@JS('subscribeToPush')
external JSPromise<JSAny?> subscribeToPush();

// Wrapper function to call from anywhere in your Dart code
Future<void> triggerPushSubscription() async {
  try {
    await subscribeToPush().toDart; // .toDart converts JS Promise → Dart Future
  } catch (e) {
    // If push isn't supported or user denies permission, fail silently
    // ignore: avoid_print
    print('Push subscription failed: $e');
  }
}