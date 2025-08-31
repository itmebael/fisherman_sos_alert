class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Required field validation
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  // Phone number validation
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces and special characters
    final cleanedValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check for Philippines mobile number format
    if (cleanedValue.length < 10 || cleanedValue.length > 13) {
      return 'Please enter a valid phone number';
    }
    
    // Check if it starts with valid Philippines mobile prefixes
    if (cleanedValue.startsWith('09') && cleanedValue.length == 11) {
      return null; // Valid Philippines mobile number
    }
    
    if (cleanedValue.startsWith('639') && cleanedValue.length == 12) {
      return null; // Valid international format
    }
    
    if (cleanedValue.startsWith('+639') && cleanedValue.length == 13) {
      return null; // Valid international format with +
    }
    
    return 'Please enter a valid Philippine phone number';
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    // Check for at least one letter and one number
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasNumber = RegExp(r'[0-9]').hasMatch(value);
    
    if (!hasLetter || !hasNumber) {
      return 'Password must contain both letters and numbers';
    }
    
    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Name validation
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    // Check for valid characters (letters, spaces, and common name characters)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-\.\']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name contains invalid characters';
    }
    
    return null;
  }

  // Boat number validation
  static String? boatNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional field
    }
    
    // Remove spaces and convert to uppercase
    final cleanedValue = value.trim().toUpperCase();
    
    // Basic boat registration number format (you can customize this)
    if (cleanedValue.length < 3) {
      return 'Boat number is too short';
    }
    
    if (cleanedValue.length > 15) {
      return 'Boat number is too long';
    }
    
    // Allow alphanumeric characters and some special characters
    final boatRegex = RegExp(r'^[A-Z0-9\-]+$');
    if (!boatRegex.hasMatch(cleanedValue)) {
      return 'Boat number contains invalid characters';
    }
    
    return null;
  }

  // ID number validation
  static String? idNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ID number is required';
    }
    
    final cleanedValue = value.trim();
    
    if (cleanedValue.length < 5) {
      return 'ID number is too short';
    }
    
    if (cleanedValue.length > 20) {
      return 'ID number is too long';
    }
    
    // Allow alphanumeric characters and dashes
    final idRegex = RegExp(r'^[A-Za-z0-9\-]+$');
    if (!idRegex.hasMatch(cleanedValue)) {
      return 'ID number contains invalid characters';
    }
    
    return null;
  }

  // Address validation
  static String? address(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    
    if (value.trim().length < 10) {
      return 'Please provide a complete address';
    }
    
    return null;
  }

  // Fishing area validation
  static String? fishingArea(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Fishing area is required';
    }
    
    if (value.trim().length < 3) {
      return 'Fishing area name is too short';
    }
    
    return null;
  }

  // Generic length validation
  static String? Function(String?) minLength(int min, String fieldName) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      
      if (value.trim().length < min) {
        return '$fieldName must be at least $min characters long';
      }
      
      return null;
    };
  }

  // Generic max length validation
  static String? Function(String?) maxLength(int max, String fieldName) {
    return (String? value) {
      if (value != null && value.trim().length > max) {
        return '$fieldName must not exceed $max characters';
      }
      
      return null;
    };
  }

  // Combined min and max length validation
  static String? Function(String?) lengthRange(int min, int max, String fieldName) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      
      final length = value.trim().length;
      
      if (length < min) {
        return '$fieldName must be at least $min characters long';
      }
      
      if (length > max) {
        return '$fieldName must not exceed $max characters';
      }
      
      return null;
    };
  }

  // Numeric validation
  static String? numeric(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value.trim()) == null) {
      return '$fieldName must be a valid number';
    }
    
    return null;
  }

  // Positive number validation
  static String? positiveNumber(String? value, String fieldName) {
    final numericResult = numeric(value, fieldName);
    if (numericResult != null) return numericResult;
    
    final number = double.parse(value!.trim());
    if (number <= 0) {
      return '$fieldName must be greater than zero';
    }
    
    return null;
  }
}