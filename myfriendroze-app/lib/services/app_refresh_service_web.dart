// Web implementation for app_refresh_service.dart — see that file's header.
//
// Uses package:web's typed bindings (Navigator.serviceWorker,
// Window.caches) rather than dart:js_util's generic property/method
// access — dart:js_util is not just deprecated but fully removed on
// newer Dart SDKs (confirmed via a CI failure on a newer stable Flutter
// than this was first written against: `uri_does_not_exist` for
// 'dart:js_util'). package:web is the actively maintained replacement.
import 'dart:js_interop';

import 'package:web/web.dart' as web;

const bool canRefreshApp = true;

Future<void> refreshApp() async {
  final registrations =
      (await web.window.navigator.serviceWorker.getRegistrations().toDart)
          .toDart;
  for (final registration in registrations) {
    await registration.unregister().toDart;
  }

  final cacheStorage = web.window.caches;
  final keys = (await cacheStorage.keys().toDart).toDart;
  for (final key in keys) {
    await cacheStorage.delete(key.toDart).toDart;
  }

  web.window.location.reload();
}
