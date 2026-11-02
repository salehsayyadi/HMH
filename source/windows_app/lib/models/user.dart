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
    return UserModel(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'] ?? '${json['first_name']} ${json['last_name']}',
      phoneNumber: json['phone_number'],
      schoolName: json['school'] != null ? json['school']['name'] : null,
      positionTitle: json['position'] != null ? json['position']['title'] : null,
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? true,
      mustChangePassword: json['must_change_password'] ?? false,
    );
  }
}
