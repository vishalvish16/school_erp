class HomeworkModel {
  final String id;
  final String subject;
  final String className;
  final String sectionName;
  final String title;
  final String? description;
  final String assignedDate;
  final String dueDate;
  final List<String> attachmentUrls;
  final String status;
  final String createdAt;

  const HomeworkModel({
    required this.id,
    required this.subject,
    required this.className,
    required this.sectionName,
    required this.title,
    this.description,
    required this.assignedDate,
    required this.dueDate,
    this.attachmentUrls = const [],
    this.status = 'ACTIVE',
    required this.createdAt,
  });

  bool get isOverdue {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return false;
    return DateTime.now().isAfter(due) && status == 'ACTIVE';
  }

  int get daysRemaining {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return 0;
    return due.difference(DateTime.now()).inDays;
  }

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    final urlsRaw = json['attachment_urls'];
    final urls = urlsRaw is List
        ? urlsRaw.map((e) => e.toString()).toList()
        : <String>[];

    return HomeworkModel(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      assignedDate: json['assigned_date'] as String? ?? '',
      dueDate: json['due_date'] as String? ?? '',
      attachmentUrls: urls,
      status: json['status'] as String? ?? 'ACTIVE',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'title': title,
        if (description != null) 'description': description,
        'due_date': dueDate,
        'attachment_urls': attachmentUrls,
      };
}
