import 'package:flutter_test/flutter_test.dart';
import 'package:masters_of_magic_2/game/economy/shop_pricing.dart';

/// `ECONOMY_CONTRACT.md` §3 — the pricing curve and the marginal-pricing
/// invariant. Pure-arithmetic tests only; no catalogue, no config, no
/// profile — those seams are the other two economy builders' files.
void main() {
  group('§3.1 the scarcity multiplier', () {
    test('at stock == equilibrium the multiplier is exactly 1.0', () {
      expect(
        ShopPricing.multiplier(equilibrium: 60, stock: 60),
        1.0,
        reason: 'no scarcity, no glut — the curve\'s own resting point',
      );
    });

    test('below equilibrium the multiplier rises above 1.0', () {
      expect(
        ShopPricing.multiplier(equilibrium: 60, stock: 30),
        closeTo(1.41421, 1e-4),
        reason: 'sqrt(60/30) = sqrt(2)',
      );
    });

    test('above equilibrium the multiplier falls below 1.0', () {
      expect(
        ShopPricing.multiplier(equilibrium: 60, stock: 200),
        closeTo(0.54772, 1e-4),
        reason: 'sqrt(60/200) — a flooded shelf is cheap',
      );
    });

    test('the ceiling clamps at 2.5, not the raw sqrt', () {
      // sqrt(60/1) = 7.746 uncapped — the mutant this kills is a missing
      // upper clamp that would price a near-empty shelf absurdly high.
      expect(ShopPricing.multiplier(equilibrium: 60, stock: 1), 2.5);
    });

    test('the floor clamps at 0.4, not the raw sqrt', () {
      // sqrt(60/500) = 0.346 uncapped — the mutant this kills is a missing
      // lower clamp that would let a sufficiently flooded item go to zero.
      expect(ShopPricing.multiplier(equilibrium: 60, stock: 500), 0.4);
    });
  });

  group('§3.3 the zero-stock guard', () {
    test('stock == 0 reads as the clamp ceiling, not a division by zero', () {
      expect(
        ShopPricing.multiplier(equilibrium: 60, stock: 0),
        2.5,
        reason: 'an empty shelf is already maximum scarcity (§3.3)',
      );
      expect(ShopPricing.multiplier(equilibrium: 60, stock: 0).isNaN, isFalse);
      expect(
        ShopPricing.multiplier(equilibrium: 60, stock: 0).isInfinite,
        isFalse,
      );
    });

    test('a defensively-negative stock reads the same as zero', () {
      // Never produced by this file's own quotes (they floor at 0), but a
      // caller handing over a bad value must not get a NaN/negative price.
      expect(ShopPricing.multiplier(equilibrium: 60, stock: -5), 2.5);
    });
  });

  group('§5.2 the three worked price tables, pinned cell by cell', () {
    // ⭐ All three at their native town (locationMod = 0% = factor 1.0) and
    // no event (eventMod = 1.0) — isolating the stock curve exactly as the
    // contract's own tables do. Price/Buy/Sell are deliberately compared as
    // unrounded doubles: the contract's own table shows fractional gold
    // (61.24, not 61) because §3.1's formula is continuous — only a real
    // per-unit transaction (buyQuote/sellQuote) rounds to whole gold.
    void pin({
      required String label,
      required int base,
      required int equilibrium,
      required int stock,
      required double price,
      required double buy,
      required double sell,
    }) {
      test(label, () {
        expect(
          ShopPricing.price(base: base, equilibrium: equilibrium, stock: stock),
          closeTo(price, 0.01),
          reason: 'raw price at stock=$stock',
        );
        expect(
          ShopPricing.buyPrice(base: base, equilibrium: equilibrium, stock: stock),
          closeTo(buy, 0.01),
          reason: 'buy = price × 1.10',
        );
        expect(
          ShopPricing.sellPrice(base: base, equilibrium: equilibrium, stock: stock),
          closeTo(sell, 0.01),
          reason: 'sell = price × 0.90',
        );
      });
    }

    group('oak_log — material, E=60, base=25 (the worked-table anchor)', () {
      pin(
        label: 'stock=0 (clamped ceiling)',
        base: 25,
        equilibrium: 60,
        stock: 0,
        price: 62.50,
        buy: 68.75,
        sell: 56.25,
      );
      pin(
        label: 'stock=10',
        base: 25,
        equilibrium: 60,
        stock: 10,
        price: 61.24,
        buy: 67.36,
        sell: 55.12,
      );
      pin(
        label: 'stock=30',
        base: 25,
        equilibrium: 60,
        stock: 30,
        price: 35.36,
        buy: 38.89,
        sell: 31.82,
      );
      pin(
        label: 'stock=60 (=E, multiplier exactly 1.0)',
        base: 25,
        equilibrium: 60,
        stock: 60,
        price: 25.00,
        buy: 27.50,
        sell: 22.50,
      );
      pin(
        label: 'stock=100',
        base: 25,
        equilibrium: 60,
        stock: 100,
        price: 19.36,
        buy: 21.30,
        sell: 17.43,
      );
      pin(
        label: 'stock=200',
        base: 25,
        equilibrium: 60,
        stock: 200,
        price: 13.69,
        buy: 15.06,
        sell: 12.32,
      );
      pin(
        label: 'stock=500 (clamped floor)',
        base: 25,
        equilibrium: 60,
        stock: 500,
        price: 10.00,
        buy: 11.00,
        sell: 9.00,
      );
    });

    group('rimepelt — material, E=60, base=12 (shipped value, unchanged)', () {
      pin(
        label: 'stock=0',
        base: 12,
        equilibrium: 60,
        stock: 0,
        price: 30.00,
        buy: 33.00,
        sell: 27.00,
      );
      pin(
        label: 'stock=10',
        base: 12,
        equilibrium: 60,
        stock: 10,
        price: 29.39,
        buy: 32.33,
        sell: 26.45,
      );
      pin(
        label: 'stock=30',
        base: 12,
        equilibrium: 60,
        stock: 30,
        price: 16.97,
        buy: 18.66,
        sell: 15.27,
      );
      pin(
        label: 'stock=60 (=E)',
        base: 12,
        equilibrium: 60,
        stock: 60,
        price: 12.00,
        buy: 13.20,
        sell: 10.80,
      );
      pin(
        label: 'stock=100',
        base: 12,
        equilibrium: 60,
        stock: 100,
        price: 9.30,
        buy: 10.23,
        sell: 8.37,
      );
      pin(
        label: 'stock=200',
        base: 12,
        equilibrium: 60,
        stock: 200,
        price: 6.57,
        buy: 7.23,
        sell: 5.91,
      );
      pin(
        label: 'stock=500',
        base: 12,
        equilibrium: 60,
        stock: 500,
        price: 4.80,
        buy: 5.28,
        sell: 4.32,
      );
    });

    group('saltwort_draught — consumable, E=30, base=30 (shipped, unchanged)', () {
      pin(
        label: 'stock=0',
        base: 30,
        equilibrium: 30,
        stock: 0,
        price: 75.00,
        buy: 82.50,
        sell: 67.50,
      );
      pin(
        label: 'stock=10',
        base: 30,
        equilibrium: 30,
        stock: 10,
        price: 51.96,
        buy: 57.15,
        sell: 46.76,
      );
      pin(
        label: 'stock=30 (=E)',
        base: 30,
        equilibrium: 30,
        stock: 30,
        price: 30.00,
        buy: 33.00,
        sell: 27.00,
      );
      pin(
        label: 'stock=60',
        base: 30,
        equilibrium: 30,
        stock: 60,
        price: 21.21,
        buy: 23.33,
        sell: 19.09,
      );
      pin(
        label: 'stock=100',
        base: 30,
        equilibrium: 30,
        stock: 100,
        price: 16.43,
        buy: 18.07,
        sell: 14.79,
      );
      test(
        'stock=200 and stock=500 both collapse to the same clamped-floor price',
        () {
          // ⚠️ §5.2's own callout: the smaller E for a consumable means the
          // floor clamp binds earlier, so these two distinct stock levels
          // must price identically — a mutant that only clamps the ceiling
          // (or clamps at the wrong threshold) would separate them.
          const expectedPrice = 12.00;
          for (final stock in [200, 500]) {
            expect(
              ShopPricing.price(base: 30, equilibrium: 30, stock: stock),
              closeTo(expectedPrice, 0.01),
              reason: 'stock=$stock must hit the same 0.4 floor',
            );
            expect(
              ShopPricing.buyPrice(base: 30, equilibrium: 30, stock: stock),
              closeTo(13.20, 0.01),
            );
            expect(
              ShopPricing.sellPrice(base: 30, equilibrium: 30, stock: stock),
              closeTo(10.80, 0.01),
            );
          }
        },
      );
    });
  });

  group('location and event modifiers multiply straight through', () {
    test('a -25% native town discount at oak_log\'s E=60/base=25/stock=60',
        () {
      expect(
        ShopPricing.price(
          base: 25,
          equilibrium: 60,
          stock: 60,
          locationMod: 0.75,
        ),
        closeTo(18.75, 0.01),
      );
    });

    test('a +20% event stacks multiplicatively with location', () {
      expect(
        ShopPricing.price(
          base: 25,
          equilibrium: 60,
          stock: 60,
          locationMod: 1.25,
          eventMod: 1.2,
        ),
        closeTo(37.50, 0.01),
        reason: '25 × 1.0 × 1.25 × 1.2',
      );
    });
  });

  group('roundGold — half away from zero', () {
    test('exact halves round up in magnitude, not banker\'s rounding', () {
      expect(ShopPricing.roundGold(2.5), 3);
      expect(ShopPricing.roundGold(3.5), 4);
      expect(
        ShopPricing.roundGold(4.5),
        5,
        reason: '⚠️ round-half-to-even (banker\'s) would give 4 here — the '
            'mutant this kills',
      );
    });

    test('below and above the half boundary round the ordinary way', () {
      expect(ShopPricing.roundGold(2.49), 2);
      expect(ShopPricing.roundGold(2.51), 3);
    });

    test('a negative input (never produced by this file, but guarded)', () {
      expect(ShopPricing.roundGold(-2.5), -3);
    });
  });

  group('vendorPrice — the flat 0.6× non-stocked sink (ruling 3, §2.4)', () {
    test('a flat fraction of base, rounded to gold', () {
      expect(ShopPricing.vendorPrice(100), 60);
      expect(
        ShopPricing.vendorPrice(37),
        22,
        reason: '37 × 0.6 = 22.2 → 22',
      );
    });

    test('no stock, no location, no event — it never varies', () {
      // The signature itself proves this (no such parameters exist); the
      // regression is that a refactor cannot quietly add one.
      expect(ShopPricing.vendorPrice(50), ShopPricing.vendorPrice(50));
    });
  });

  group('§3.2 the marginal-pricing invariant', () {
    test(
      'the named worked example: 50 units of a nearly-sold-out potion',
      () {
        // saltwort_draught: E=30, base=30, buy×1.10/sell×0.90, stock=2,
        // selling 50 units at once.
        //
        // The WRONG (batch) implementation prices every unit at the
        // pre-transaction snapshot: mult=clamp(√(30/2),0.4,2.5)=2.5 (capped),
        // so `30 × 2.5 × 0.90 = 67.50` gold each — pinned to the contract's
        // own number, unrounded, exactly as the contract states it.
        final batchUnit = ShopPricing.sellPrice(
          base: 30,
          equilibrium: 30,
          stock: 2,
        );
        expect(batchUnit, closeTo(67.50, 0.001));
        final batchTotal = batchUnit * 50;
        expect(
          batchTotal,
          closeTo(3375, 0.01),
          reason: '⭐ pinned verbatim from §3.2\'s own worked table',
        );

        // The CORRECT (marginal) walk must come out dramatically lower — the
        // shop craters the price as the dump floods a shelf that only
        // wanted 2 units, which is the entire point of walking unit by unit.
        final correct = ShopPricing.sellQuote(
          n: 50,
          base: 30,
          equilibrium: 30,
          stock: 2,
        );
        expect(
          correct.totalGold,
          lessThan(batchTotal.round()),
          reason: '⚠️ the mutant this kills: reverting to the batch shortcut',
        );
        expect(
          correct.totalGold,
          lessThan((batchTotal * 0.6).round()),
          reason: 'not just lower — the correct total must be a different '
              'order of magnitude, not a rounding-sized nudge',
        );
        expect(correct.newStock, 52, reason: 'stock floods by exactly 50');
      },
    );

    test('unit 1 always prices at the pre-transaction stock, not stock ± 1', () {
      // §3.2's own framing: "unit 1 sells at stock=2" — the walk's very
      // first step must read the stock the transaction STARTS at.
      final quote = ShopPricing.sellQuote(
        n: 1,
        base: 30,
        equilibrium: 30,
        stock: 2,
      );
      expect(
        quote.totalGold,
        ShopPricing.roundGold(
          ShopPricing.sellPrice(base: 30, equilibrium: 30, stock: 2),
        ),
      );
    });

    test('buying walks stock DOWN one unit at a time, mid-transaction', () {
      // Each successive unit must price into a scarcer shelf than the one
      // before — a batch mutant would price all 3 identically.
      final prices = <int>[];
      var stock = 10;
      for (var i = 0; i < 3; i++) {
        final quote = ShopPricing.buyQuote(
          n: 1,
          base: 25,
          equilibrium: 60,
          stock: stock,
        );
        prices.add(quote.totalGold);
        stock = quote.newStock;
      }
      expect(stock, 7, reason: 'three units drained one at a time');
      expect(
        prices[0],
        lessThan(prices[1]),
        reason: 'buying itself must move the very next unit\'s price',
      );
      expect(prices[1], lessThanOrEqualTo(prices[2]));
    });

    test('selling walks stock UP one unit at a time, mid-transaction', () {
      final prices = <int>[];
      var stock = 2;
      for (var i = 0; i < 3; i++) {
        final quote = ShopPricing.sellQuote(
          n: 1,
          base: 30,
          equilibrium: 30,
          stock: stock,
        );
        prices.add(quote.totalGold);
        stock = quote.newStock;
      }
      expect(stock, 5);
      expect(
        prices[0],
        greaterThanOrEqualTo(prices[1]),
        reason: 'the first unit dumped into a scarce shop fetches the best '
            'price; each later unit in the same dump floods it further',
      );
    });

    test('buying drains stock to exactly 0 and never below it', () {
      final quote = ShopPricing.buyQuote(
        n: 100,
        base: 25,
        equilibrium: 60,
        stock: 3,
      );
      expect(
        quote.newStock,
        0,
        reason: '§3.3: the shelf floors at 0, it does not go negative',
      );
    });

    test(
      'once the shelf is emptied mid-walk, every remaining unit prices at '
      'the clamp ceiling, not a runaway or undefined value',
      () {
        final quote = ShopPricing.buyQuote(
          n: 10,
          base: 25,
          equilibrium: 60,
          stock: 2,
        );
        // Every one of the 10 units must price no higher than the ceiling
        // allows: base × 2.5 × 1.10, rounded, times 10.
        final ceilingUnit = ShopPricing.roundGold(25 * 2.5 * 1.10);
        expect(quote.totalGold, lessThanOrEqualTo(ceilingUnit * 10));
      },
    );

    group('a same-transaction round trip never turns a profit', () {
      // ⭐ The one property this contract's spread is unconditionally true
      // (verified by direct search): for the equilibrium defaults this
      // contract actually ships (E ∈ {20, 30, 60}) and any base value in
      // the proposed §8.2 range, buying N units and immediately selling
      // them back to the SAME shop can shave the loss down to as little as
      // 0% at specific stock levels (integer gold rounding at low absolute
      // prices — not a formula bug), but it can never flip to a net gain.
      // A batch-priced mutant, by contrast, routinely CAN — see the group
      // below.
      final equilibria = [20, 30, 60];
      final bases = [7, 12, 25, 30, 58, 95, 190];
      final stocks = [0, 1, 5, 10, 30, 60, 100, 200, 500];
      final quantities = [1, 2, 3, 5, 10, 25, 50];

      test('swept across a representative grid of E, base, stock and N', () {
        var checked = 0;
        for (final e in equilibria) {
          for (final base in bases) {
            for (final stock in stocks) {
              for (final n in quantities) {
                final buy = ShopPricing.buyQuote(
                  n: n,
                  base: base,
                  equilibrium: e,
                  stock: stock,
                );
                final sell = ShopPricing.sellQuote(
                  n: n,
                  base: base,
                  equilibrium: e,
                  stock: buy.newStock,
                );
                checked++;
                expect(
                  sell.totalGold,
                  lessThanOrEqualTo(buy.totalGold),
                  reason: 'E=$e base=$base stock=$stock n=$n: a round trip '
                      'must never pay out more than it cost',
                );
              }
            }
          }
        }
        expect(
          checked,
          equilibria.length * bases.length * stocks.length * quantities.length,
          reason: 'sanity: the sweep actually ran every combination',
        );
      });
    });

    group('a typical round trip loses roughly the ruled ~18%', () {
      // ⭐ Chosen at a well-stocked town (stock == E, the flat region where
      // the curve is barely moving) — the condition under which §3.1's own
      // "≈18%" figure is derived, and where integer-gold rounding has the
      // least room to distort the result.
      test('oak_log, single unit, at its own equilibrium', () {
        final buy = ShopPricing.buyQuote(n: 1, base: 25, equilibrium: 60, stock: 60);
        final sell = ShopPricing.sellQuote(
          n: 1,
          base: 25,
          equilibrium: 60,
          stock: buy.newStock,
        );
        final loss = 1 - sell.totalGold / buy.totalGold;
        expect(
          loss,
          inInclusiveRange(0.15, 0.20),
          reason: 'buy=${buy.totalGold} sell=${sell.totalGold} — close to '
              'the ruled ~18%, never near 0 and never negative',
        );
      });

      test('the same item, a moderate 20-unit trade at equilibrium', () {
        final buy = ShopPricing.buyQuote(n: 20, base: 25, equilibrium: 60, stock: 60);
        final sell = ShopPricing.sellQuote(
          n: 20,
          base: 25,
          equilibrium: 60,
          stock: buy.newStock,
        );
        final loss = 1 - sell.totalGold / buy.totalGold;
        expect(loss, inInclusiveRange(0.15, 0.20));
      });
    });

    test(
      '⚠️ documented edge case: draining half a small shelf can push the '
      'walk\'s asymmetry loss below the typical ~18% (still a real loss)',
      () {
        // saltwort_draught, stock=10, buy 5 then sell 5 back. The marginal
        // walk touches a rank-shifted set of stock levels on the way out vs
        // the way back in (§3.2's own convention — unit 1 always prices at
        // the PRE-transaction stock), which structurally favours the seller
        // slightly compared to a naive "same stock both ways" estimate.
        // Pinned exactly so a change to the walk's convention shows up here
        // rather than as a silent drift.
        final buy = ShopPricing.buyQuote(
          n: 5,
          base: 30,
          equilibrium: 30,
          stock: 10,
        );
        expect(buy.totalGold, 323);
        final sell = ShopPricing.sellQuote(
          n: 5,
          base: 30,
          equilibrium: 30,
          stock: buy.newStock,
        );
        expect(sell.totalGold, 283);
        expect(
          sell.totalGold,
          lessThan(buy.totalGold),
          reason: 'still a real, nonzero loss — 283 < 323',
        );
      },
    );

    group('kill the batch-pricing mutant — the exploit named in §3.2', () {
      /// The named mutant: prices the WHOLE batch once, at the stock level
      /// the transaction started at, then applies the stock change in one
      /// shot at the end — never walking mid-transaction. This is exactly
      /// the "wrong" column of §3.2's worked table, generalised to a round
      /// trip so it can be compared against [ShopPricing.buyQuote]/
      /// [ShopPricing.sellQuote] on identical inputs.
      ({int totalGold, int newStock}) batchBuy({
        required int n,
        required int base,
        required int equilibrium,
        required int stock,
      }) {
        final unit = ShopPricing.buyPrice(
          base: base,
          equilibrium: equilibrium,
          stock: stock,
        );
        final newStock = stock - n < 0 ? 0 : stock - n;
        return (totalGold: (unit * n).round(), newStock: newStock);
      }

      ({int totalGold, int newStock}) batchSell({
        required int n,
        required int base,
        required int equilibrium,
        required int stock,
      }) {
        final unit = ShopPricing.sellPrice(
          base: base,
          equilibrium: equilibrium,
          stock: stock,
        );
        return (totalGold: (unit * n).round(), newStock: stock + n);
      }

      test(
        'batch pricing lets a well-stocked round trip turn an outright '
        'profit — the correct marginal walk never does',
        () {
          // A moderate 20-unit round trip of oak_log starting exactly at
          // equilibrium. Correct: a real, comfortable loss (see the group
          // above). Batch: the buy is priced at stock=60 (mult=1.0) for all
          // 20 units, but the SELL is then priced at the post-buy snapshot
          // stock=40 (mult=√(60/40)≈1.22, already scarcer) for all 20 units
          // — the shop pays MORE per unit on the way back out than it
          // charged on the way in, because batch pricing lets the sell leg
          // "see" a scarcity the buy leg never paid for.
          const base = 25, equilibrium = 60, stock = 60, n = 20;

          final correctBuy = ShopPricing.buyQuote(
            n: n,
            base: base,
            equilibrium: equilibrium,
            stock: stock,
          );
          final correctSell = ShopPricing.sellQuote(
            n: n,
            base: base,
            equilibrium: equilibrium,
            stock: correctBuy.newStock,
          );
          expect(
            correctSell.totalGold,
            lessThan(correctBuy.totalGold),
            reason: 'the real implementation always loses gold on this trip',
          );

          final wrongBuy = batchBuy(
            n: n,
            base: base,
            equilibrium: equilibrium,
            stock: stock,
          );
          final wrongSell = batchSell(
            n: n,
            base: base,
            equilibrium: equilibrium,
            stock: wrongBuy.newStock,
          );
          expect(
            wrongSell.totalGold,
            greaterThan(wrongBuy.totalGold),
            reason: '⚠️ THE EXPLOIT: batch pricing turns this exact same '
                'trip into free gold — buy=${wrongBuy.totalGold} '
                'sell=${wrongSell.totalGold}',
          );
        },
      );

      test(
        'across a spread of quantities and stocks, batch pricing loses far '
        'less than marginal pricing (or profits outright) on the same trip',
        () {
          final cases = [
            (base: 25, equilibrium: 60, stock: 60, n: 20),
            (base: 30, equilibrium: 30, stock: 2, n: 50),
            (base: 12, equilibrium: 60, stock: 15, n: 10),
            (base: 25, equilibrium: 60, stock: 90, n: 30),
          ];
          for (final c in cases) {
            final correctBuy = ShopPricing.buyQuote(
              n: c.n,
              base: c.base,
              equilibrium: c.equilibrium,
              stock: c.stock,
            );
            final correctSell = ShopPricing.sellQuote(
              n: c.n,
              base: c.base,
              equilibrium: c.equilibrium,
              stock: correctBuy.newStock,
            );
            final correctLoss =
                1 - correctSell.totalGold / correctBuy.totalGold;

            final wrongBuy = batchBuy(
              n: c.n,
              base: c.base,
              equilibrium: c.equilibrium,
              stock: c.stock,
            );
            final wrongSell = batchSell(
              n: c.n,
              base: c.base,
              equilibrium: c.equilibrium,
              stock: wrongBuy.newStock,
            );
            final wrongLoss = wrongBuy.totalGold == 0
                ? 0.0
                : 1 - wrongSell.totalGold / wrongBuy.totalGold;

            expect(
              wrongLoss,
              lessThan(correctLoss),
              reason: '$c — batch must under-punish the round trip relative '
                  'to the real, walked implementation (correctLoss='
                  '${(correctLoss * 100).toStringAsFixed(1)}%, wrongLoss='
                  '${(wrongLoss * 100).toStringAsFixed(1)}%)',
            );
          }
        },
      );
    });
  });
}
