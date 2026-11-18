import 'package:flutter_test/flutter_test.dart';
import 'package:totoitaliano/core/notifications/schedina_reminder_calculator.dart';

void main() {
  final now = DateTime(2026, 9, 21, 10, 0);
  final deadline = DateTime(2026, 9, 21, 14, 0); // fireAt atteso: 13:00

  group('SchedinaReminderCalculator.compute', () {
    test('pianifica solo le leghe con schedina incompleta', () {
      final plan = SchedinaReminderCalculator.compute(
        leagues: const [
          (leagueId: 'l1', leagueName: 'Amici del Bar', schedinaComplete: false),
          (leagueId: 'l2', leagueName: 'Ufficio Milano', schedinaComplete: true),
        ],
        matchdayId: 'md12',
        deadline: deadline,
        now: now,
      );

      expect(plan.toSchedule, hasLength(1));
      expect(plan.toSchedule.single.leagueId, 'l1');
      expect(plan.toSchedule.single.fireAt,
          deadline.subtract(SchedinaReminderCalculator.leadTime));
      expect(plan.toCancelIds, [SchedinaReminderCalculator.stableId('l2', 'md12')]);
    });

    test('non pianifica nulla se il momento del promemoria è già passato', () {
      final closeDeadline = now.add(const Duration(minutes: 10));
      final plan = SchedinaReminderCalculator.compute(
        leagues: const [
          (leagueId: 'l1', leagueName: 'Amici del Bar', schedinaComplete: false),
        ],
        matchdayId: 'md12',
        deadline: closeDeadline,
        now: now,
      );

      expect(plan.toSchedule, isEmpty);
      expect(plan.toCancelIds, [SchedinaReminderCalculator.stableId('l1', 'md12')]);
    });

    test('stableId è deterministico e sempre positivo', () {
      final a = SchedinaReminderCalculator.stableId('lg-bar', 'md12');
      final b = SchedinaReminderCalculator.stableId('lg-bar', 'md12');
      final c = SchedinaReminderCalculator.stableId('lg-uff', 'md12');

      expect(a, b);
      expect(a, isNot(c));
      expect(a, greaterThanOrEqualTo(0));
    });

    test('lista vuota di leghe produce un piano vuoto', () {
      final plan = SchedinaReminderCalculator.compute(
        leagues: const [],
        matchdayId: 'md12',
        deadline: deadline,
        now: now,
      );

      expect(plan.toSchedule, isEmpty);
      expect(plan.toCancelIds, isEmpty);
    });
  });
}
