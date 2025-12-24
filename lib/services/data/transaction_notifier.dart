import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import 'transaction_service.dart';

/// Global notifier to trigger automatic updates across all screens
/// when transactions are added, edited, or deleted
class TransactionNotifier with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

  /// Notify all listeners to refresh transaction data
  void notifyTransactionChanged() {
    notifyListeners();
  }

  /// Wrapper for adding transaction that notifies all screens
  Future<void> addTransactionAndNotify(Transaction transaction) async {
    await _transactionService.addTransaction(transaction);
    notifyTransactionChanged();
  }

  /// Wrapper for updating transaction that notifies all screens
  Future<void> updateTransactionAndNotify(Transaction transaction) async {
    await _transactionService.updateTransaction(transaction);
    notifyTransactionChanged();
  }

  /// Wrapper for deleting transaction that notifies all screens
  Future<void> deleteTransactionAndNotify(String transactionId) async {
    await _transactionService.deleteTransaction(transactionId);
    notifyTransactionChanged();
  }
}
