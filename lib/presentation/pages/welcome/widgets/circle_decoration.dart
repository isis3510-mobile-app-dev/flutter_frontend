

import 'package:flutter/material.dart';

class CircleDecoration extends StatelessWidget{
  final double size;
  final double opacity;

  const CircleDecoration({
    super.key, 
    required this.size, 
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}