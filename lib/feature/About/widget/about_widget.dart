import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/server/get_permision.dart';
import 'package:dashboard_desginland/feature/Access%20Defind/view/access_defind_view.dart';
import 'package:flutter/material.dart';

class AboutWidget extends StatefulWidget {
  const AboutWidget({Key? key}) : super(key: key);

  @override
  State<AboutWidget> createState() => _AboutWidgetState();
}

class _AboutWidgetState extends State<AboutWidget> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;

  // controllers - About Us & Contact
  final _aboutController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();

  bool _isLoadingInfo = true;
  bool _isSavingInfo = false;

  @override
  void initState() {
    super.initState();
    Start();
    _tabController = TabController(length: 2, vsync: this);
    _loadAppInfo();
  }
  List<String>_permision=[];

  void Start()async{
    _permision=await GetPermisionUser();
    setState(() {
      _permision;
    });
  }

  // تحميل البيانات الحالية لـ About Us و Contact
  Future<void> _loadAppInfo() async {
    try {
      final aboutDoc = await _db.collection('app_info').doc('about_us').get();
      final contactDoc = await _db.collection('app_info').doc('contact').get();

      if (aboutDoc.exists) {
        _aboutController.text = aboutDoc.data()?['description'] ?? '';
      }

      if (contactDoc.exists) {
        final data = contactDoc.data();
        _emailController.text = data?['email'] ?? '';
        _phoneController.text = data?['phone'] ?? '';
        _whatsappController.text = data?['whatsapp'] ?? '';
      }
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء تحميل البيانات: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingInfo = false);
      }
    }
  }

  // حفظ المعلومات الأساسية والتواصل
  Future<void> _saveAppInfo() async {
    setState(() => _isSavingInfo = true);
    try {
      await _db.collection('app_info').doc('about_us').set({
        'description': _aboutController.text.trim(),
      }, SetOptions(merge: true));

      await _db.collection('app_info').doc('contact').set({
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
      }, SetOptions(merge: true));

      _showSnackBar('تم حفظ البيانات بنجاح!');
    } catch (e) {
      _showSnackBar('حدث خطأ أثناء الحفظ: $e');
    } finally {
      if (mounted) {
        setState(() => _isSavingInfo = false);
      }
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return _permision.contains("about")?  Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('إدارة "من نحن" والأسئلة الشائعة'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'المعلومات الأساسية'),
            Tab(icon: Icon(Icons.quiz_outlined), text: 'الأسئلة الشائعة (FAQ)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildFaqTab(),
        ],
      ),
    ):AccessDefindView();
  }

  // --- 1. تبويب المعلومات الأساسية والتواصل ---
  Widget _buildInfoTab() {
    if (_isLoadingInfo) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // كارت من نحن
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نبذة "عن التطبيق / من نحن"',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _aboutController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'اكتب الوصف الذي يظهر للمستخدم هنا...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // كارت معلومات التواصل
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'بيانات التواصل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _whatsappController,
                  decoration: InputDecoration(
                    labelText: 'رقم الواتساب',
                    prefixIcon: const Icon(Icons.wechat, color: Color(0xFF25D366)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'رقم الاتصال',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // زر الحفظ
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSavingInfo ? null : _saveAppInfo,
              icon: _isSavingInfo
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.save),
              label: const Text('حفظ التعديلات', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. تبويب الأسئلة الشائعة (FAQS) ---
  Widget _buildFaqTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFaqDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة سؤال جديد'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('faqs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('لا توجد أسئلة شائعة مضافة بعد.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final question = data['question'] ?? '';
              final answer = data['answer'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                    )
                  ],
                ),
                child: ListTile(
                  title: Text(
                    question,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(answer),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showFaqDialog(
                          docId: doc.id,
                          currentQuestion: question,
                          currentAnswer: answer,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteFaq(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // نافذة إضافة/تعديل سؤال شائع
  void _showFaqDialog({
    String? docId,
    String? currentQuestion,
    String? currentAnswer,
  }) {
    final isEdit = docId != null;
    final qController = TextEditingController(text: currentQuestion ?? '');
    final aController = TextEditingController(text: currentAnswer ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'تعديل السؤال الشائع' : 'إضافة سؤال شائع جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qController,
                decoration: const InputDecoration(
                  labelText: 'السؤال',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'الإجابة',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (qController.text.trim().isEmpty || aController.text.trim().isEmpty) {
                  return;
                }

                final data = {
                  'question': qController.text.trim(),
                  'answer': aController.text.trim(),
                };

                if (isEdit) {
                  await _db.collection('faqs').doc(docId).update(data);
                } else {
                  await _db.collection('faqs').add(data);
                }

                if (mounted) Navigator.pop(context);
              },
              child: Text(isEdit ? 'تعديل' : 'إضافة'),
            ),
          ],
        );
      },
    );
  }

  // حذف سؤال شائع
  Future<void> _deleteFaq(String docId) async {
    await _db.collection('faqs').doc(docId).delete();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aboutController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }
}