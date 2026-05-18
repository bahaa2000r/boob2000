import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/mobile_sync_service.dart';
import '../widgets/action_bar.dart';
import '../widgets/section_box.dart';

class SyncCenterScreen extends StatefulWidget {
  const SyncCenterScreen({super.key});

  @override
  State<SyncCenterScreen> createState() => _SyncCenterScreenState();
}

class _SyncCenterScreenState extends State<SyncCenterScreen> {
  String deviceId = '';
  String lastMessage = 'جاهز للمزامنة';
  bool loading = false;
  Map<String, int> stats = const {'total': 0, 'imports': 0, 'conflicts': 0};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = await MobileSyncService.deviceId();
    final st = await MobileSyncService.stats();
    if (mounted) setState(() { deviceId = id; stats = st; });
  }

  Future<void> _export(String kind) async {
    setState(() => loading = true);
    try {
      final path = await MobileSyncService.exportPackage(kind: kind);
      final st = await MobileSyncService.stats();
      setState(() {
        stats = st;
        lastMessage = 'تم تصدير ملف المزامنة:\n$path\n\nانقل هذا الملف إلى نسخة الحاسوب أو أرسله عبر تلجرام/واتساب.';
      });
    } catch (e) {
      setState(() => lastMessage = 'خطأ أثناء التصدير: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _import() async {
    setState(() => loading = true);
    try {
      final result = await MobileSyncService.importPackage();
      final st = await MobileSyncService.stats();
      setState(() {
        stats = st;
        lastMessage = '${result.message}\nمدمج: ${result.imported}\nمتجاوز: ${result.skipped}\nتعارضات: ${result.conflicts}';
      });
    } catch (e) {
      setState(() => lastMessage = 'خطأ أثناء الاستقبال: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionBox(
            title: 'مركز المزامنة الفعلي',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Device ID: $deviceId', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Text('إجمالي السجلات المحلية: ${stats['total']} | ملفات مستقبلة: ${stats['imports']} | تعارضات: ${stats['conflicts']}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ActionBar(children: [
                  FilledButton.icon(
                    onPressed: loading ? null : () => _export('full'),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('تصدير نسخة كاملة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: loading ? null : () => _export('pending'),
                    icon: const Icon(Icons.sync),
                    label: const Text('تصدير تغييرات لاحقة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: loading ? null : _import,
                    icon: const Icon(Icons.download),
                    label: const Text('استقبال ملف مزامنة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: loading ? null : _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث الحالة'),
                  ),
                ]),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Text(lastMessage, textAlign: TextAlign.center),
                ),
              ],
            ),
          ),
          const SectionBox(
            title: 'طريقة الاستخدام',
            child: Text(
              'أول مرة: صدّر نسخة كاملة من الحاسوب ثم استقبلها هنا.\n'
              'بعد ذلك: صدّر تغييرات لاحقة من أي جهاز واستقبلها في الجهاز الآخر.\n'
              'يتم الحفظ الآن داخل SQLite في الهاتف، ويتم منع تكرار الحزم برقم Package ID.\n'
              'يمكن نقل الملف عبر USB أو تلجرام أو واتساب أو أي طريقة مشاركة ملفات.',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
