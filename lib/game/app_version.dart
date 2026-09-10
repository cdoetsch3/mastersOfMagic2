/// The human-readable version shown on the About panel.
///
/// ⭐ **One release, one number** (ruling 2026-08-25): the BUILD number is
/// `ContentVersion.current` — the same integer the login gate compares and
/// the same one the maintainer writes to `config/content` at deploy. The
/// About panel therefore shows exactly the number the server gates on, so
/// "what version am I running?" has one answer everywhere.
///
/// ⚠️ Consequence, accepted deliberately: EVERY release bumps the content
/// version, UI-only releases included — the gate doubles as the auto-refresh
/// mechanism, and a needless refresh is cheaper than a drifting number.
///
/// ⚠️ `test/version_sync_test.dart` pins pubspec.yaml's `x.y.z+N` to BOTH
/// constants — the suite fails on any drift, which is what "keep in sync
/// with pubspec" comments never achieved (0.12.0/26 vs 0.13.0+27 vs
/// content 2 is how it looked the day the test was written).
const String appVersion = '0.15.0';
