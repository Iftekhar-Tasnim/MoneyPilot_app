import '../models/transaction_model.dart';
  
class DraftTransaction {
  final TransactionModel model;
  final String? originalPhrase;
  
  DraftTransaction({required this.model, this.originalPhrase});
}
