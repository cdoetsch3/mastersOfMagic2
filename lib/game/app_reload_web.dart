import 'dart:js_interop';

@JS('window.location.reload')
external void _locationReload();

/// Hard-reloads the page, which is the only way a dart2js build picks up a
/// newer `main.dart.js`.
///
/// ⚠️ Flutter's own navigation cannot do this — there is no in-app path back
/// to a different build. It has to be the browser.
void reloadApp() => _locationReload();
