class BankOperationModel {
  final int id;
  final String name;
  final String account;
  final String type;
  final double originalAmount;
  final double transferredAmount;
  final DateTime date;
  final String notes;

  const BankOperationModel({
    required this.id,
    required this.name,
    required this.account,
    required this.type,
    required this.originalAmount,
    required this.transferredAmount,
    required this.date,
    this.notes = '',
  });

  double get remaining => originalAmount - transferredAmount;

  String get status {
    if (remaining <= 0) return 'مسدد';
    if (transferredAmount <= 0) return 'غير مسدد';
    return 'جزئي';
  }
}
