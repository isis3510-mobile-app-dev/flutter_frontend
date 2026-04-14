import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_frontend/core/constants/app_assets.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
import 'package:flutter_frontend/core/forms/app_form_constraints.dart';
import 'package:flutter_frontend/core/forms/app_form_utils.dart';
import 'package:flutter_frontend/core/network/api_exception.dart';
import 'package:flutter_frontend/core/services/auth_service.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/auth/widgets/auth_text_field.dart';
import 'package:flutter_frontend/presentation/pages/auth/widgets/auth_toggle.dart';
import 'package:flutter_frontend/presentation/pages/auth/widgets/google_sign_in_button.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isSignInMode = true;
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _emailFieldError;
  String? _passwordFieldError;
  String? _nameFieldError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.pageHorizontalPadding,
                    vertical: AppDimensions.spaceL,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppDimensions.spaceL),
                      _buildHeader(context),
                      const SizedBox(height: AppDimensions.spaceXL),
                      AuthToggle(
                        isSignInSelected: _isSignInMode,
                        signInLabel: AppStrings.authSignIn,
                        createAccountLabel: AppStrings.authCreateAccount,
                        onChanged: (isSignIn) {
                          setState(() {
                            _isSignInMode = isSignIn;
                            _clearFieldErrors();
                            _errorMessage = null;
                          });
                        },
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _isSignInMode
                              ? _buildSignInForm(context)
                              : _buildCreateAccountForm(context),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppDimensions.spaceM),
                        Text(
                          _errorMessage!,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spaceL),
                      _ContinueWithDivider(text: AppStrings.authOrContinueWith),
                      const SizedBox(height: AppDimensions.spaceM),
                      GoogleSignInButton(
                        text: AppStrings.authContinueWithGoogle,
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark
        ? AppColors.onBackgroundDark
        : AppColors.onBackground;
    final subtitleColor = isDark ? AppColors.grey500 : AppColors.grey700;

    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.18)
                    : AppColors.shadowSoft,
                blurRadius: AppDimensions.spaceL,
                spreadRadius: AppDimensions.strokeThin,
                offset: const Offset(0, AppDimensions.spaceS),
              ),
            ],
          ),
          child: SvgPicture.asset(
            AppAssets.iconAppPrimary,
            width: AppDimensions.iconXXL,
            height: AppDimensions.iconXXL,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        Text(
          AppStrings.authAppName,
          style: context.textTheme.headlineMedium?.copyWith(color: titleColor),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Text(
          AppStrings.authSubtitle,
          style: context.textTheme.bodyMedium?.copyWith(color: subtitleColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _buildCreateAccountForm(BuildContext context) {
    return [
      AuthTextField(
        label: AppStrings.authFullName,
        hintText: AppStrings.authFullNameHint,
        controller: _nameController,
        forceErrorText: _nameFieldError,
        onChanged: (_) => _clearNameError(),
        validator: AppFormValidators.combine([
          AppFormValidators.required(AppStrings.validationFullNameRequired),
          AppFormValidators.maxCharacters(
            fieldLabel: AppStrings.authFullName,
            maxLength: AppFormConstraints.personNameMaxLength,
          ),
        ]),
      ),
      const SizedBox(height: AppDimensions.spaceM),
      AuthTextField(
        label: AppStrings.authEmailAddress,
        hintText: AppStrings.authEmailHint,
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        forceErrorText: _emailFieldError,
        onChanged: (_) => _clearEmailError(),
        validator: AppFormValidators.email(
          requiredMessage: AppStrings.validationEmailRequired,
          invalidMessage: AppStrings.authErrorInvalidEmail,
        ),
        inputFormatters: AppInputFormatters.email(),
      ),
      const SizedBox(height: AppDimensions.spaceM),
      AuthTextField(
        label: AppStrings.authPassword,
        hintText: AppStrings.authPasswordHint,
        controller: _passwordController,
        isPassword: true,
        obscureText: _isPasswordObscured,
        onToggleVisibility: _togglePasswordVisibility,
        forceErrorText: _passwordFieldError,
        onChanged: (_) => _clearPasswordError(),
        validator: AppFormValidators.password(
          requiredMessage: AppStrings.validationPasswordRequired,
          minLength: 8,
          tooShortMessage: AppStrings.validationPasswordTooShort,
          invalidCharactersMessage:
              AppStrings.validationPasswordUnsupportedCharacters,
        ),
        inputFormatters: AppInputFormatters.password(),
      ),
      const SizedBox(height: AppDimensions.spaceL),
      _PrimaryAuthButton(
        text: AppStrings.authCreateAccount,
        onPressed: _isLoading ? null : _handleSignUp,
        isLoading: _isLoading,
      ),
    ];
  }

  List<Widget> _buildSignInForm(BuildContext context) {
    return [
      AuthTextField(
        label: AppStrings.authEmailAddress,
        hintText: AppStrings.authEmailHint,
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        forceErrorText: _emailFieldError,
        onChanged: (_) => _clearEmailError(),
        validator: AppFormValidators.email(
          requiredMessage: AppStrings.validationEmailRequired,
          invalidMessage: AppStrings.authErrorInvalidEmail,
        ),
        inputFormatters: AppInputFormatters.email(),
      ),
      const SizedBox(height: AppDimensions.spaceM),
      AuthTextField(
        label: AppStrings.authPassword,
        hintText: AppStrings.authPasswordHint,
        controller: _passwordController,
        isPassword: true,
        obscureText: _isPasswordObscured,
        onToggleVisibility: _togglePasswordVisibility,
        forceErrorText: _passwordFieldError,
        onChanged: (_) => _clearPasswordError(),
        validator: AppFormValidators.password(
          requiredMessage: AppStrings.validationPasswordRequired,
          minLength: 0,
          invalidCharactersMessage:
              AppStrings.validationPasswordUnsupportedCharacters,
        ),
        inputFormatters: AppInputFormatters.password(),
      ),
      const SizedBox(height: AppDimensions.spaceS),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: _isLoading ? null : _handleForgotPassword,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.authForgotPassword,
            style: context.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      const SizedBox(height: AppDimensions.spaceL),
      _PrimaryAuthButton(
        text: AppStrings.authSignIn,
        onPressed: _isLoading ? null : _handleSignIn,
        isLoading: _isLoading,
      ),
    ];
  }

  void _togglePasswordVisibility() {
    setState(() => _isPasswordObscured = !_isPasswordObscured);
  }

  Future<void> _handleSignIn() async {
    AppFormSanitizers.trimControllers([_emailController]);
    _clearFieldErrors();
    setState(() {
      _errorMessage = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await _runAuthAction(
      () => _authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      ),
    );
  }

  Future<void> _handleSignUp() async {
    AppFormSanitizers.trimControllers([_nameController, _emailController]);
    _clearFieldErrors();
    setState(() {
      _errorMessage = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await _runAuthAction(() async {
      await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        name: _nameController.text.trim(),
      );
    });
  }

  Future<void> _handleGoogleSignIn() async {
    await _runAuthAction(_authService.signInWithGoogle);
  }

  Future<void> _handleForgotPassword() async {
    AppFormSanitizers.trimControllers([_emailController]);
    final email = _emailController.text.trim();

    if (_emailValidator(_emailController.text) != null) {
      _clearFieldErrors();
      _formKey.currentState?.validate();
      setState(() {
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(email);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.authForgotPasswordEmailSent)),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _forgotPasswordErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = AppStrings.authErrorResetPassword;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _emailValidator(String? value) {
    return AppFormValidators.email(
      requiredMessage: AppStrings.validationEmailRequired,
      invalidMessage: AppStrings.authErrorInvalidEmail,
    )(value);
  }

  void _clearFieldErrors() {
    _emailFieldError = null;
    _passwordFieldError = null;
    _nameFieldError = null;
  }

  void _clearEmailError() {
    if (_emailFieldError == null && _errorMessage == null) {
      return;
    }
    setState(() {
      _emailFieldError = null;
      _errorMessage = null;
    });
  }

  void _clearPasswordError() {
    if (_passwordFieldError == null && _errorMessage == null) {
      return;
    }
    setState(() {
      _passwordFieldError = null;
      _errorMessage = null;
    });
  }

  void _clearNameError() {
    if (_nameFieldError == null && _errorMessage == null) {
      return;
    }
    setState(() {
      _nameFieldError = null;
      _errorMessage = null;
    });
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _clearFieldErrors();
    });

    try {
      await action();
    } on ApiException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } on FirebaseAuthException catch (error) {
      setState(() {
        _applyFirebaseFieldError(error);
      });
    } on PlatformException catch (error) {
      final message = _platformAuthErrorMessage(error);
      setState(() {
        _errorMessage = message.isEmpty ? null : message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = AppStrings.errorGeneric;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFirebaseFieldError(FirebaseAuthException error) {
    final message = _firebaseErrorMessage(error);
    if (message.isEmpty) {
      _errorMessage = null;
      return;
    }

    switch (error.code) {
      case 'invalid-email':
      case 'user-not-found':
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        _emailFieldError = message;
        _errorMessage = null;
        return;
      case 'wrong-password':
      case 'invalid-credential':
      case 'weak-password':
        _passwordFieldError = message;
        _errorMessage = null;
        return;
      default:
        _errorMessage = message;
    }
  }

  String _firebaseErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'sign_in_canceled':
      case 'web-context-cancelled':
      case 'popup-closed-by-user':
        return '';
      case 'invalid-email':
        return AppStrings.authErrorInvalidEmail;
      case 'user-not-found':
        return AppStrings.authErrorUserNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.authErrorWrongPassword;
      case 'email-already-in-use':
        return AppStrings.authErrorEmailInUse;
      case 'weak-password':
        return AppStrings.authErrorWeakPassword;
      case 'network-request-failed':
        return AppStrings.errorNoConnection;
      case 'account-exists-with-different-credential':
        return AppStrings.authErrorAccountExistsDifferentCredential;
      case 'too-many-requests':
        return AppStrings.authErrorTooManyRequests;
      default:
        return AppStrings.errorGeneric;
    }
  }

  String _platformAuthErrorMessage(PlatformException error) {
    final normalizedCode = error.code.toLowerCase();
    final message = error.message?.toLowerCase() ?? '';

    if (normalizedCode == 'sign_in_canceled' ||
        normalizedCode == 'canceled' ||
        normalizedCode == 'cancelled') {
      return '';
    }

    if (normalizedCode.contains('network')) {
      return AppStrings.errorNoConnection;
    }

    final isGoogleConfigError =
        normalizedCode == 'sign_in_failed' ||
        message.contains('apiexception: 10') ||
        message.contains('10:') ||
        message.contains('developer error');

    if (isGoogleConfigError) {
      return AppStrings.authErrorGoogleConfig;
    }

    return AppStrings.errorGeneric;
  }

  String _forgotPasswordErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return AppStrings.authErrorInvalidEmail;
      case 'network-request-failed':
        return AppStrings.errorNoConnection;
      case 'too-many-requests':
        return AppStrings.authErrorTooManyRequests;
      default:
        return AppStrings.authErrorResetPassword;
    }
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeightL,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: AppDimensions.iconM,
                height: AppDimensions.iconM,
                child: CircularProgressIndicator(
                  strokeWidth: AppDimensions.strokeThin,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.onPrimary,
                  ),
                ),
              )
            : Text(
                text,
                style: context.textTheme.titleMedium?.copyWith(
                  color: AppColors.onPrimary,
                ),
              ),
      ),
    );
  }
}

class _ContinueWithDivider extends StatelessWidget {
  const _ContinueWithDivider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = isDark ? AppColors.grey700 : AppColors.grey300;
    final textColor = isDark ? AppColors.grey500 : AppColors.grey500;

    return Row(
      children: [
        Expanded(child: Divider(thickness: 1, color: dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
          child: Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(color: textColor),
          ),
        ),
        Expanded(child: Divider(thickness: 1, color: dividerColor)),
      ],
    );
  }
}
