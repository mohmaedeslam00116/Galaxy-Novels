import 'package:flutter/material.dart';

import 'app_section_header.dart';

@Deprecated('Use AppSectionHeader instead.')
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    required this.title,
    this.action,
    this.leadingIcon,
    super.key,
  });

  final String title;
  final Widget? action;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return AppSectionHeader(
      title: title,
      action: action,
      leadingIcon: leadingIcon,
    );
  }
}
