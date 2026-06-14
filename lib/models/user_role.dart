enum UserRole { customer, technician, admin }

extension UserRoleLabel on UserRole {
  String get label {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.technician:
        return 'Technician';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
