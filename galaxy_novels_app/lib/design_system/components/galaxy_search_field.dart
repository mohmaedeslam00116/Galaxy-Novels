import 'package:flutter/material.dart';

class GalaxySearchField extends StatelessWidget {
  const GalaxySearchField({
    required this.hintText,
    required this.onChanged,
    this.controller,
    this.focusNode,
    this.onClear,
    this.statusText,
    this.enabled = true,
    this.onSubmitted,
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onClear;
  final String? statusText;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hintText,
        helperText: statusText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                tooltip: 'مسح البحث',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}
