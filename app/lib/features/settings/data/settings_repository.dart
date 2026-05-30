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
      appVersion: '0.1.0+1',
      summary:
          '這個 demo 只保留課程查詢與課表規劃，透過 GitHub Pages 提供前端，並直接讀取 magic-pinecone-lite 的靜態課程 JSON。',
      statusItems: [
        SettingsStatusItem(label: '課程資料由 GitHub CDN 上的靜態 JSON 載入'),
        SettingsStatusItem(label: '課程查詢、進階篩選與課表預覽已獨立成 Lite 版本'),
        SettingsStatusItem(label: '課表分享與本機儲存使用瀏覽器能力完成'),
      ],
    );
  }
}
