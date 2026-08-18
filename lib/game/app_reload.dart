/// Reloading the *page*, which only the web build can actually do.
///
/// ⚠️ Conditional import, not an `if (kIsWeb)` branch: `dart:js_interop` does
/// not exist on the VM, so a direct import would break `flutter test` and the
/// mobile shells at compile time. The stub is what the test suite links.
library;

export 'app_reload_stub.dart'
    if (dart.library.js_interop) 'app_reload_web.dart';
