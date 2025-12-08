import 'package:flutter/material.dart';
import 'package:fasalmitra/services/language_service.dart';

class TrText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;
  final double? textScaleFactor;

  const TrText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.softWrap = true,
    this.textScaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, child) {
        return Text(
          LanguageService.instance.t(text),
          style: style,
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
          softWrap: softWrap,
          textScaler: textScaleFactor != null
              ? TextScaler.linear(textScaleFactor!)
              : null,
        );
      },
    );
  }
}
