class PositionSummaryModel {
  final int id;
  final String title;

  PositionSummaryModel({required this.id, required this.title});

  factory PositionSummaryModel.fromJson(Map<String, dynamic> json) {
    return PositionSummaryModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
    );
  }
}

class InternshipBatchSummaryModel {
  final int id;
  final String name;
  InternshipBatchSummaryModel({required this.id, required this.name});
  factory InternshipBatchSummaryModel.fromJson(Map<String, dynamic> json) {
    return InternshipBatchSummaryModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class MentorSummaryModel {
  final String id;
  final String fullName;
  final String email;
  MentorSummaryModel({
    required this.id,
    required this.fullName,
    required this.email,
  });
  factory MentorSummaryModel.fromJson(Map<String, dynamic> json) {
    return MentorSummaryModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class InternModel {
  final int id;
  final String fullName;
  final PositionSummaryModel? position;
  final InternshipBatchSummaryModel? internshipBatch;
  final MentorSummaryModel? mentor;
  final String? startDate;
  final String? endDate;
  final String internStatus;
  final String? createdAt;
  final String? updatedAt;
  InternModel({
    required this.id,
    required this.fullName,
    this.position,
    this.internshipBatch,
    this.mentor,
    this.startDate,
    this.endDate,
    required this.internStatus,
    this.createdAt,
    this.updatedAt,
  });
  factory InternModel.fromJson(Map<String, dynamic> json) {
    return InternModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      fullName: json['fullName'] ?? '',
      position: json['position'] != null
          ? PositionSummaryModel.fromJson(json['position'])
          : null,
      internshipBatch: json['internshipBatch'] != null
          ? InternshipBatchSummaryModel.fromJson(json['internshipBatch'])
          : null,
      mentor: json['mentor'] != null
          ? MentorSummaryModel.fromJson(json['mentor'])
          : null,
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      internStatus: json['internStatus']?.toString() ?? 'IN_PROGRESS',
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}
