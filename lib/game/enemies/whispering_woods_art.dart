/// Pixel art for the Whispering Woods.
///
/// ⭐ **The wood is one creature and you are standing on it** (ENEMIES §2d), so
/// nothing here is drawn as an animal. Bark grain, root bundles and moss;
/// joints that bend where a branch would rather than where a bone would.
///
/// ⚠️ Authored for **silhouette**, not detail. Descriptions in BESTIARY_ART.md
/// are written for image generators and say things like "fine pink feeding
/// roots" — at this resolution that is one pixel, so it becomes a shape at the
/// creature's edge or it does not exist.
///
/// Palette chars: `b` body · `d` shade · `l` highlight · `a` accent ·
/// `A` accent shade · `e` dark · `g` glow · `.` empty.
library;

import '../creature_sprite.dart';

abstract final class WhisperingWoodsArt {
  // ---- commons ---------------------------------------------------------

  /// Deer-shaped, root-built, head lowered, no eyes.
  ///
  /// ⭐ **Redrawn with an outline and real negative space** after a first pass
  /// that read as a green lump. The gap between the legs and the separated
  /// head-and-ear shape are what make it a creature rather than a blob — at
  /// this size the *hole* does more work than any pixel that is filled.
  static const listeningFawn = CreatureArt([
    '..................................',
    '.............................oo...',
    '............................oaao..',
    '...........................oaaao..',
    '..........................oaaao...',
    '.........oooooooo........oaaao....',
    '.......ooblllllbboo.....oaaao.....',
    '......oblllllllllbbo...oaao.......',
    '.....obllllllllllllbo.oaao........',
    '....obllllllllllllllboaao.........',
    '....obllllllllllllllbboo..........',
    '....obllllllllllllllbo............',
    '....obdlllllllllllldbo............',
    '....obdddlllllllldddbo............',
    '.....obdddddddddddddbo............',
    '......obdddddddddddbo.....ooo.....',
    '.......oobddddddddboo....obbbo....',
    '.........obdddddddbo....obllbo....',
    '.........obo.....obo...obllbo.....',
    '.........obo.....obo..obllbo......',
    '.........obo.....obo.obllbo.......',
    '.........obo.....obo.oblbo........',
    '.........obo.....obo..obo.........',
    '.........ooo.....ooo..............',
    '..................................',
  ]);

  /// Knee-high, hunched, briar-wiry. ⭐ The thorn ridge down the spine is the
  /// only silhouette break — everything else is a crouch.
  static const thornbackSprite = CreatureArt([
    '....................',
    '..........aa........',
    '.........a..........',
    '........a...........',
    '.......a.....a......',
    '......bbbb..a.......',
    '.....bbbbbba........',
    '....bbeebbba........',
    '....bbbbbbba........',
    '...bbbbbbbba........',
    '..bbbbbbbbba........',
    '..bbbbbbbbbd........',
    '.bbbbbbbbbbd........',
    '.bbbbbbbbbd.........',
    '.bbbbbbbbd..........',
    '..bbbbbbd...........',
    '..bb..bb............',
    '..bb..bb............',
    '..dd..dd............',
    '....................',
  ]);

  /// A slumped mass of wet wood and leaf litter, knuckle-walking. ⚠️ The caps
  /// crowd the back — they are the reason its outline is not a boulder.
  static const sporecapShambler = CreatureArt([
    '..........................',
    '.........aa...aaa.........',
    '........aaaa.aaaaa........',
    '.......aaaaaaaaaaaa.......',
    '.....aaaaAAaaaaAAaaa......',
    '....aaAA.....a...AAaa.....',
    '...bbbbbbbbbbbbbbbbbb.....',
    '..bbbbbbbbbbbbbbbbbbbb....',
    '.bbbbbbbbbbbbbbbbbbbbbd...',
    '.bbbbbbbbbbbbbbbbbbbbbd...',
    'bbbbbbbbbbbbbbbbbbbbbbdd..',
    'bbbbbbbbbbbbbbbbbbbbbbd...',
    'dbbbbbbbbbbbbbbbbbbbbd....',
    '.dbbbbbbbbbbbbbbbbbbd.....',
    '..ddbbbbbbbbbbbbbbdd......',
    '....bbb........bbb........',
    '....bbb........bbb........',
    '....ddd........ddd........',
    '..........................',
  ]);

  /// A writhing knot with no head. ⭐ The feeding tendrils fringe the
  /// underside — the one detail that must read, because it is what it does.
  static const bindweedCreeper = CreatureArt([
    '..........................',
    '.........bbbbb............',
    '.......bbbbbbbbb..........',
    '.....bbbbbbbbbbbbb........',
    '....bbbbllllbbbbbbbb......',
    '...bbbbllggllbbbbbbbb.....',
    '..bbbbbllllbbbbbbbbbbb....',
    '..bbbbbbbbbbbbbbbbbbbbb...',
    '.bbbbbbbbbbbbbbbbbbbbbbb..',
    '.bbbbbbbbbbbbbbbbbbbbbbd..',
    '.dbbbbbbbbbbbbbbbbbbbbd...',
    '..ddbbbbbbbbbbbbbbbbdd....',
    '....dddbbbbbbbbbbddd......',
    '..a..a.a..a.a..a..a.a.....',
    '..a..a.a..a.a..a..a.a.....',
    '..........................',
  ]);

  /// A single fist of braided root punched up out of the soil. ⚠️ Nothing
  /// above the wrist — it is a limb, not a body.
  static const rootknuckle = CreatureArt([
    '......................',
    '......bbbbbbbb........',
    '....bbbbbbbbbbbb......',
    '...bbbbbbbbbbbbbb.....',
    '..bbllbbllbbllbbbb....',
    '..bbllbbllbbllbbbbd...',
    '..bbbbbbbbbbbbbbbbd...',
    '.bbbbbbbbbbbbbbbbbbd..',
    '.bbbbbbbbbbbbbbbbbbd..',
    '.bbbbbbbbbbbbbbbbbd...',
    '..bbbbbbbbbbbbbbbd....',
    '...bbbbbbbbbbbbbd.....',
    '....bbbbbbbbbbbd......',
    '.....bbbbbbbbbd.......',
    '......bbbbbbbd........',
    '.......bbbbbd.........',
    '....eee.bbb.eeee......',
    '..eeeeeeeeeeeeeeee....',
    '.eeeeeeeeeeeeeeeeeee..',
    '......................',
  ]);

  // ---- mini-bosses -----------------------------------------------------

  /// Broad and low on six tapering legs, with one clouded amber knot for an
  /// eye. ⭐ Bull-sized — the silhouette is width, not height.
  static const elderroot = CreatureArt([
    '..............................',
    '.........bbbbbbbbbb...........',
    '.......bbbbbbbbbbbbbb.........',
    '.....bbbbbbbbbbbbbbbbbb.......',
    '....bbbbbbbbbbbbbbbbbbbbb.....',
    '...bbbbbbbbbbbbbbbbbbbbbbb....',
    '..bbbbbbbbbggbbbbbbbbbbbbbd...',
    '..bbbbbbbbbggbbbbbbbbbbbbbd...',
    '.bbbbbbbbbbbbbbbbbbbbbbbbbbd..',
    '.bbbbbbbbbbbbbbbbbbbbbbbbbd...',
    '.dbbbbbbbbbbbbbbbbbbbbbbbd....',
    '..ddbbbbbbbbbbbbbbbbbbbdd.....',
    '....dddbbbbbbbbbbbbbddd.......',
    '...bb...bb...bb...bb..bb......',
    '...bb...bb...bb...bb..bb......',
    '...dd...dd...dd...dd..dd......',
    '..............................',
  ]);

  /// A pale dome wider than it is tall, flush with the floor, gills beneath.
  /// ⚠️ Almost no vertical silhouette at all — that is the point.
  static const motherSpore = CreatureArt([
    '..............................',
    '..........llllll..............',
    '.......llllllllllll...........',
    '.....llllllllllllllll.........',
    '...aaaaaaaaaaaaaaaaaaaa.......',
    '..aaaaaaaaaaaaaaaaaaaaaa......',
    '.aaaaaaaaaaaaaaaaaaaaaaaa.....',
    'aaaaaaaaaaaaaaaaaaaaaaaaaa....',
    'AAAAAAAAAAAAAAAAAAAAAAAAAA....',
    '.AAAAAAAAAAAAAAAAAAAAAAAA.....',
    '.A.A.A.A.A.A.A.A.A.A.A.A.A....',
    '.A.A.A.A.A.A.A.A.A.A.A.A.A....',
    '..bbbbbbbbbbbbbbbbbbbbbb......',
    '...a...a....a....a...a........',
    '..............................',
  ]);

  /// A stag with the ribcage open and empty — ⭐ you can see the forest
  /// through it. Antlers still in leaf.
  static const hollowStag = CreatureArt([
    '..............................',
    '..aa..................aa......',
    '...aa................aa.......',
    '....aa..............aa........',
    '.....aaa..........aaa.........',
    '.......aa........aa...........',
    '........aa......aa............',
    '.........bbbbbbbb.............',
    '.........bbeeeebb.............',
    '.........bbbbbbbb.............',
    '..........bbbbbb..............',
    '...........bbbb...............',
    '......bbbbbbbbbbbbbbb.........',
    '....bbbbbbbbbbbbbbbbbbb.......',
    '...bb.b.b.b.b.b.b.b.bbbd......',
    '...bb.b.b.b.b.b.b.b.bbbd......',
    '...bb.b.b.b.b.b.b.b.bbd.......',
    '...bbbbbbbbbbbbbbbbbbd........',
    '....dbbbbbbbbbbbbbbdd.........',
    '.....bb..........bb...........',
    '.....bb..........bb...........',
    '.....bb..........bb...........',
    '.....dd..........dd...........',
    '..............................',
  ]);

  /// Barely a body — hanging root-hair and moss, drifting clear of the
  /// ground. ⭐ The dark hollows are the only features, at uneven heights.
  static const theMurmur = CreatureArt([
    '....................',
    '......bbbbbbb.......',
    '....bbbbbbbbbbb.....',
    '...bbbbbbbbbbbbb....',
    '..bbbbbeebbbbbbbb...',
    '..bbbbbeebbbbbbbb...',
    '..bbbbbbbbbbeebbb...',
    '..bbbbbbbbbbeebbb...',
    '.bbbeebbbbbbbbbbbd..',
    '.bbbeebbbbbbbbbbbd..',
    '.bbbbbbbbbbbbbbbbd..',
    '.bbbbbbbbeebbbbbbd..',
    '.bbbbbbbbeebbbbbbd..',
    '.dbbbbbbbbbbbbbbd...',
    '.d.b.b.d.b.b.d.b....',
    '.d.b.b.d.b.b.d.b....',
    '...b...d...b...b....',
    '...b...d...b........',
    '....................',
  ]);

  // ---- bosses ----------------------------------------------------------

  /// An ancient tree half out of the earth, walking on splayed root. ⚠️ The
  /// vertical cleft is the wound — pale, wet, and lit from inside.
  static const heartwood = CreatureArt([
    '..............................',
    '.....aaaa......aaaa...........',
    '...aaaaaaaa..aaaaaaaa.........',
    '..aaaaaaaaaaaaaaaaaaaaa.......',
    '.aaaaaaaaaaaaaaaaaaaaaaa......',
    'aaaaaaaaaaaaaaaaaaaaaaaaa.....',
    '.aaaaaaaaaaaaaaaaaaaaaaa......',
    '...aaaaaaaaaaaaaaaaaaa........',
    '......bbbbbbbbbbbbb...........',
    '......bbbbbggbbbbbd...........',
    '......bbbbGggGbbbbd...........',
    '......bbbbGggGbbbbd...........',
    '......bbbbGggGbbbbd...........',
    '......bbbbbggbbbbbd...........',
    '......bbbbbggbbbbbd...........',
    '.....bbbbbbggbbbbbbd..........',
    '.....bbbbbbbbbbbbbbd..........',
    '....bbbbbbbbbbbbbbbbd.........',
    '....bbbbbbbbbbbbbbbbd.........',
    '...bbbbbbbbbbbbbbbbbbd........',
    '..bbbbb.bbbbbbbb.bbbbbd.......',
    '.bbbbb...bbbbbb...bbbbbd......',
    'bbbb......bbbb......bbbbd.....',
    'ddd........dd........dddd.....',
    '..............................',
  ]);

  /// A person, grown from plants. ⭐ Slightly too tall and too thin, and
  /// perfectly still — unsettling because it is nearly correct.
  static const theStandingGreen = CreatureArt([
    '....................',
    '.......llll.........',
    '......llllll........',
    '.....llbbbbll.......',
    '.....lbbbbbbl.......',
    '.....lbbbbbbl.......',
    '.....abbbbbba.......',
    '......bbbbbb........',
    '.......bbbb.........',
    '......bbbbbb........',
    '.....bbbbbbbb.......',
    '....bbbbbbbbbb......',
    '...bbbbbbbbbbbb.....',
    '...bbbbbbbbbbbd.....',
    '...bbbbbbbbbbbd.....',
    '...bbbbbbbbbbbd.....',
    '..bbbbbbbbbbbbbd....',
    '..bbbbbbbbbbbbbd....',
    '..bbbb.bbbb.bbbd....',
    '..bbb...bb...bbd....',
    '...bb...bb...bb.....',
    '...bb...bb...bb.....',
    '...bb........bb.....',
    '...bb........bb.....',
    '...dd........dd.....',
    '....................',
  ]);

  /// Every creature in the zone, by enemy id.
  static const byEnemyId = <String, CreatureArt>{
    'listening_fawn': listeningFawn,
    'thornback_sprite': thornbackSprite,
    'sporecap_shambler': sporecapShambler,
    'bindweed_creeper': bindweedCreeper,
    'rootknuckle': rootknuckle,
    'elderroot': elderroot,
    'mother_spore': motherSpore,
    'hollow_stag': hollowStag,
    'the_murmur': theMurmur,
    'heartwood': heartwood,
    'the_standing_green': theStandingGreen,
  };
}
