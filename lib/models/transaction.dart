/// Represents a financial transaction (income or expense) related to a crop planting.
/// Pure Dart model without framework dependencies.
class Transaction {
  final String id;
  final String plantingId;
  final String fieldId;
  final String kind; // 'expense' or 'income'
  final String category; // 'seed', 'labour', 'fertilizer', 'pesticide', 'irrigation', 'machinery', 'transport', 'sale', 'other'
  final double amount;
  final DateTime date;
  final String note;

  const Transaction({
    required this.id,
    required this.plantingId,
    required this.fieldId,
    required this.kind,
    required this.category,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory Transaction.fromJson(Map<String, dynamic> json, [String? id]) {
    return Transaction(
      id: id ?? json['id'] as String? ?? '',
      plantingId: json['plantingId'] as String? ?? '',
      fieldId: json['fieldId'] as String? ?? '',
      kind: json['kind'] as String? ?? 'expense',
      category: json['category'] as String? ?? 'other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'plantingId': plantingId,
      'fieldId': fieldId,
      'kind': kind,
      'category': category,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  Transaction copyWith({
    String? id,
    String? plantingId,
    String? fieldId,
    String? kind,
    String? category,
    double? amount,
    DateTime? date,
    String? note,
  }) {
    return Transaction(
      id: id ?? this.id,
      plantingId: plantingId ?? this.plantingId,
      fieldId: fieldId ?? this.fieldId,
      kind: kind ?? this.kind,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          plantingId == other.plantingId &&
          amount == other.amount &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(id, plantingId, amount, kind);
}
