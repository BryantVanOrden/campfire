import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomTextFormField extends StatelessWidget {
  final String hintText;
  final String? labelText; // Add optional labelText
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final int maxLines;
  final EdgeInsets? margin; // Optional margin
  final String? Function(String?)? validator; // Add validator
  final void Function(String?)? onSaved; // Add onSaved

  const CustomTextFormField({
    Key? key,
    required this.hintText,
    this.labelText, // Make the labelText optional
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1, // Default to 1 line
    this.margin, // Default margin is null (no margin)
    this.validator, // Optional validator function
    this.onSaved, // Optional onSaved function
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8), // Apply margin if provided
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align the label to the start
        children: [
          if (labelText != null) // Show label if provided
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0), // Small space between label and input
              child: Text(
                labelText!,
                style: TextStyle(
                  color: AppColors.darkGreen, // Dark green label color
                  fontSize: 14, // Label font size
                  fontWeight: FontWeight.w600, // Label font weight
                ),
              ),
            ),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(
              color: Colors.black, // Text color for the input
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppColors.mediumGreen, // Placeholder color
                fontWeight: FontWeight.w300, // Thin placeholder text
              ),
              filled: true,
              fillColor: Colors.white, // White background
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.shade400, // Light gray border
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: AppColors.mediumGreen, // Green border when focused
                  width: 1.5,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.grey.shade400,
                  width: 1.0,
                ),
              ),
            ),
            validator: validator, // Add the validator function
            onSaved: onSaved, // Add the onSaved function
          ),
        ],
      ),
    );
  }
}
