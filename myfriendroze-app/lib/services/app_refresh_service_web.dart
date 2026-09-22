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

  // Deliberately NOT clearing IndexedDB here. A prior version of this
  // function did, on the assumption that cached_network_image's cache
  // (via flutter_cache_manager) was IndexedDB-backed on web — checked the
  // locked flutter_cache_manager 3.4.1 source directly and that's wrong:
  // its web Config uses NonStoringObjectProvider + MemoryCacheSystem, an
  // in-memory-only cache with no persistence at all, already fully
  // cleared by the reload() below with no extra code needed. Actually
  // deleting IndexedDB would only have risked wiping Firebase Auth's/
  // Firestore's own IndexedDB-backed persistence (a real correctness
  // hazard — e.g. logging the user out), for a problem that didn't exist.
  web.window.location.reload();
}
