import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pamigay/utils/constants.dart';

/// A reusable form input field with consistent styling throughout the app.
///
/// This component provides a standardized input field that can be used
/// for various form inputs like text, numbers, etc.
class FormInputField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController controller;
  
  /// Optional label text to display above the field
  final String? labelText;
  
  /// Optional hint text to display inside the field
  final String? hintText;
  
  /// Optional helper text to display below the field
  final String? helperText;
  
  /// Optional error text to display when validation fails
  final String? errorText;
  
  /// Whether the field is required
  final bool isRequired;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Callback when the value changes
  final Function(String)? onChanged;
  
  /// Keyboard type for the input
  final TextInputType keyboardType;
  
  /// Input formatters for restricting input
  final List<TextInputFormatter>? inputFormatters;
  
  /// Text capitalization behavior
  final TextCapitalization textCapitalization;
  
  /// Maximum number of lines for multiline input
  final int? maxLines;
  
  /// Whether to obscure text (for passwords)
  final bool obscureText;
  
  /// Prefix icon to display inside the field
  final IconData? prefixIcon;
  
  /// Suffix icon to display inside the field
  final Widget? suffixIcon;
  
  /// Callback when the field is submitted
  final Function(String)? onSubmitted;
  
  /// Focus node for controlling focus
  final FocusNode? focusNode;
  
  /// Auto-validation mode
  final AutovalidateMode? autovalidateMode;
  
  /// Validation function
  final String? Function(String?)? validator;

  const FormInputField({
    Key? key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isRequired = false,
    this.enabled = true,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.focusNode,
    this.autovalidateMode,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label text if provided
        if (labelText != null) ...[
          Row(
            children: [
              Text(
                labelText!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        // Text form field
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            errorText: errorText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: PamigayColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            filled: !enabled,
            fillColor: !enabled ? Colors.grey[200] : null,
          ),
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          obscureText: obscureText,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          focusNode: focusNode,
          autovalidateMode: autovalidateMode,
          validator: validator,
          style: TextStyle(
            color: enabled ? Colors.black : Colors.grey[700],
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
