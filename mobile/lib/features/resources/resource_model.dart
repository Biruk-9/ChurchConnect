class ResourceItem {
  const ResourceItem({
    this.id,
    required this.title,
    this.description,
    required this.category,
    required this.accessLevel,
    this.fileUrl,
    this.filePath,
    this.createdAt,
  });

  final String? id;
  final String title;
  final String? description;
  final String category;
  final String accessLevel;
  final String? fileUrl;
  final String? filePath;
  final DateTime? createdAt;

  factory ResourceItem.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return ResourceItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? 'pdf',
      accessLevel: json['accessLevel']?.toString() ?? 'public',
      fileUrl: json['fileUrl']?.toString(),
      filePath: json['filePath']?.toString(),
      createdAt: created != null ? DateTime.tryParse(created.toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'title': title,
        if (description != null) 'description': description,
        'category': category,
        'accessLevel': accessLevel,
        if (fileUrl != null) 'fileUrl': fileUrl,
        if (filePath != null) 'filePath': filePath,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
