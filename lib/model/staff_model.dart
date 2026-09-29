class StaffModel {
  final String id;
  final String name;
  final String email;
  final List<String> permissions;

  const StaffModel({
    required this.id,
    required this.name,
    required this.email,
    required this.permissions,
  });

  factory StaffModel.fromFirestore(String id, Map<String, dynamic> data) {
    return StaffModel(
      id: id,
      name: data['name'] as String? ?? 'Anonymous',
      email: data['email'] as String? ?? '',
      permissions: List<String>.from(data['permissions'] ?? const []),
    );
  }
}