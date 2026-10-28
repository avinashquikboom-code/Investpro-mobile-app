enum NotificationType {
  investmentSuccess,
  returnReceived,
  withdrawalApproved,
  projectUpdate,
  newProject,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedId;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.relatedId,
  });

  String get body => description;
  DateTime get date => timestamp;
  bool get read => isRead;
  NotificationModel markRead() => copyWith(isRead: true);

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? isRead,
    String? relatedId,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId ?? this.relatedId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'relatedId': relatedId,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parsedType;
    final typeVal = json['type']?.toString().toUpperCase() ?? 'INVESTMENT';
    switch (typeVal) {
      case 'INVESTMENT':
      case 'INVESTMENTSUCCESS':
        parsedType = NotificationType.investmentSuccess;
        break;
      case 'RETURN':
      case 'RETURNRECEIVED':
        parsedType = NotificationType.returnReceived;
        break;
      case 'WITHDRAWAL':
      case 'WITHDRAWALAPPROVED':
        parsedType = NotificationType.withdrawalApproved;
        break;
      case 'PROJECT_UPDATE':
      case 'PROJECTUPDATE':
        parsedType = NotificationType.projectUpdate;
        break;
      case 'NEWPROJECT':
      default:
        parsedType = NotificationType.values.firstWhere(
          (e) => e.name.toLowerCase() == typeVal.toLowerCase(),
          orElse: () => NotificationType.newProject,
        );
        break;
    }

    String? relatedId = json['relatedId'] as String? ?? json['targetId'] as String?;
    if (relatedId == null && json['data'] is Map) {
      relatedId = (json['data'] as Map)['referenceId']?.toString() ??
          (json['data'] as Map)['id']?.toString();
    }

    final dateStr = (json['createdAt'] ?? json['timestamp']) as String?;
    final date = dateStr != null ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();

    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      type: parsedType,
      title: (json['title'] ?? 'Notification').toString(),
      description: (json['body'] ?? json['description'] ?? json['message'] ?? '').toString(),
      timestamp: date,
      isRead: json['isRead'] as bool? ?? false,
      relatedId: relatedId,
    );
  }
}
