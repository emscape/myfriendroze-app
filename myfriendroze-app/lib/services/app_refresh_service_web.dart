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

  // The service worker + CacheStorage clear above only covers the app
  // shell (index.html, main.dart.js, etc.) — it does nothing for
  // cached_network_image's own cache (via flutter_cache_manager), which
  // stores fetched images in IndexedDB, a separate browser storage
  // mechanism entirely. Without this, a product/gallery/event photo that
  // failed to load once (e.g. during a CORS misconfiguration, or any
  // other transient fetch failure) could stay stuck showing that failure
  // indefinitely, surviving this button being pressed.
  try {
    final databases = (await web.window.indexedDB.databases().toDart).toDart;
    for (final db in databases) {
      final name = db.name;
      // deleteDatabase() returns an IDBOpenDBRequest (the classic
      // event-callback IndexedDB API, not a Promise) — not awaited here.
      // This is best-effort cleanup already wrapped in a try/catch, and
      // the deletion is fired before the reload() below regardless of
      // whether it's finished by the time the page actually navigates
      // away.
      if (name.isNotEmpty) {
        web.window.indexedDB.deleteDatabase(name);
      }
    }
  } catch (_) {
    // indexedDB.databases() isn't supported on every browser (notably
    // older Safari) — if it throws, the rest of the refresh (service
    // worker + CacheStorage clear, reload) still proceeds below rather
    // than leaving the whole button non-functional over one unsupported
    // API.
  }

  web.window.location.reload();
}
