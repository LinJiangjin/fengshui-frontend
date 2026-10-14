/// 合规文档（用户协议 / 隐私政策）模型。
///
/// 正文由服务端下发、客户端只负责渲染：条款更新后无需发版即可生效。
/// 结构是「节」的列表，每节含小标题与若干段落——用原生组件就能排好版，
/// 不必为它引入 Markdown 依赖。
class LegalSection {
  const LegalSection({required this.heading, required this.paragraphs});

  final String heading;
  final List<String> paragraphs;

  factory LegalSection.fromJson(Map<String, dynamic> json) {
    return LegalSection(
      heading: (json['heading'] ?? '') as String,
      paragraphs: ((json['paragraphs'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class LegalDoc {
  const LegalDoc({
    required this.slug,
    required this.title,
    required this.version,
    required this.updatedAt,
    required this.summary,
    required this.sections,
  });

  final String slug;
  final String title;

  /// 条款版本，如 2026.1
  final String version;

  /// 更新日期（YYYY-MM-DD），展示在标题下方
  final String updatedAt;

  final String summary;
  final List<LegalSection> sections;

  factory LegalDoc.fromJson(Map<String, dynamic> json) {
    return LegalDoc(
      slug: (json['slug'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      version: (json['version'] ?? '') as String,
      updatedAt: (json['updated_at'] ?? '') as String,
      summary: (json['summary'] ?? '') as String,
      sections: ((json['sections'] as List?) ?? const [])
          .map((e) => LegalSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
