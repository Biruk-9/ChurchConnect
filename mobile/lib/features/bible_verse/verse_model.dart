class Verse {
  const Verse({
    this.id,
    required this.ref,
    required this.text,
    this.date,
    this.posted = false,
  });

  final String? id;
  final String ref;
  final String text;
  final DateTime? date;
  final bool posted;

  factory Verse.fromJson(Map<String, dynamic> json) {
    final dateValue = json['date'];
    DateTime? parsedDate;
    if (dateValue != null) {
      parsedDate = DateTime.tryParse(dateValue.toString());
    }
    return Verse(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      ref: json['ref']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      date: parsedDate,
      posted: json['posted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) '_id': id,
        'ref': ref,
        'text': text,
        if (date != null) 'date': date!.toIso8601String(),
        'posted': posted,
      };
}
