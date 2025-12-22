import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String category;

  @HiveField(3)
  String? note;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  TransactionType type;

  @HiveField(6)
  String? paymentMethod; // Tiền mặt, Thẻ, etc.

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  String userId; // ID của user sở hữu transaction này

  @HiveField(9)
  String? categoryId; // 🔗 liên kết với CategoryGroup

  Transaction({
    required this.id,
    required this.amount,
    required this.category,
    this.note,
    this.categoryId,
    required this.date,
    required this.type,
    this.paymentMethod,
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'type': type.toString(),
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'categoryId': categoryId,
    };
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      amount: json['amount'],
      category: json['category'],
      note: json['note'],
      date: DateTime.parse(json['date']),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      paymentMethod: json['paymentMethod'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'] ?? '', // Fallback cho data cũ
      categoryId: json['categoryId'],
    );
  }
}

@HiveType(typeId: 2)
enum TransactionType {
  @HiveField(0)
  expense, // Khoản chi

  @HiveField(1)
  income, // Khoản thu

  @HiveField(2)
  loan, // Vay/Nợ
}
