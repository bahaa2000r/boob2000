class ItemModel {
  final int id;
  final String name;
  final double quantity;
  final double purchasePrice;
  final double wholesalePrice;
  final double retailPrice;
  final String storagePlace;
  final String supplier;

  const ItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.purchasePrice,
    required this.wholesalePrice,
    required this.retailPrice,
    this.storagePlace = '',
    this.supplier = '',
  });
}
