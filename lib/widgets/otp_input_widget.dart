import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Six-box OTP input used on email verification screens.
class OtpInputWidget extends StatelessWidget {
  const OtpInputWidget({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    this.shakeAnimation,
    this.shakeController,
    this.activeColor = const Color(0xFF22C55E),
    this.activeDarkColor = const Color(0xFF16A34A),
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final Animation<double>? shakeAnimation;
  final AnimationController? shakeController;
  final Color activeColor;
  final Color activeDarkColor;

  String get value => controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    Widget boxes = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final isFilled = controllers[i].text.isNotEmpty;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 46,
          height: 56,
          decoration: BoxDecoration(
            color: isFilled ? activeColor.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFilled ? activeColor : const Color(0xFFE2E8F0),
              width: isFilled ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controllers[i],
            focusNode: focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: i == 0 ? 6 : 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isFilled ? activeDarkColor : const Color(0xFF0F172A),
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) => onChanged(i, v),
          ),
        );
      }),
    );

    if (shakeAnimation != null && shakeController != null) {
      boxes = AnimatedBuilder(
        animation: shakeAnimation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              shakeAnimation!.value *
                  (shakeController!.status == AnimationStatus.forward ? -1 : 1),
              0,
            ),
            child: child,
          );
        },
        child: boxes,
      );
    }

    return boxes;
  }
}

/// Shared digit navigation / paste handling for OTP boxes.
void handleOtpDigitChanged({
  required int index,
  required String value,
  required List<TextEditingController> controllers,
  required List<FocusNode> focusNodes,
  VoidCallback? onUpdate,
}) {
  if (value.length == 1 && index < 5) {
    focusNodes[index + 1].requestFocus();
  }
  if (value.isEmpty && index > 0) {
    focusNodes[index - 1].requestFocus();
  }
  if (value.length == 6) {
    for (int i = 0; i < 6; i++) {
      controllers[i].text = value[i];
    }
    focusNodes[5].requestFocus();
  }
  onUpdate?.call();
}

void clearOtpInput({
  required List<TextEditingController> controllers,
  required List<FocusNode> focusNodes,
}) {
  for (final c in controllers) {
    c.clear();
  }
  focusNodes[0].requestFocus();
}
