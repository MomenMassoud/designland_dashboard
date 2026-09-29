class DynamicFieldModel {
  String name;
  String type; // 'text', 'number', 'drive_link', 'dropdown'
  bool isRequired;
  List<String> options;

  DynamicFieldModel({
    required this.name,
    this.type = 'text',
    this.isRequired = true,
    List<String>? options,
  }) : options = options ?? [];

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'isRequired': isRequired,
      'options': options,
    };
  }

  factory DynamicFieldModel.fromMap(Map<String, dynamic> map) {
    return DynamicFieldModel(
      name: map['name'] ?? '',
      type: map['type'] ?? 'text',
      isRequired: map['isRequired'] ?? true,
      options: List<String>.from(map['options'] ?? []),
    );
  }
}