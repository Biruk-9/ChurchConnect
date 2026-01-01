class EventItem {
  const EventItem({
    this.id,
    required this.title,
    this.description,
    required this.date,
    required this.time,
    this.location,
    this.createdAt,
  });

  final String? id;
  final String title;
  final String? description;
  final DateTime date;
  final String time;
  final String? location;
  final DateTime? createdAt;

  factory EventItem.fromJson(Map<String, dynamic> json) {
    final dateValue = json['date'] ?? json['startDate'];
    final parsedDate = dateValue != null ? DateTime.tryParse(dateValue.toString()) : null;
    final created = json['createdAt'];
    return EventItem(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      date: parsedDate ?? DateTime.now(),
      time: json['time']?.toString() ?? '',
      location: json['location']?.toString(),
      createdAt: created != null ? DateTime.tryParse(created.toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'title': title,
        if (description != null) 'description': description,
        'date': date.toIso8601String(),
        'time': time,
        if (location != null) 'location': location,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
