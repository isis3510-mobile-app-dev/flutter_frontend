class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.header,
    required this.text,
    this.actionLabel = '',
    this.actionPhone = '',
    this.actionWhatsapp = '',
    this.actionReportId = '',
    this.actionPetId = '',
    this.actionPetName = '',
    this.actionPetPhotoUrl = '',
    this.actionReporterName = '',
    this.actionLocation = '',
    this.actionLatitude,
    this.actionLongitude,
    this.dateSent,
    this.isRead = false,
  });

  final String id;
  final String type;
  final String header;
  final String text;
  final String actionLabel;
  final String actionPhone;
  final String actionWhatsapp;
  final String actionReportId;
  final String actionPetId;
  final String actionPetName;
  final String actionPetPhotoUrl;
  final String actionReporterName;
  final String actionLocation;
  final double? actionLatitude;
  final double? actionLongitude;
  final DateTime? dateSent;
  final bool isRead;

  bool get hasCallAction => actionPhone.trim().isNotEmpty;
  bool get hasWhatsAppAction => actionWhatsapp.trim().isNotEmpty;
  bool get hasLostPetReport => actionReportId.trim().isNotEmpty;
  bool get hasActionLocation =>
      actionLatitude != null && actionLongitude != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _readString(json['id'] ?? json['_id']),
      type: _readString(json['type']),
      header: _readString(json['header']),
      text: _readString(json['text']),
      actionLabel: _readString(json['actionLabel'] ?? json['action_label']),
      actionPhone: _readString(json['actionPhone'] ?? json['action_phone']),
      actionWhatsapp: _readString(
        json['actionWhatsapp'] ?? json['action_whatsapp'],
      ),
      actionReportId: _readString(
        json['actionReportId'] ?? json['action_report_id'],
      ),
      actionPetId: _readString(json['actionPetId'] ?? json['action_pet_id']),
      actionPetName: _readString(
        json['actionPetName'] ?? json['action_pet_name'],
      ),
      actionPetPhotoUrl: _readString(
        json['actionPetPhotoUrl'] ?? json['action_pet_photo_url'],
      ),
      actionReporterName: _readString(
        json['actionReporterName'] ?? json['action_reporter_name'],
      ),
      actionLocation: _readString(
        json['actionLocation'] ?? json['action_location'],
      ),
      actionLatitude: _readDouble(
        json['actionLatitude'] ?? json['action_latitude'],
      ),
      actionLongitude: _readDouble(
        json['actionLongitude'] ?? json['action_longitude'],
      ),
      dateSent: DateTime.tryParse(_readString(json['dateSent'])),
      isRead: json['isRead'] == true || json['is_read'] == true,
    );
  }
}

double? _readDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

String _readString(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}
