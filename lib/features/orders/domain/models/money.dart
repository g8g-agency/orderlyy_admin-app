// ── Money Value Object ───────────────────────────────────────────────────────
// Immutable value object for monetary amounts.
// Prevents currency mismatch errors and provides type safety.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'money.freezed.dart';
part 'money.g.dart';

@freezed
abstract class Money with _$Money implements Comparable<Money> {
  const Money._();

  const factory Money({
    required int amountInCents, // STRICTLY integer minor units
    @Default('INR') String currency,
  }) = _Money;

  factory Money.fromJson(Map<String, dynamic> json) => _$MoneyFromJson(json);

  factory Money.zero() => const Money(amountInCents: 0);

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(amountInCents: amountInCents + other.amountInCents, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(amountInCents: amountInCents - other.amountInCents, currency: currency);
  }

  Money operator *(int multiplier) {
    return Money(amountInCents: amountInCents * multiplier, currency: currency);
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return amountInCents.compareTo(other.amountInCents);
  }

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot operate on different currencies');
    }
  }

  String format() {
    return '₹${(amountInCents / 100).toStringAsFixed(2)}';
  }

  bool get isZero => amountInCents == 0;
  bool get isPositive => amountInCents > 0;
  bool get isNegative => amountInCents < 0;
}
