enum NotificationType {
  investorWelcome,
  requestUpdate,
  investmentSuccess,
  returnReceived,
  withdrawalApproved,
  projectUpdate,
  newProject,
  kyc,
  subscriptionActivated,
  subscriptionExpiring,
  subscriptionExpired,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedId;
  final String? targetType;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.relatedId,
    this.targetType,
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
      targetType: targetType,
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
      'targetType': targetType,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationType parsedType;
    final typeVal = json['type']?.toString().toUpperCase() ?? 'INVESTMENT';
    final targetType = json['targetType']?.toString().toUpperCase() ?? '';
    final title = (json['title'] ?? '').toString().toUpperCase();

    final metadata = json['data'] is Map ? json['data'] as Map : const {};
    final event = (metadata['event'] ?? metadata['type'] ?? '')
        .toString()
        .toUpperCase();
    if (targetType == 'REQUEST' || typeVal == 'REQUESTUPDATE' || typeVal == 'REQUEST_UPDATED') {
      parsedType=NotificationType.requestUpdate;
    } else if (typeVal == 'INVESTOR_WELCOME' ||
        typeVal == 'INVESTORWELCOME' ||
        event == 'INVESTOR_WELCOME' ||
        targetType == 'INVESTOR_WELCOME') {
      parsedType = NotificationType.investorWelcome;
    } else if (typeVal.contains('KYC') ||
        targetType == 'KYC' ||
        title.contains('KYC')) {
      parsedType = NotificationType.kyc;
    } else if (typeVal == 'SUBSCRIPTION_ACTIVATED' ||
        (targetType == 'SUBSCRIPTION' && (typeVal.contains('ACTIVAT') || title.contains('ACTIVAT') || event.contains('ACTIVAT')))) {
      parsedType = NotificationType.subscriptionActivated;
    } else if (typeVal == 'SUBSCRIPTION_EXPIRING' ||
        (targetType == 'SUBSCRIPTION' && (typeVal.contains('EXPIRING') || title.contains('EXPIRING') || event.contains('EXPIRING')))) {
      parsedType = NotificationType.subscriptionExpiring;
    } else if (typeVal == 'SUBSCRIPTION_EXPIRED' ||
        (targetType == 'SUBSCRIPTION' && (typeVal.contains('EXPIRED') || title.contains('EXPIRED') || event.contains('EXPIRED')))) {
      parsedType = NotificationType.subscriptionExpired;
    } else if (targetType == 'SUBSCRIPTION' || typeVal.contains('SUBSCRIPTION')) {
      parsedType = NotificationType.subscriptionActivated;
    } else {
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
    }

    String? relatedId =
        json['relatedId'] as String? ?? json['targetId'] as String?;
    if (relatedId == null && json['data'] is Map) {
      relatedId =
          (json['data'] as Map)['referenceId']?.toString() ??
          (json['data'] as Map)['id']?.toString();
    }

    final dateStr = (json['createdAt'] ?? json['timestamp']) as String?;
    final date = dateStr != null
        ? (DateTime.tryParse(dateStr) ?? DateTime.now())
        : DateTime.now();

    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      type: parsedType,
      title: (json['title'] ?? 'Notification').toString(),
      description:
          (json['body'] ?? json['description'] ?? json['message'] ?? '')
              .toString(),
      timestamp: date,
      isRead: json['isRead'] as bool? ?? false,
      relatedId: relatedId,
      targetType: json['targetType']?.toString(),
    );
  }
}
