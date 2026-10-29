import 'visitor_status.dart';

class VisitorOptions {
  const VisitorOptions._();

  static const List<String> types = ['Customer', 'Vendor', 'Other'];
  static const List<String> projects = ['Project A', 'Project B', 'Project C'];
}

class Visitor {
  const Visitor({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
    required this.status,
    required this.createdAt,
    required this.checkInTime,
    required this.checkOutTime,
    this.passUrl,
  });

  const Visitor.draft({
    required this.name,
    required this.mobile,
    required this.email,
    required this.visitorType,
    required this.project,
    required this.purpose,
    this.createdAt,
  })  : id = '',
        status = VisitorStatus.registered,
        checkInTime = null,
        checkOutTime = null,
        passUrl = null;

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String visitorType;
  final String project;
  final String purpose;
  final VisitorStatus status;
  final String? createdAt;
  final String? checkInTime;
  final String? checkOutTime;

  final String? passUrl;

  bool get isPersisted => id.isNotEmpty;

  bool get hasPass => (passUrl ?? '').isNotEmpty;

  factory Visitor.fromJson(Map<String, dynamic> json) {
    return Visitor(
      id: _asString(json['id']),
      name: _asString(json['name']),
      mobile: _asString(json['mobile']),
      email: _asNullableString(json['email']),
      visitorType: _asString(json['visitor_type'], fallback: 'Other'),
      project: _asString(json['project']),
      purpose: _asString(json['purpose']),
      status: VisitorStatus.fromApi(_asNullableString(json['status'])),
      createdAt: _asNullableString(json['created_at']),
      checkInTime: _asNullableString(json['check_in_time']),
      checkOutTime: _asNullableString(json['check_out_time']),
      passUrl: _asNullableString(json['pass_url']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name.trim(),
        'mobile': mobile.trim(),
        'email': _emptyToNull(email),
        'visitor_type': visitorType,
        'project': project,
        'purpose': purpose.trim(),
        'status': VisitorStatus.registered.apiValue,
        'created_at': createdAt,
        'check_in_time': null,
        'check_out_time': null,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name.trim(),
        'mobile': mobile.trim(),
        'email': _emptyToNull(email),
        'visitor_type': visitorType,
        'project': project,
        'purpose': purpose.trim(),
        'status': status.apiValue,
        'created_at': createdAt,
        'check_in_time': checkInTime,
        'check_out_time': checkOutTime,
      };

  Visitor copyWith({
    String? id,
    String? name,
    String? mobile,
    String? Function()? email,
    String? visitorType,
    String? project,
    String? purpose,
    VisitorStatus? status,
    String? Function()? createdAt,
    String? Function()? checkInTime,
    String? Function()? checkOutTime,
    String? Function()? passUrl,
  }) {
    return Visitor(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email == null ? this.email : email(),
      visitorType: visitorType ?? this.visitorType,
      project: project ?? this.project,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt == null ? this.createdAt : createdAt(),
      checkInTime: checkInTime == null ? this.checkInTime : checkInTime(),
      checkOutTime: checkOutTime == null ? this.checkOutTime : checkOutTime(),
      passUrl: passUrl == null ? this.passUrl : passUrl(),
    );
  }

  bool matches(String term) {
    final query = term.trim().toLowerCase();
    if (query.isEmpty) return true;
    if (name.toLowerCase().contains(query)) return true;
    final digits = query.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isNotEmpty && mobile.contains(digits);
  }

  static String _asString(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _asNullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _emptyToNull(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }

  @override
  bool operator ==(Object other) =>
      other is Visitor &&
      other.id == id &&
      other.name == name &&
      other.mobile == mobile &&
      other.email == email &&
      other.visitorType == visitorType &&
      other.project == project &&
      other.purpose == purpose &&
      other.status == status &&
      other.createdAt == createdAt &&
      other.checkInTime == checkInTime &&
      other.checkOutTime == checkOutTime &&
      other.passUrl == passUrl;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        mobile,
        email,
        visitorType,
        project,
        purpose,
        status,
        createdAt,
        checkInTime,
        checkOutTime,
        passUrl,
      );
}
