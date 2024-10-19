import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomDropdownFormField<T> extends StatelessWidget {
  final String hintText;
  final String? labelText; // Add optional labelText
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final EdgeInsets? margin; // Optional margin
  final FormFieldValidator<T>? validator; // Optional validator

  const CustomDropdownFormField({
    Key? key,
    required this.hintText,
    this.labelText, // Optional labelText
    required this.items,
    this.value,
    required this.onChanged,
    this.margin,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(vertical: 8), // Apply margin if provided
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align label to the start
        children: [
          if (labelText != null) // Show label if provided
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0), // Space between label and dropdown
              child: Text(
                labelText!,
                style: TextStyle(
                  color: AppColors.darkGreen, // Dark green label color
                  fontSize: 14, // Label font size
                  fontWeight: FontWeight.w600, // Label font weight
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white, // White background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade400, // Light gray border
                width: 1.0,
              ),
            ),
            child: DropdownButtonFormField<T>(
              value: value,
              onChanged: onChanged,
              validator: validator,
              isDense: true, // Optionally reduce the height of the dropdown
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.mediumGreen, // Medium green placeholder text
                  fontWeight: FontWeight.w300, // Thin placeholder text
                ),
                filled: true,
                fillColor: Colors.white, // White background
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Padding for consistent text alignment
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
              hint: Align(
                alignment: Alignment.centerLeft, // Change alignment as needed
                child: Text(
                  hintText,
                  style: TextStyle(
                    color: AppColors.mediumGreen, // Hint color
                    fontWeight: FontWeight.w300, // Hint font weight
                  ),
                ),
              ),
              items: items,
              dropdownColor: Colors.white, // Dropdown color
            ),
          ),
        ],
      ),
    );
  }
}
