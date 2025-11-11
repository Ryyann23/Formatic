import 'package:flutter/material.dart';

ButtonStyle purpleElevatedStyle({
  double radius = 14,
  double verticalPadding = 14,
  double elevation = 0,
}) {
  return ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF8B2CF5),
    foregroundColor: Colors.white,
    elevation: elevation,
    padding: EdgeInsets.symmetric(vertical: verticalPadding),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );
}

// placeholder for future text-button helper
ButtonStyle purpleTextButtonStyle({double radius = 14}) {
  return TextButton.styleFrom(
    foregroundColor: const Color(0xFF8B2CF5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );
}
