import 'package:freezed_annotation/freezed_annotation.dart';

part 'complaint.freezed.dart';
part 'complaint.g.dart';

@freezed
class Complaint with _$Complaint {
  const factory Complaint({
    required String id,
    required String studentId,
    required String description,
    required String location,
    String? imageKey,
    required String status,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Complaint;

  factory Complaint.fromJson(Map<String, dynamic> json) =>
      _$ComplaintFromJson(json);
}
