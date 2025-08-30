// FILE: lib/src/models/activity_log_model.dart
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
    return ActivityLog(
      id: json['id'],
      timestamp: json['timestamp'],
      user: json['user'],
      action: json['action'],
      targetId: json['targetId'],
      targetName: json['targetName'],
      details: json['details'] is Map
          ? Map<String, dynamic>.from(json['details'])
          : {},
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
      'details': jsonEncode(details),
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'],
      timestamp: map['timestamp'],
      user: map['user'],
      action: map['action'],
      targetId: map['targetId'],
      targetName: map['targetName'],
      details: jsonDecode(map['details']),
    );
  }
}