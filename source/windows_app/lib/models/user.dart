class UserModel {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? phoneNumber;
  final String? schoolName;
  final String? positionTitle;
  final String role;
  final bool isActive;
  final bool mustChangePassword;

  UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.phoneNumber,
    this.schoolName,
    this.positionTitle,
    required this.role,
    required this.isActive,
    required this.mustChangePassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final fName = (json['first_name'] as String?) ?? 'مدیر';
    final lName = (json['last_name'] as String?) ?? 'ارشد';
    final full = (json['full_name'] as String?) ?? '$fName $lName';

    return UserModel(
      id: (json['id'] as int?) ?? 1,
      username: (json['username'] as String?) ?? '',
      firstName: fName,
      lastName: lName,
      fullName: full,
      phoneNumber: json['phone_number'] as String?,
      schoolName: json['school'] != null ? json['school']['name'] as String? : null,
      positionTitle: json['position'] != null ? json['position']['title'] as String? : null,
      role: (json['role'] as String?) ?? 'super_admin',
      isActive: (json['is_active'] as bool?) ?? true,
      mustChangePassword: (json['must_change_password'] as bool?) ?? false,
    );
  }
}
