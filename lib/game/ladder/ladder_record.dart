import '../player_profile.dart';

/// Applies one rated result to [p]'s fields for the [academy] (vs Geared)
/// ladder (LADDER_DESIGN §2): sets the new rating, bumps the rated-games
/// counter, raises the peak if the new rating exceeds it, and — for the
/// Academy only — bumps that ladder's own win/loss count.
///
/// ⚠️ **The geared record is NOT touched here.** `duelsWon`/`duelsLost` are
/// bumped by `GameState.recordDuelResult`, which every geared duel (bot or
/// human) already goes through for XP and gold; counting them here too
/// would double every geared result. The Academy banks nothing through that
/// path (ruled 2026-09-10), so its record has to live here.
///
/// ⭐ **Pure mutation of the passed profile; [newRating] is the caller's to
/// compute.** The Elo math (`Elo.delta`) lives in `mom_engine`, being
/// written in a parallel lane — this helper must not depend on it, so it
/// takes the already-computed rating rather than the two ratings and a
/// score.
///
/// ⚠️ **Peak only rises, never falls.** LADDER §2's "reached 2400" K-10 rule
/// reads the peak, not the current rating, so a loss that drops
/// `ratingGeared` below a past high must not erase that high.
void applyRatedResult(
  PlayerProfile p, {
  required bool academy,
  required int newRating,
  required bool won,
}) {
  if (academy) {
    p.ratingAcademy = newRating;
    p.ratedGamesAcademy++;
    if (newRating > p.peakAcademy) p.peakAcademy = newRating;
    if (won) {
      p.academyWins++;
    } else {
      p.academyLosses++;
    }
  } else {
    p.ratingGeared = newRating;
    p.ratedGamesGeared++;
    if (newRating > p.peakGeared) p.peakGeared = newRating;
  }
}
