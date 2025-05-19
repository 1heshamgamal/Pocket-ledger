import 'package:sqflite/sqflite.dart';

enum TransactionType {
  expense,
  debtYouOwe,
  debtOwedToYou,
}

class Transaction {
  final int? id;
  final TransactionType type;
  final double amount;
  final String description;
  final DateTime date;
  final bool isPaid; // Only relevant for debt transactions

  Transaction({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.isPaid = false,
  });

  // Convert a Transaction into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
    };
  }

  // Create a Transaction from a Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: TransactionType.values[map['type']],
      amount: map['amount'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      isPaid: map['isPaid'] == 1,
    );
  }

  // Create a copy of this Transaction with the given field values changed
  Transaction copyWith({
    int? id,
    TransactionType? type,
    double? amount,
    String? description,
    DateTime? date,
    bool? isPaid,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}