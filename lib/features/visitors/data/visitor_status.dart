enum VisitorStatus {
  registered('Registered'),
  checkedIn('Checked In'),
  checkedOut('Checked Out');

  const VisitorStatus(this.apiValue);

  final String apiValue;

  String get label => apiValue;

  bool get canCheckIn => this == VisitorStatus.registered;

  bool get canCheckOut => this == VisitorStatus.checkedIn;

  bool get isComplete => this == VisitorStatus.checkedOut;

  static VisitorStatus fromApi(String? raw) {
    final normalised =
        (raw ?? '').toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '');
    return switch (normalised) {
      'checkedin' => VisitorStatus.checkedIn,
      'checkedout' => VisitorStatus.checkedOut,
      _ => VisitorStatus.registered,
    };
  }
}
