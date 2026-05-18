class PersonModel {
  final int id;
  final String name;
  final String phone;
  final String notes;

  const PersonModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.notes = '',
  });
}
