class VisitorQr {
  const VisitorQr._();

  static const String prefix = 'VMS:';

  static String encode(String visitorId) => '$prefix$visitorId';

  static String? decode(String? raw) {
    final value = raw?.trim() ?? '';
    if (!value.startsWith(prefix)) return null;
    final id = value.substring(prefix.length).trim();
    return id.isEmpty ? null : id;
  }
}
