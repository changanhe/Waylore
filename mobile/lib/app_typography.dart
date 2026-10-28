enum JournalFont {
  system('系统默认', '清晰熟悉，跟随设备字体', null),
  serif('书页宋体', '衬线笔画，适合安静阅读', 'JournalSerif'),
  wenkai('霞鹜文楷', '自然手写感，让记录更温柔', 'JournalWenKai');

  final String label, description;
  final String? family;
  const JournalFont(this.label, this.description, this.family);
  static JournalFont read(dynamic value) =>
      values.where((font) => font.name == value).firstOrNull ?? system;

  static List<String> fallback(String language) => [
    if (language == 'ja') 'Noto Sans CJK JP',
    if (language == 'zh-TW') 'Noto Sans CJK TC',
    'Noto Sans CJK SC',
    'Noto Sans CJK TC',
    'Noto Sans CJK JP',
    'Microsoft YaHei',
    'PingFang SC',
    'sans-serif',
  ];
}
