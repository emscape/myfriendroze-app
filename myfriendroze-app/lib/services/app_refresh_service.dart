// Unregisters the PWA's service worker and clears its Cache Storage
// entries, then reloads — lets the "Refresh App" button on the Profile
// screen force a stuck web build to pick up the latest deploy without
// removing/re-adding the iOS home-screen bookmark (Safari's PWA mode has
// no visible cache-clear control the way a normal browser tab does).
//
// dart:html isn't available when compiling for Android, so the real
// implementation lives in a web-only file behind a conditional export,
// with a no-op stub for every other platform. `canRefreshApp` mirrors
// that: false everywhere the real refresh has nothing to do.
export 'app_refresh_service_stub.dart'
    if (dart.library.html) 'app_refresh_service_web.dart';
