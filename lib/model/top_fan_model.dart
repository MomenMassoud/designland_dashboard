class TopFanModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final int completedOrdersCount;
  final double totalSpent;

  TopFanModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.completedOrdersCount,
    required this.totalSpent,
  });

  factory TopFanModel.fromFirestoreMap(
      Map<String, dynamic> data,
      String id,
      int completedOrdersCount,
      double totalSpent, {
        String phoneFromOrder = '',
      }) {
    return TopFanModel(
      uid: data['uid'] ?? id,
      name: data['name'] ?? data['Name'] ?? 'No Name',
      email: data['email'] ?? '',
      phone: (data['phone'] != null && data['phone'].toString().isNotEmpty)
          ? data['phone']
          : phoneFromOrder,
      profileImage: data['image'] ?? data['photoUrl'],
      completedOrdersCount: completedOrdersCount,
      totalSpent: totalSpent,
    );
  }
}