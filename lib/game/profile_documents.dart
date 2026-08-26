import 'player_profile.dart';

/// The cloud save, cut into the documents Firestore actually stores.
///
/// ⭐ **The split lives here, away from the network.** Assembling and cutting
/// a profile is pure map arithmetic; only [FirestoreProfileStorage] knows about
/// paths, retries and caches. That is what makes the interesting half —
/// "does a legacy save survive the round trip?" — testable without a network.
///
/// ⚠️ **Local guest storage does not use this at all.** `LocalProfileStorage`
/// keeps the single-blob `PlayerProfile.toJson()` it has always written, byte
/// for byte, because a browser's localStorage has no document ceiling and no
/// per-document write cost — the two things this split exists to answer.
///
/// The layout (designer ruling, 2026-08-26):
///
/// ```
/// users/{uid}                                   <- the account: login-adjacent
/// users/{uid}/characters/{cid}                  <- the character (v1: 'main')
/// users/{uid}/characters/{cid}/storerooms/{townId}
/// users/{uid}/characters/{cid}/shopStock/{townId}
/// ```
class ProfileDocuments {
  /// The account document's fields.
  final Map<String, dynamic> user;

  /// The character document's fields — today's profile, less the big maps.
  final Map<String, dynamic> character;

  /// One document per town that has anything stored in it.
  final Map<String, Map<String, dynamic>> storerooms;

  /// One document per town whose shop this character has resolved.
  final Map<String, Map<String, dynamic>> shopStock;

  const ProfileDocuments({
    required this.user,
    required this.character,
    required this.storerooms,
    required this.shopStock,
  });

  /// Bumped when the shape below changes, so a future reader can tell which
  /// layout it is looking at. 1 = the users/characters restructure.
  static const int schemaVersion = 1;

  /// The character id every v1 client uses. ⭐ **Fixed, not generated**: v1
  /// ships one character and no picker, so a stable id means the client can
  /// address the document without first reading a list to find out its name.
  /// The path is already plural, so a picker later adds ids beside this one
  /// rather than moving it.
  static const String soleCharacterId = 'main';

  /// Fields that leave the character document for the account document.
  ///
  /// ⭐ **`lastSeenAt` is the one genuinely account-level fact in today's
  /// profile.** Presence answers "is this *person* around, could I challenge
  /// them right now" (see `presence.dart`) — a question about a login, not
  /// about which mage they last played. Decisively: the friends list reads it
  /// off *somebody else's* account, and a social read must not have to walk
  /// into a stranger's character subcollection to find one timestamp.
  ///
  /// ⚠️ Everything else stays on the character, and deliberately so.
  /// ACHIEVEMENTS_DESIGN §2 rules that progress is character-level and that
  /// two characters are "100% separate — an account is just the login", so xp,
  /// gold, resonancePrisms, duel record and the item pool are all character
  /// fields even where an account-wide reading is imaginable. See the report's
  /// ambiguity list.
  static const String lastSeenField = 'lastSeenAt';

  /// The big per-town maps, which become one document each.
  static const List<String> townKeyedFields = ['storerooms', 'shopStock'];

  /// Cuts [profile] into the documents to write.
  static ProfileDocuments split(PlayerProfile profile) {
    // ⭐ Cut from `toJson()` rather than from the fields, so the character
    // document inherits every rule that serialization already enforces — the
    // sparse-write filter that drops an emptied Storeroom, the ISO-8601 dates,
    // the enum-name encoding. A second, parallel serializer would be a second
    // place for those rules to drift.
    final json = profile.toJson();
    final rooms = _townDocs(json.remove('storerooms'));
    final shops = _townDocs(json.remove('shopStock'));
    final lastSeen = json.remove(lastSeenField);

    // ⚠️ `skillXp` is the one field `toJson` writes *sparsely*, and a REST
    // patch only touches the fields it names: were the key simply absent on a
    // character with no skill XP, a reset would leave the old ledger behind in
    // the cloud. Forcing it present keeps every character document's field set
    // identical, so the update mask always covers everything that could be
    // stale. Reading `{}` back is what an absent key already meant.
    json.putIfAbsent('skillXp', () => <String, int>{});

    return ProfileDocuments(
      user: {
        // A copy, not the source of truth: the character owns its name (see
        // `GameState.setName`). This is the label a *social* read wants —
        // the friends list, a leaderboard row — beside the presence stamp it
        // is already fetching, so neither costs a subcollection read.
        'displayName': json['name'],
        lastSeenField: lastSeen,
        'schemaVersion': schemaVersion,
      },
      character: json,
      storerooms: rooms,
      shopStock: shops,
    );
  }

  /// Rebuilds the whole profile from the documents that were read back.
  ///
  /// Every argument is tolerated as missing: a character document with no
  /// account document beside it, or with no town documents, is a perfectly
  /// coherent save (a character who has stored nothing anywhere).
  static PlayerProfile assemble({
    Map<String, dynamic>? user,
    required Map<String, dynamic> character,
    Map<String, Map<String, dynamic>> storerooms = const {},
    Map<String, Map<String, dynamic>> shopStock = const {},
  }) {
    final json = Map<String, dynamic>.from(character)
      ..['storerooms'] = storerooms
      ..['shopStock'] = shopStock;
    // ⭐ The account document wins on the fields it owns, but a character
    // document that still carries them (a legacy save mid-migration, or one
    // written by a build from before the split) is read rather than discarded.
    json[lastSeenField] = user?[lastSeenField] ?? character[lastSeenField];
    json['name'] ??= user?['displayName'];
    return PlayerProfile.fromJson(json);
  }

  static Map<String, Map<String, dynamic>> _townDocs(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        '${e.key}': Map<String, dynamic>.from(e.value as Map),
    };
  }
}
