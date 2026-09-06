// Web implementation for app_refresh_service.dart — see that file's header.
//
// Uses dart:js_util's generic property/method access rather than typed
// dart:html bindings for navigator.serviceWorker/caches: dart:html's
// Cache Storage coverage is inconsistent across Dart SDK versions, while
// plain JS interop only assumes the browser APIs themselves exist (true
// in every browser this PWA targets).
import 'dart:js_util' as js_util;

const bool canRefreshApp = true;

Future<void> refreshApp() async {
  final navigator = js_util.getProperty(js_util.globalThis, 'navigator');
  final serviceWorker = js_util.getProperty(navigator, 'serviceWorker');

  if (serviceWorker != null) {
    final registrations = await js_util.promiseToFuture<List<dynamic>>(
      js_util.callMethod(serviceWorker, 'getRegistrations', []),
    );
    for (final registration in registrations) {
      await js_util.promiseToFuture<dynamic>(
        js_util.callMethod(registration, 'unregister', []),
      );
    }
  }

  final caches = js_util.getProperty(js_util.globalThis, 'caches');
  if (caches != null) {
    final keys = await js_util.promiseToFuture<List<dynamic>>(
      js_util.callMethod(caches, 'keys', []),
    );
    for (final key in keys) {
      await js_util.promiseToFuture<dynamic>(
        js_util.callMethod(caches, 'delete', [key]),
      );
    }
  }

  final location = js_util.getProperty(js_util.globalThis, 'location');
  js_util.callMethod(location, 'reload', []);
}
