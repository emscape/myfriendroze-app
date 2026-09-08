// Non-web fallback for app_refresh_service.dart — see that file's header.
// Native platforms update via reinstall, not a service-worker/cache clear,
// so there's nothing for this to do.
const bool canRefreshApp = false;

Future<void> refreshApp() async {}
