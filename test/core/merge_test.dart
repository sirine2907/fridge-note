import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/core/sync/local_clock.dart';
import 'package:fridge_note/core/sync/merge.dart';
import 'package:fridge_note/core/sync/record_patch.dart';

void main() {
  group('mergeFields', () {
    test('takes every column of a brand new row', () {
      final result = mergeFields(
        currentValues: {},
        currentTimes: {},
        incomingValues: {'name': 'Milk', 'checked': false},
        incomingTimes: {'name': 5, 'checked': 5},
      );
      expect(result.values, {'name': 'Milk', 'checked': false});
      expect(result.changed, isTrue);
    });

    test('the newer value wins, column by column', () {
      final result = mergeFields(
        currentValues: {'name': 'Milk', 'checked': true},
        currentTimes: {'name': 100, 'checked': 300},
        incomingValues: {'name': 'Oat milk', 'checked': false},
        incomingTimes: {'name': 200, 'checked': 200},
      );
      expect(result.values['name'], 'Oat milk', reason: 'rename is newer');
      expect(result.values['checked'], isTrue, reason: 'the check is newer than the uncheck');
      expect(result.times, {'name': 200, 'checked': 300});
    });

    test('a rename never undoes a check, because they are different columns', () {
      // Sirine checks Milk at 10:00:01, Anis renames it at 10:00:05.
      final checked = mergeFields(
        currentValues: {'name': 'Milk', 'checked': false},
        currentTimes: {'name': 1, 'checked': 1},
        incomingValues: {'checked': true},
        incomingTimes: {'checked': 1001},
      );
      final renamed = mergeFields(
        currentValues: checked.values,
        currentTimes: checked.times,
        incomingValues: {'name': 'Whole milk'},
        incomingTimes: {'name': 5001},
      );
      expect(renamed.values, {'name': 'Whole milk', 'checked': true});
    });

    test('an older change is ignored and reports no change', () {
      final result = mergeFields(
        currentValues: {'quantity': 3},
        currentTimes: {'quantity': 50},
        incomingValues: {'quantity': 1},
        incomingTimes: {'quantity': 10},
      );
      expect(result.values['quantity'], 3);
      expect(result.changed, isFalse);
    });

    test('applying the same change twice changes nothing the second time', () {
      final first = mergeFields(
        currentValues: {'checked': false},
        currentTimes: {'checked': 1},
        incomingValues: {'checked': true},
        incomingTimes: {'checked': 2},
      );
      final again = mergeFields(
        currentValues: first.values,
        currentTimes: first.times,
        incomingValues: {'checked': true},
        incomingTimes: {'checked': 2},
      );
      expect(again.changed, isFalse);
    });

    test('on an exact tie both devices pick the same value, and a check wins', () {
      final onPhoneA = mergeFields(
        currentValues: {'checked': true},
        currentTimes: {'checked': 7},
        incomingValues: {'checked': false},
        incomingTimes: {'checked': 7},
      );
      final onPhoneB = mergeFields(
        currentValues: {'checked': false},
        currentTimes: {'checked': 7},
        incomingValues: {'checked': true},
        incomingTimes: {'checked': 7},
      );
      expect(onPhoneA.values['checked'], isTrue);
      expect(onPhoneB.values['checked'], isTrue);
    });

    test('the order changes arrive in does not matter', () {
      final changes = [
        ({'name': 'Eggs'}, {'name': 3}),
        ({'quantity': 6}, {'quantity': 9}),
        ({'name': 'Free range eggs', 'quantity': 12}, {'name': 8, 'quantity': 4}),
      ];

      Map<String, Object?> apply(List<int> order) {
        var values = <String, Object?>{};
        var times = <String, int>{};
        for (final i in order) {
          final result = mergeFields(
            currentValues: values,
            currentTimes: times,
            incomingValues: changes[i].$1,
            incomingTimes: changes[i].$2,
          );
          values = result.values;
          times = result.times;
        }
        return values;
      }

      final expected = {'name': 'Free range eggs', 'quantity': 6};
      expect(apply([0, 1, 2]), expected);
      expect(apply([2, 1, 0]), expected);
      expect(apply([1, 2, 0]), expected);
    });
  });

  group('LocalClock', () {
    test('never hands out the same time twice', () {
      final clock = LocalClock(now: () => 1000);
      expect([clock.next(), clock.next(), clock.next()], [1000, 1001, 1002]);
    });

    test('stamps a change after a newer time it has seen from the server', () {
      // This phone's clock is 5 seconds behind.
      final clock = LocalClock(now: () => 10000);
      clock.observe(15000);
      expect(clock.next(), greaterThan(15000));
    });
  });

  group('RecordPatch.fromServerRow', () {
    test('splits off the bookkeeping columns', () {
      final patch = RecordPatch.fromServerRow('items', {
        'id': 'milk',
        'name': 'Milk',
        'checked': true,
        'field_times': {'name': 10, 'checked': 20},
        'updated_at': 20,
      });
      expect(patch.id, 'milk');
      expect(patch.values, {'name': 'Milk', 'checked': true});
      expect(patch.times, {'name': 10, 'checked': 20});
    });

    test('columns without their own time use updated_at', () {
      final patch = RecordPatch.fromServerRow('items', {
        'id': 'milk',
        'name': 'Milk',
        'field_times': '{}',
        'updated_at': 42,
      });
      expect(patch.times, {'name': 42});
    });
  });
}
