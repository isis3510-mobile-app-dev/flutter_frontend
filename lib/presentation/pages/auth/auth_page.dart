import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_frontend/core/constants/app_assets.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';
import 'package:flutter_frontend/core/constants/app_dimensions.dart';
import 'package:flutter_frontend/core/constants/app_strings.dart';
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
  bool _isSignInMode = true;
  bool _isPasswordObscured = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          setState(() => _isSignInMode = isSignIn);
                        },
                      ),
                      const SizedBox(height: AppDimensions.spaceL),
                      if (_isSignInMode)
                        ..._buildSignInForm(context)
                      else
                        ..._buildCreateAccountForm(context),
                      const SizedBox(height: AppDimensions.spaceL),
                      _ContinueWithDivider(text: AppStrings.authOrContinueWith),
                      const SizedBox(height: AppDimensions.spaceM),
                      GoogleSignInButton(
                        text: AppStrings.authContinueWithGoogle,
                        onPressed: () {},
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
    return Column(
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: AppDimensions.spaceL,
                spreadRadius: AppDimensions.strokeThin,
                offset: Offset(0, AppDimensions.spaceS),
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
          style: context.textTheme.headlineMedium?.copyWith(
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Text(
          AppStrings.authSubtitle,
          style: context.textTheme.bodyMedium?.copyWith(
            color: AppColors.grey700,
          ),
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
      ),
      const SizedBox(height: AppDimensions.spaceM),
      AuthTextField(
        label: AppStrings.authEmailAddress,
        hintText: AppStrings.authEmailHint,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: AppDimensions.spaceM),
      AuthTextField(
        label: AppStrings.authPassword,
        hintText: AppStrings.authPasswordHint,
        isPassword: true,
        obscureText: _isPasswordObscured,
        onToggleVisibility: _togglePasswordVisibility,
      ),
      const SizedBox(height: AppDimensions.spaceL),
      _PrimaryAuthButton(text: AppStrings.authCreateAccount, onPressed: () {}),
    ];
  }

  List<Widget> _buildSignInForm(BuildContext context) {
    return [
      AuthTextField(
        label: AppStrings.authEmailAddress,
        hintText: AppStrings.authEmailHint,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: AppDimensions.spaceM),
      AuthTextField(
        label: AppStrings.authPassword,
        hintText: AppStrings.authPasswordHint,
        isPassword: true,
        obscureText: _isPasswordObscured,
        onToggleVisibility: _togglePasswordVisibility,
      ),
      const SizedBox(height: AppDimensions.spaceS),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {},
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
      _PrimaryAuthButton(text: AppStrings.authSignIn, onPressed: () {}),
    ];
  }

  void _togglePasswordVisibility() {
    setState(() => _isPasswordObscured = !_isPasswordObscured);
  }
}

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

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
        child: Text(
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
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: AppColors.grey300)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceM),
          child: Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: AppColors.grey500,
            ),
          ),
        ),
        const Expanded(child: Divider(thickness: 1, color: AppColors.grey300)),
      ],
    );
  }
}
