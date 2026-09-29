import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class UserDetailController extends GetxController {
  final String userId;
  UserDetailController(this.userId);

  final RxBool isLoadingUser = true.obs;
  final RxMap<String, dynamic> userDetails = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExtraUserData();
  }

  Future<void> fetchExtraUserData() async {
    try {
      isLoadingUser.value = true;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        userDetails.value = doc.data()!;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch user details: $e');
    } finally {
      isLoadingUser.value = false;
    }
  }

  Stream<QuerySnapshot> get sessionsStream {
    return FirebaseFirestore.instance
        .collection('analytics_sessions')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }
}