import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_strings.dart';
import 'app_form_constraints.dart';

class AppFormSanitizers {
  const AppFormSanitizers._();

  static void trimControllers(Iterable<TextEditingController> controllers) {
    for (final controller in controllers) {
      final trimmed = controller.text.trim();
      if (controller.text == trimmed) {
        continue;
      }

      controller.value = controller.value.copyWith(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
        composing: TextRange.empty,
      );
    }
  }
}

class AppInputFormatters {
  const AppInputFormatters._();

  static final RegExp _emailCharsRegex = RegExp(
    r"[A-Za-z0-9.!#$%&'*+/=?^_`{|}~@-]",
  );
  static final RegExp _asciiPrintableRegex = RegExp(r'[\x20-\x7E]');
  static final RegExp _singleLineSafeTextRegex = RegExp(
    r'[A-Za-zÀ-ÖØ-öø-ÿ0-9 .,;:()!?@#%&*+\-_/\\[\]{}]',
  );
  static final RegExp _multiLineSafeTextRegex = RegExp(
    r'[A-Za-zÀ-ÖØ-öø-ÿ0-9 .,;:()!?@#%&*+\-_/\\[\]{}\n\r]',
  );
  static final RegExp _phoneCharsRegex = RegExp(r'[0-9+()\-\s]');

  static List<TextInputFormatter> email() => <TextInputFormatter>[
    LengthLimitingTextInputFormatter(AppFormConstraints.emailMaxLength),
    FilteringTextInputFormatter.allow(_emailCharsRegex),
  ];

  static List<TextInputFormatter> password() => <TextInputFormatter>[
    LengthLimitingTextInputFormatter(AppFormConstraints.passwordMaxLength),
    FilteringTextInputFormatter.allow(_asciiPrintableRegex),
  ];

  static List<TextInputFormatter> phone() => <TextInputFormatter>[
    LengthLimitingTextInputFormatter(AppFormConstraints.phoneMaxLength),
    FilteringTextInputFormatter.allow(_phoneCharsRegex),
  ];

  static List<TextInputFormatter> safeSingleLineText(int maxLength) =>
      <TextInputFormatter>[
        LengthLimitingTextInputFormatter(maxLength),
        FilteringTextInputFormatter.allow(_singleLineSafeTextRegex),
      ];

  static List<TextInputFormatter> safeMultilineText(int maxLength) =>
      <TextInputFormatter>[
        LengthLimitingTextInputFormatter(maxLength),
        FilteringTextInputFormatter.allow(_multiLineSafeTextRegex),
      ];

  static List<TextInputFormatter> decimal({
    required int maxWholeDigits,
    required int decimalDigits,
  }) => <TextInputFormatter>[
    TextInputFormatter.withFunction((oldValue, newValue) {
      final text = newValue.text;
      if (text.isEmpty) {
        return newValue;
      }

      final normalized = text.replaceAll(',', '.');
      final decimalPattern = decimalDigits > 0
          ? RegExp('^\\d{0,$maxWholeDigits}(?:\\.\\d{0,$decimalDigits})?\$')
          : RegExp('^\\d{0,$maxWholeDigits}\$');

      if (!decimalPattern.hasMatch(normalized)) {
        return oldValue;
      }

      if (text == normalized) {
        return newValue;
      }

      return newValue.copyWith(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }),
  ];
}

typedef AppStringValidator = String? Function(String? value);

class AppFormValidators {
  const AppFormValidators._();
  static const int defaultMinTextLength = 3;

  static final RegExp _emailRegex = RegExp(
    r"^(?=.{1,254}$)(?=.{1,64}@)[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[A-Za-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}$",
  );
  static final RegExp _asciiPrintableRegex = RegExp(r'^[\x20-\x7E]+$');
  static final RegExp _singleLineSafeTextRegex = RegExp(
    r'^[A-Za-zÀ-ÖØ-öø-ÿ0-9 .,;:()!?@#%&*+\-_/\\[\]{}]+$',
  );
  static final RegExp _multiLineSafeTextRegex = RegExp(
    r'^[A-Za-zÀ-ÖØ-öø-ÿ0-9 .,;:()!?@#%&*+\-_/\\[\]{}\n\r]+$',
  );
  static final RegExp _phoneRegex = RegExp(r'^[0-9+()\-\s]+$');

  static AppStringValidator combine(List<AppStringValidator> validators) {
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

  static AppStringValidator required(String message) {
    return (value) {
      if ((value?.trim() ?? '').isEmpty) {
        return message;
      }
      return null;
    };
  }

  static AppStringValidator maxCharacters({
    required String fieldLabel,
    required int maxLength,
    int minLength = defaultMinTextLength,
  }) {
    return (value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) {
        return null;
      }
      if (trimmed.length < minLength) {
        return AppStrings.validationFieldTooShort(fieldLabel, minLength);
      }
      if (trimmed.length <= maxLength) {
        return null;
      }
      return AppStrings.validationFieldTooLong(fieldLabel, maxLength);
    };
  }

  static AppStringValidator safeSingleLineText({
    required String fieldLabel,
    required int maxLength,
    int minLength = defaultMinTextLength,
  }) {
    return combine(<AppStringValidator>[
      maxCharacters(
        fieldLabel: fieldLabel,
        maxLength: maxLength,
        minLength: minLength,
      ),
      (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty || _singleLineSafeTextRegex.hasMatch(trimmed)) {
          return null;
        }
        return AppStrings.validationFieldContainsUnsupportedCharacters(
          fieldLabel,
        );
      },
    ]);
  }

  static AppStringValidator safeMultilineText({
    required String fieldLabel,
    required int maxLength,
    int minLength = defaultMinTextLength,
  }) {
    return combine(<AppStringValidator>[
      maxCharacters(
        fieldLabel: fieldLabel,
        maxLength: maxLength,
        minLength: minLength,
      ),
      (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty || _multiLineSafeTextRegex.hasMatch(trimmed)) {
          return null;
        }
        return AppStrings.validationFieldContainsUnsupportedCharacters(
          fieldLabel,
        );
      },
    ]);
  }

  static AppStringValidator email({
    required String requiredMessage,
    required String invalidMessage,
  }) {
    return combine(<AppStringValidator>[
      required(requiredMessage),
      maxCharacters(
        fieldLabel: AppStrings.authEmailAddress,
        maxLength: AppFormConstraints.emailMaxLength,
      ),
      (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return null;
        }
        if (!_emailRegex.hasMatch(trimmed)) {
          return invalidMessage;
        }
        return null;
      },
    ]);
  }

  static AppStringValidator password({
    required String requiredMessage,
    String? tooShortMessage,
    required String invalidCharactersMessage,
    int minLength = 8,
  }) {
    return (value) {
      final raw = value ?? '';
      if (raw.trim().isEmpty) {
        return requiredMessage;
      }
      if (minLength > 0 && raw.length < minLength) {
        return tooShortMessage;
      }
      if (raw.length > AppFormConstraints.passwordMaxLength) {
        return AppStrings.validationFieldTooLong(
          AppStrings.authPassword,
          AppFormConstraints.passwordMaxLength,
        );
      }
      if (!_asciiPrintableRegex.hasMatch(raw)) {
        return invalidCharactersMessage;
      }
      return null;
    };
  }

  static AppStringValidator phone({
    required int maxLength,
    required String invalidMessage,
  }) {
    return combine(<AppStringValidator>[
      maxCharacters(fieldLabel: AppStrings.profilePhone, maxLength: maxLength),
      (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty || _phoneRegex.hasMatch(trimmed)) {
          return null;
        }
        return invalidMessage;
      },
    ]);
  }

  static AppStringValidator optionalDecimal({
    required String invalidMessage,
    String? maxMessage,
    double? maxValue,
  }) {
    return (value) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isEmpty) {
        return null;
      }

      final parsed = double.tryParse(trimmed.replaceAll(',', '.'));
      if (parsed == null) {
        return invalidMessage;
      }

      if (maxValue != null && parsed > maxValue) {
        return maxMessage ??
            AppStrings.validationNumberMustBeAtMost(maxValue.toString());
      }

      return null;
    };
  }
}
