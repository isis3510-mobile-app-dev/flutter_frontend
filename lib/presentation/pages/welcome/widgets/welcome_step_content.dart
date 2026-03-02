

import 'package:flutter/material.dart';
import 'package:flutter_frontend/core/utils/context_extensions.dart';
import 'package:flutter_frontend/presentation/pages/welcome/welcome_step_model.dart';
import 'package:flutter_frontend/presentation/pages/welcome/widgets/circle_decoration.dart';

class WelcomeStepContent extends StatelessWidget{
  final WelcomeStepModel step;
  
  const WelcomeStepContent({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: TopContent(key: ValueKey(step.title), step: step)
        ),
        Expanded(
          flex: 1,
          child: BottomContent(key: ValueKey(step.title), step: step)
        ),
      ],
    );
  }
}


class TopContent extends StatefulWidget {
  const TopContent({super.key, required this.step});
  final WelcomeStepModel step;

  @override
  State<TopContent> createState() => _TopContentState();
}

class _TopContentState extends State<TopContent> {
  double _offsetY = 40;
  double _opacity = 0;

  void _runEntranceAnimation() {
    _offsetY = 40;
    _opacity = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _offsetY = 0;
        _opacity = 1;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _runEntranceAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn, // Efecto de rebote suave
          transform: Matrix4.translationValues(0, _offsetY, 0),
          child: Stack(
            children: [
              Center(
                child: CircleDecoration(size: 190, opacity: 0.1)
              ),
              Center(
                child: CircleDecoration(size: 250, opacity: 0.1)
              ),
              Center(
                child: Image.asset(widget.step.imagePath ?? '', height: 180)
              ),
            ]
          ),
        ),
      ),
    );
  }
}

class BottomContent extends StatefulWidget {
  const BottomContent({super.key, required this.step});
  final WelcomeStepModel step;

  @override
  State<BottomContent> createState() => _BottomContentState();
}

class _BottomContentState extends State<BottomContent> {
  double _offsetY = 20;
  double _opacity = 0;

  void _runEntranceAnimation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _offsetY = 0;
        _opacity = 1;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _runEntranceAnimation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedOpacity(
        duration: const Duration(milliseconds: 600),
        opacity: _opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeIn, // Efecto de rebote suave
          transform: Matrix4.translationValues(0, _offsetY, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 300),
                  child: Text(
                    widget.step.title,
                    style: context.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.step.description,
                style: context.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ),
    );
  }
}