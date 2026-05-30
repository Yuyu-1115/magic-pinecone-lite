import 'package:magic_pinecone_course_demo/features/settings/models/settings_models.dart';

abstract class SettingsRepository {
  SettingsSnapshot loadSettings();
}

class StaticSettingsRepository implements SettingsRepository {
  const StaticSettingsRepository();

  @override
  SettingsSnapshot loadSettings() {
    return const SettingsSnapshot(
      appName: '神奇松果 Lite',
      appVersion: '0.2.0',
      summary:
          '神奇松果是由學生社群 Google Developers on Campus NCU 正在開發中的軟體。期望能夠將零碎的校務資訊、分散的系統功能整合起來，為中大學生提供一個一站式的服務。目前的試行版本（Lite）提供以下功能：',
      statusItems: [
        SettingsStatusItem(label: '定期同步最新課程資訊'),
        SettingsStatusItem(label: '在本機儲存選課資訊，並支援與他人分享'),
        SettingsStatusItem(label: '基本的RWD，手機電腦皆適用'),
      ],
    );
  }
}
