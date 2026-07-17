import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'action.dart';
import 'element.dart';
import 'spellbook.dart';

/// Trustless building blocks for commit-reveal PvP.
///
/// Each turn, both players first publish a **commitment** — a hash of their
/// move plus a secret nonce — so neither can peek at the other's move. Once
/// both commitments are posted, both **reveal** the move and nonce; each side
/// verifies the other's reveal matches the commitment, then feeds both moves
/// into the shared deterministic [DuelEngine]. Damage rolls stay hidden until
/// reveal because they depend on both moves (see the duel transport, which
/// derives each turn's RNG seed from the revealed pair).
///
/// These functions are pure and transport-agnostic — the Firestore layer sits
/// on top of them.

/// Canonical wire encoding of a [MageAction]. Stable across clients so the
/// same move always produces the same commitment hash.
///   channel: `C|<element>`
///   cast:    `S|<spellId>|<element>`
/// `<element>` is the element name, or empty for null (continuing a cycle).
String encodeAction(MageAction action) {
  return switch (action) {
    ForfeitAction() => 'F',
    ChargeAction(:final element) => 'C|${element?.name ?? ''}',
    CastAction(:final spell, :final element) =>
      'S|${spell.id}|${element?.name ?? ''}',
  };
}

/// Inverse of [encodeAction]. Throws [FormatException] on malformed input.
MageAction decodeAction(String wire) {
  MagicElement? elem(String s) =>
      s.isEmpty ? null : MagicElement.values.byName(s);
  final parts = wire.split('|');
  switch (parts.first) {
    case 'F' when parts.length == 1:
      return const ForfeitAction();
    case 'C' when parts.length == 2:
      return ChargeAction(elem(parts[1]));
    case 'S' when parts.length == 3:
      return CastAction(Spellbook.byId(parts[1]), elem(parts[2]));
    default:
      throw FormatException('Malformed action wire: "$wire"');
  }
}

/// A commitment hides a move behind a secret nonce: `sha256(move|nonce)`.
/// Published before the reveal so the opponent's move can't be peeked.
String commitmentOf(String moveWire, String nonce) =>
    sha256.convert(utf8.encode('$moveWire|$nonce')).toString();

/// Checks a revealed (move, nonce) against the earlier commitment. A false
/// result means the opponent tried to change their move after committing.
bool verifyCommitment(String commitment, String moveWire, String nonce) =>
    commitmentOf(moveWire, nonce) == commitment;

/// Per-turn RNG seed both clients agree on: derived from a duel-long master
/// seed, the turn number, and BOTH revealed moves. Because it depends on the
/// opponent's move (unknown at commit time), neither player can predict their
/// damage rolls before locking in.
int deriveTurnSeed(int masterSeed, int turn, String moveA, String moveB) {
  // Sort the two moves so both clients derive the same seed regardless of
  // which side they consider "A".
  final moves = [moveA, moveB]..sort();
  final digest =
      sha256.convert(utf8.encode('$masterSeed|$turn|${moves.join('|')}'));
  var seed = 0;
  for (var i = 0; i < 4; i++) {
    seed = (seed << 8) | digest.bytes[i];
  }
  return seed;
}

/// A [Random] whose stream can be replaced mid-duel. Networked duels hand
/// this to [DuelEngine] and call [reseed] with [deriveTurnSeed]'s output
/// before each turn, so both clients roll identical damage without either
/// being able to predict it at commit time.
class ReseedableRandom implements Random {
  Random _inner;

  ReseedableRandom([int? seed]) : _inner = Random(seed);

  void reseed(int seed) => _inner = Random(seed);

  @override
  bool nextBool() => _inner.nextBool();

  @override
  double nextDouble() => _inner.nextDouble();

  @override
  int nextInt(int max) => _inner.nextInt(max);
}
