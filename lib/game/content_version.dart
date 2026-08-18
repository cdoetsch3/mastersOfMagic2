import 'firestore_rest.dart';

/// The version of everything a duel resolves *against*.
///
/// ⭐ **Bump [current] whenever a build changes anything two clients must
/// agree on**: item stats, spell tables, engine tuning, drop tables, prices,
/// or the wire protocol of the commit-reveal duel. This number is not the app
/// version — a UI-only release does not need a bump, and a one-line balance
/// tweak does.
///
/// ⚠️ **A bump is only half the change: the deploy must also write the new
/// number to the server document** (`config/content`.`version`) or nobody can
/// play — every client will see a mismatch and be gated. Bump, deploy the
/// build, then update the doc. See README "Releasing".
///
/// 📝 Why a login gate rather than a version field in the matchmaking ticket
/// (IMPLEMENTATION_PLAN, "LOGIN content-version gate", ruled 2026-08-02): a
/// ticket compare only stops a mismatched *pairing*; the gate stops a
/// mismatched client from existing at all, and so covers PvE, crafting and
/// prices too. It is also what makes item definitions-in-code safe
/// (ITEMS §10.1).
abstract final class ContentVersion {
  /// The content version this build resolves against. Starts at 1.
  static const int current = 1;

  /// The server's copy. ⭐ Public-read, no auth (see `firestore.rules`), so
  /// the check can run at boot rather than waiting on sign-in — a desynced
  /// guest is just as dangerous as a desynced account.
  static const String docPath = 'config/content';

  /// The integer field inside [docPath].
  static const String field = 'version';

  /// ⚠️ A slow network must not hold the player at a spinner. Past this the
  /// check gives up and fails OPEN.
  static const Duration fetchTimeout = Duration(seconds: 6);
}

/// What the login gate decided about this client.
enum ContentGateDecision {
  /// Play on — the versions match, or the check could not run at all.
  pass,

  /// Versions differ: hold the player on the blocking screen until they
  /// reload into a build that agrees with the server.
  blocked;

  bool get blocks => this == ContentGateDecision.blocked;
}

/// The gate rule, pure and total.
///
/// ⭐ **Any** difference gates, not just an older client: a server that is
/// *behind* a client means a rollback or a half-finished deploy, and a client
/// running ahead of the content everyone else resolves against desyncs a duel
/// exactly the same way.
///
/// ⚠️ **Fail-OPEN.** [serverVersion] is null when the fetch failed, timed out,
/// was refused by the rules, or the document does not exist yet — all of which
/// are *our* outage, not the player's skew. The gate exists to stop version
/// drift, and locking everyone out of the game whenever Firestore hiccups is a
/// far worse failure than letting one stale client through.
ContentGateDecision contentGateDecision(
  int? serverVersion, {
  int clientVersion = ContentVersion.current,
}) {
  if (serverVersion == null) return ContentGateDecision.pass;
  return serverVersion == clientVersion
      ? ContentGateDecision.pass
      : ContentGateDecision.blocked;
}

/// Reads a Firestore document, returning its decoded fields (null if missing).
/// Exists so tests can fake the REST layer instead of touching the network.
typedef ContentDocReader = Future<Map<String, dynamic>?> Function(String path);

/// Fetches the server's content version and applies [contentGateDecision].
///
/// ⚠️ Every failure path — exception, timeout, missing document, missing or
/// non-numeric field — collapses to [ContentGateDecision.pass]. See the
/// fail-open note on [contentGateDecision].
Future<ContentGateDecision> checkContentVersion({
  ContentDocReader read = FirestoreRest.get,
  int clientVersion = ContentVersion.current,
  Duration timeout = ContentVersion.fetchTimeout,
}) async {
  int? serverVersion;
  try {
    final fields = await read(ContentVersion.docPath).timeout(timeout);
    final raw = fields?[ContentVersion.field];
    serverVersion = raw is num ? raw.toInt() : null;
  } catch (_) {
    serverVersion = null;
  }
  return contentGateDecision(serverVersion, clientVersion: clientVersion);
}
