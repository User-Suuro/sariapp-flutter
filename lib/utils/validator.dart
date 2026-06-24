typedef Validator = String? Function(String? value);

class Validators {
  static Validator required(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }

      return null;
    };
  }

  static Validator minLength(int length) {
    return (value) {
      // allow empty values
      if (value == null || value.trim().isEmpty) {
        return null;
      }

      if (value.length < length) {
        return 'Minimum length is $length';
      }

      return null;
    };
  }

  static Validator integer() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }

      if (int.tryParse(value) == null) {
        return 'Must be a valid integer';
      }

      return null;
    };
  }

  static Validator nonNegativeInteger() {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return null;
      }

      final number = int.tryParse(value);

      if (number == null) {
        return 'Must be a valid integer';
      }

      if (number < 0) {
        return 'Value cannot be negative';
      }

      return null;
    };
  }

  static Validator compose(List<Validator> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);

        if (result != null) {
          return result;
        }
      }

      return null;
    };
  }
}
