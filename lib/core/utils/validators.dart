class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email wajib diisi";
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!emailRegex.hasMatch(value)) {
      return "Format email tidak valid";
    }

    return null;
  }

  static String? validatePassword(
      String? value) {
    if (value == null || value.length < 6) {
      return "Password minimal 6 karakter";
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "Nama wajib diisi";
    }

    return null;
  }
}
