class ClassDiaryModel {
  final String id;
  final String subject;
  final String className;
  final String sectionName;
  final String date;
  final int? periodNo;
  final String topicCovered;
  final String? description;
  final String? pageFrom;
  final String? pageTo;
  final String? homeworkGiven;
  final String? remarks;
  final String createdAt;

  const ClassDiaryModel({
    required this.id,
    required this.subject,
    required this.className,
    required this.sectionName,
    required this.date,
    this.periodNo,
    required this.topicCovered,
    this.description,
    this.pageFrom,
    this.pageTo,
    this.homeworkGiven,
    this.remarks,
    required this.createdAt,
  });

  String get pageRange {
    if (pageFrom == null && pageTo == null) return '';
    if (pageFrom != null && pageTo != null) return 'pp. $pageFrom–$pageTo';
    return 'p. ${pageFrom ?? pageTo}';
  }

  factory ClassDiaryModel.fromJson(Map<String, dynamic> json) {
    return ClassDiaryModel(
      id: json['id'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      periodNo: (json['period_no'] as num?)?.toInt(),
      topicCovered: json['topic_covered'] as String? ?? '',
      description: json['description'] as String?,
      pageFrom: json['page_from'] as String?,
      pageTo: json['page_to'] as String?,
      homeworkGiven: json['homework_given'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'date': date,
        if (periodNo != null) 'period_no': periodNo,
        'topic_covered': topicCovered,
        if (description != null) 'description': description,
        if (pageFrom != null) 'page_from': pageFrom,
        if (pageTo != null) 'page_to': pageTo,
        if (homeworkGiven != null) 'homework_given': homeworkGiven,
        if (remarks != null) 'remarks': remarks,
      };
}
