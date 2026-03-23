/// Form validation utilities for AutoWala app
class Validators {
  // Private constructor to prevent instantiation
  Validators._();

  /// Validate Indian phone number (10 digits)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your mobile number';
    }

    // Remove any whitespace or special characters
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanValue.length != 10) {
      return 'Please enter a valid 10-digit mobile number';
    }

    // Check if it starts with valid Indian mobile prefixes
    final validPrefixes = ['6', '7', '8', '9'];
    if (!validPrefixes.contains(cleanValue[0])) {
      return 'Please enter a valid Indian mobile number';
    }

    return null;
  }

  /// Validate OTP (6 digits)
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the OTP';
    }

    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanValue.length != 6) {
      return 'Please enter the complete 6-digit OTP';
    }

    return null;
  }

  /// Validate name (2-50 characters, letters and spaces only)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (trimmedValue.length > 50) {
      return 'Name cannot be more than 50 characters long';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final validNameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!validNameRegex.hasMatch(trimmedValue)) {
      return 'Please enter a valid name (letters only)';
    }

    return null;
  }

  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  /// Validate address (minimum 10 characters)
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your address';
    }

    final trimmedValue = value.trim();

    if (trimmedValue.length < 10) {
      return 'Please enter a complete address (minimum 10 characters)';
    }

    if (trimmedValue.length > 200) {
      return 'Address cannot be more than 200 characters long';
    }

    return null;
  }

  /// Validate vehicle number (Indian format)
  static String? validateVehicleNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the vehicle number';
    }

    // Remove spaces and convert to uppercase
    final cleanValue = value.replaceAll(' ', '').toUpperCase();

    // Indian vehicle number patterns:
    // Old: TN01AB1234 (state code + district code + letters + numbers)
    // New: TN01BH1234 (after 2019)
    final vehicleRegex = RegExp(
      r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,2}[0-9]{4}$',
    );

    if (!vehicleRegex.hasMatch(cleanValue)) {
      return 'Please enter a valid vehicle number (e.g., TN01AB1234)';
    }

    return null;
  }

  /// Validate pincode (6 digits)
  static String? validatePincode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the pincode';
    }

    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanValue.length != 6) {
      return 'Please enter a valid 6-digit pincode';
    }

    // Indian pincode starts from 110001 to 855126
    final pincodeInt = int.tryParse(cleanValue);
    if (pincodeInt == null || pincodeInt < 110001 || pincodeInt > 855126) {
      return 'Please enter a valid Indian pincode';
    }

    return null;
  }

  /// Validate age (18-80 years)
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }

    final ageInt = int.tryParse(value);

    if (ageInt == null) {
      return 'Please enter a valid age';
    }

    if (ageInt < 18) {
      return 'You must be at least 18 years old';
    }

    if (ageInt > 80) {
      return 'Please enter a valid age';
    }

    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength,
      [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }

    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters long';
    }

    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength,
      [String? fieldName]) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'This field'} cannot be more than $maxLength characters long';
    }

    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }

    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }

    return null;
  }

  /// Validate range (numeric)
  static String? validateRange(String? value, double min, double max,
      [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return 'Please enter ${fieldName ?? 'this field'}';
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Please enter a valid number';
    }

    if (numValue < min || numValue > max) {
      return '${fieldName ?? 'Value'} must be between $min and $max';
    }

    return null;
  }

  /// Validate dropdown selection
  static String? validateDropdownSelection(dynamic value, [String? fieldName]) {
    if (value == null) {
      return 'Please select ${fieldName ?? 'an option'}';
    }
    return null;
  }

  /// Validate coordinates (latitude/longitude)
  static String? validateCoordinates(String? value, String type) {
    if (value == null || value.isEmpty) {
      return 'Please enter $type';
    }

    final coordinate = double.tryParse(value);
    if (coordinate == null) {
      return 'Please enter a valid $type';
    }

    if (type.toLowerCase() == 'latitude') {
      if (coordinate < -90 || coordinate > 90) {
        return 'Latitude must be between -90 and 90';
      }
    } else if (type.toLowerCase() == 'longitude') {
      if (coordinate < -180 || coordinate > 180) {
        return 'Longitude must be between -180 and 180';
      }
    }

    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combineValidators(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  /// Validate Indian driving license number
  static String? validateDrivingLicense(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your driving license number';
    }

    // Remove spaces and convert to uppercase
    final cleanValue = value.replaceAll(' ', '').toUpperCase();

    // Indian DL format: TN0120230001234 (state+office+year+serial)
    final dlRegex = RegExp(r'^[A-Z]{2}[0-9]{13}$');

    if (!dlRegex.hasMatch(cleanValue)) {
      return 'Please enter a valid driving license number';
    }

    return null;
  }

  /// Validate Aadhaar number (basic format check only)
  static String? validateAadhaar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your Aadhaar number';
    }

    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanValue.length != 12) {
      return 'Please enter a valid 12-digit Aadhaar number';
    }

    return null;
  }
}
