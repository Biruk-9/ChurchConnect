class Announcement {
  const Announcement({
    this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.createdAt,
  });

  final String? id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime? createdAt;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return Announcement(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? json['body']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      createdAt: created != null ? DateTime.tryParse(created.toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'title': title,
        'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
