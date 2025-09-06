import 'dart:convert';

class ActivityLog {
  final String id;
  final String timestamp;
  final String user;
  final String action;
  final String targetId;
  final String targetName;
  final Map<String, dynamic> details;

  ActivityLog({
    required this.id,
    required this.timestamp,
    required this.user,
    required this.action,
    required this.targetId,
    required this.targetName,
    required this.details,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    dynamic detailsData = json['details'];
    Map<String, dynamic> parsedDetails = {};

    if (detailsData is Map) {
      parsedDetails = Map<String, dynamic>.from(detailsData);
    } else if (detailsData is String && detailsData.isNotEmpty) {
      try {
        // Handle legacy data that was stored as a JSON string
        parsedDetails = jsonDecode(detailsData);
      } catch (e) {
        // If it's not a valid JSON, store it under a generic key
        parsedDetails = {'legacy_data': detailsData};
      }
    }

    return ActivityLog(
      id: json['id'],
      timestamp: json['timestamp'],
      user: json['user'],
      action: json['action'],
      targetId: json['targetId'],
      targetName: json['targetName'],
      details: parsedDetails,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'user': user,
      'action': action,
      'targetId': targetId,
      'targetName': targetName,
      'details': details, // Save directly as a map
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    // fromJson now handles both map and legacy string data
    return ActivityLog.fromJson(map);
  }
}