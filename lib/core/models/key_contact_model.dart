class KeyContactModel {
  final String name;
  final String designation;
  final String mobile; // +91 XXXXX XXXXX
  final String email;

  const KeyContactModel({
    required this.name,
    required this.designation,
    this.mobile = '',
    this.email = '',
  });

  bool get isEmpty =>
      name.trim().isEmpty &&
      designation.trim().isEmpty &&
      mobile.trim().isEmpty &&
      email.trim().isEmpty;

  bool get isValid =>
      name.trim().isNotEmpty &&
      designation.trim().isNotEmpty &&
      _isValidMobile &&
      _isValidEmail;

  /// Validates +91 followed by 10 digits (spaces/dashes allowed in between).
  bool get _isValidMobile {
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 10 || digits.length == 12; // 10 w/o country code or 12 with 91
  }

  bool get _isValidEmail =>
      RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
          .hasMatch(email.trim());

  KeyContactModel copyWith({
    String? name,
    String? designation,
    String? mobile,
    String? email,
  }) =>
      KeyContactModel(
        name: name ?? this.name,
        designation: designation ?? this.designation,
        mobile: mobile ?? this.mobile,
        email: email ?? this.email,
      );
}
