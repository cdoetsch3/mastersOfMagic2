import 'item_def.dart';

/// Builds an item's display name from the facts that produced it.
///
/// ⭐ **The name is computed, never stored.** ITEMS_DESIGN §9b.5a fixes the
/// grammar so every component carries exactly one fact:
///
/// | Component | Encodes |
/// |---|---|
/// | Aspect prefix | element (drops only) |
/// | Quality adjective | the crafting roll |
/// | Material | tier, and therefore level |
/// | Form | mechanical role, never rank |
///
/// ⚠️ **Storing the string lets it drift from the facts it encodes** — an item
/// could be renamed without being changed, or changed without being renamed.
/// One composer, one drift-guard test.
String composeItemName({
  String? aspectPrefix,
  Quality? quality,
  required String material,
  required String form,
}) {
  final parts = <String>[
    ?aspectPrefix,
    if (quality != null && quality != Quality.standard) qualityWord(quality),
    material,
    form,
  ];
  return parts.join(' ');
}

/// ⭐ **Standard is unwritten.** Naming the middle of a four-step ladder makes
/// every ordinary item read as a variant; leaving it silent makes Rough and
/// Ornate mean something.
String qualityWord(Quality q) => switch (q) {
  Quality.rough => 'Rough',
  Quality.standard => 'Standard',
  Quality.ornate => 'Ornate',
  Quality.master => 'Master',
};

/// ✅ The twelve aspect prefixes (ITEMS §9b.5b). Every one avoids its own
/// element's status name and the reserved vocabulary in README §3.
const Map<String, String> aspectPrefixes = {
  'pyro': 'Charred',
  'aqua': 'Tidewashed',
  'flora': 'Overgrown',
  'electro': 'Galvanized',
  'aero': 'Windworn',
  'geo': 'Stoneclad',
  'solar': 'Sunbleached',
  'lunar': 'Moonlit',
  'astral': 'Starfallen',
  'sanctus': 'Consecrated',
  'umbra': 'Gloomtouched',
  'arcane': 'Sigilmarked',
};
