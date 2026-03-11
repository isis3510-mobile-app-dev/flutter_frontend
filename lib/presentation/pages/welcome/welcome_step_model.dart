
import 'package:flutter/material.dart';

class WelcomeStepModel {
  final String title;
  final String description;
  final List<Color> backgroundColor;
  final String ?imagePath;

  WelcomeStepModel({
    required this.title,
    required this.description,
    required this.backgroundColor,
    this.imagePath,
  });
}