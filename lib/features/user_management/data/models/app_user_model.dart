class AppUserModel {
  final String id;
  final String employeeCode;
  final String fullName;
  final String email;
  final String role;
  final String status;
  final String? factoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUserModel({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.factoryId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'EMPLOYEE',
      status: json['status']?.toString() ?? 'ACTIVE',
      factoryId: json['factoryId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeCode': employeeCode,
      'fullName': fullName,
      'email': email,
      'role': role,
      'status': status,
      if (factoryId != null) 'factoryId': factoryId,
    };
  }

  AppUserModel copyWith({
    String? id,
    String? employeeCode,
    String? fullName,
    String? email,
    String? role,
    String? status,
    String? factoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUserModel(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      factoryId: factoryId ?? this.factoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
