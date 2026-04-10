class KeyContactModel {
  final String name;
  final String designation;

  const KeyContactModel({
    required this.name,
    required this.designation,
  });

  bool get isEmpty => name.trim().isEmpty && designation.trim().isEmpty;
  bool get isValid => name.trim().isNotEmpty && designation.trim().isNotEmpty;

  KeyContactModel copyWith({String? name, String? designation}) =>
      KeyContactModel(
        name: name ?? this.name,
        designation: designation ?? this.designation,
      );
}
