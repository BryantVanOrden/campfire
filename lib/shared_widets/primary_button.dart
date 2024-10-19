// lib/widgets/primary_button.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart'; // Import the AppColors

class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final IconData? icon;

  const PrimaryButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.activeGreen; // Active state color
            }
            return AppColors.mediumGreen; // Default background color
          },
        ),
        foregroundColor: WidgetStateProperty.all(Colors.white), // Text color
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textStyle: WidgetStateProperty.all(
          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        elevation: WidgetStateProperty.all(3),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      child: icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon),
                SizedBox(width: 8),
                Text(text),
              ],
            )
          : Text(text),
    );
  }
}
