class User {
  final String id;
  final String phone;
  final String name;
  final String email;
  final String referralCode;
  final double rewardsBalance;
  final String kycStatus;
  final Map<String, dynamic>? kycDetails;

  User({
    required this.id,
    required this.phone,
    required this.name,
    required this.email,
    required this.referralCode,
    required this.rewardsBalance,
    required this.kycStatus,
    this.kycDetails,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      referralCode: json['referralCode'] ?? '',
      rewardsBalance: (json['rewardsBalance'] as num?)?.toDouble() ?? 0.0,
      kycStatus: json['kycStatus'] ?? 'None',
      kycDetails: json['kycDetails'],
    );
  }
}

class ServiceCategory {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;
  final List<Service> services;

  ServiceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
    required this.services,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    var list = json['services'] as List? ?? [];
    List<Service> serviceList = list.map((i) => Service.fromJson(i)).toList();
    return ServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      services: serviceList,
    );
  }
}

class Service {
  final String id;
  final String categoryId;
  final String name;
  final String icon;
  final List<dynamic> formFields;
  final String apiProvider;
  final String status;
  final Map<String, dynamic> cashbackSetup;

  Service({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.formFields,
    required this.apiProvider,
    required this.status,
    required this.cashbackSetup,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      formFields: json['formFields'] is List ? json['formFields'] : [],
      apiProvider: json['apiProvider'] ?? '',
      status: json['status'] ?? 'Enabled',
      cashbackSetup: json['cashbackSetup'] ?? {},
    );
  }
}

class Transaction {
  final String id;
  final String serviceName;
  final double amount;
  final String status;
  final String paymentMode;
  final double rewardsAmountUsed;
  final double gatewayAmountPaid;
  final String? operatorRefId;
  final String? receiptUrl;
  final String? errorMessage;
  final DateTime createdAt;
  final Map<String, dynamic> inputsUsed;
  final bool isRefund;
  final bool isCashback;

  Transaction({
    required this.id,
    required this.serviceName,
    required this.amount,
    required this.status,
    required this.paymentMode,
    required this.rewardsAmountUsed,
    required this.gatewayAmountPaid,
    this.operatorRefId,
    this.receiptUrl,
    this.errorMessage,
    required this.createdAt,
    required this.inputsUsed,
    this.isRefund = false,
    this.isCashback = false,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      serviceName: json['serviceName'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
      paymentMode: json['paymentMode'] ?? 'Direct',
      rewardsAmountUsed: (json['rewardsAmountUsed'] as num?)?.toDouble() ?? 0.0,
      gatewayAmountPaid: (json['gatewayAmountPaid'] as num?)?.toDouble() ?? 0.0,
      operatorRefId: json['operatorRefId'],
      receiptUrl: json['receiptUrl'],
      errorMessage: json['errorMessage'],
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      inputsUsed: json['inputsUsed'] is Map ? json['inputsUsed'] : {},
      isRefund: json['isRefund'] ?? false,
      isCashback: json['isCashback'] ?? false,
    );
  }
}

class Ticket {
  final String id;
  final String ticketNumber;
  final String subject;
  final String description;
  final String status;
  final String? assignedStaffId;
  final DateTime updatedAt;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.description,
    required this.status,
    this.assignedStaffId,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      ticketNumber: json['ticketNumber'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'Open',
      assignedStaffId: json['assignedStaffId'],
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : DateTime.now(),
    );
  }
}

class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderType;
  final String message;
  final DateTime createdAt;

  TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderType,
    required this.message,
    required this.createdAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? 'User',
      message: json['message'] ?? '',
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
    );
  }
}

class BannerModel {
  final String id;
  final String imageUrl;
  final String? linkUrl;

  BannerModel({
    required this.id,
    required this.imageUrl,
    this.linkUrl,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      linkUrl: json['linkUrl'],
    );
  }
}

class OfferModel {
  final String id;
  final String title;
  final String description;
  final String promoCode;
  final double cashbackAmount;

  OfferModel({
    required this.id,
    required this.title,
    required this.description,
    required this.promoCode,
    required this.cashbackAmount,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      promoCode: json['promoCode'] ?? '',
      cashbackAmount: (json['cashbackAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'System',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
    );
  }
}

class ScratchCardModel {
  final String id;
  final String userId;
  final double amount;
  final String status; // 'Unscratched' | 'Scratched'
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime? scratchedAt;

  ScratchCardModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.status,
    required this.title,
    required this.description,
    required this.createdAt,
    this.scratchedAt,
  });

  factory ScratchCardModel.fromJson(Map<String, dynamic> json) {
    return ScratchCardModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Unscratched',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      scratchedAt: json['scratchedAt'] != null 
        ? DateTime.parse(json['scratchedAt']) 
        : null,
    );
  }
}
