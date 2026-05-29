// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'money.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Money _$MoneyFromJson(Map<String, dynamic> json) => _Money(
  amountInCents: (json['amountInCents'] as num).toInt(),
  currency: json['currency'] as String? ?? 'INR',
);

Map<String, dynamic> _$MoneyToJson(_Money instance) => <String, dynamic>{
  'amountInCents': instance.amountInCents,
  'currency': instance.currency,
};
