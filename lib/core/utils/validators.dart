class Validators {
  const Validators._();

  static final RegExp _tenDigits = RegExp(r'^\d{10}$');
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? requiredField(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? requiredChoice(Object? value, {String label = 'an option'}) {
    if (value == null) return 'Please select $label';
    return null;
  }

  static String? mobile(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Mobile number is required';
    if (!_tenDigits.hasMatch(input)) return 'Enter exactly 10 digits';
    return null;
  }

  static String? optionalEmail(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    if (!_email.hasMatch(input)) return 'Enter a valid email address';
    return null;
  }
}
