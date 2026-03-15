
import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/constants/app_colors.dart';

class FullWidthButton extends StatelessWidget{
  const FullWidthButton({
    super.key, 
    required this.text, 
    required this.onPressed, 
    this.height = 46,
    this.backgroundColor,
    this.borderColor,
    this.textColor = AppColors.onPrimary,
    this.splashColor = AppColors.grey100,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final double height;
  final Color ?backgroundColor;
  final Color ?borderColor;
  final Color textColor;
  final Color splashColor;
  final IconData ?icon;

  @override  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        minimumSize: Size.fromHeight(height),
        overlayColor: splashColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(height),
          side: borderColor != null ? BorderSide(color: borderColor!) : BorderSide.none,
        ),
      ),
      icon: icon != null ? Icon(icon, color: textColor) : const SizedBox.shrink(),
      label: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}