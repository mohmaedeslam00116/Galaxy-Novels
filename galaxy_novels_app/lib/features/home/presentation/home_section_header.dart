import 'package:flutter/material.dart';

import '../../../design_system/components/galaxy_section_header.dart';
import '../domain/home_customization.dart';
import 'home_density_metrics.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    required this.customization,
    this.icon,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.actionKey,
    super.key,
  });

  final String title;
  final IconData? icon;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;
  final HomeCustomization customization;

  @override
  Widget build(BuildContext context) {
    final density = customization.density;
    final showsDetails = customization.headerStyle == HomeHeaderStyle.standard;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        density.horizontalPadding,
        density.sectionSpacing,
        density.horizontalPadding,
        8,
      ),
      child: GalaxySectionHeader(
        title: title,
        icon: icon,
        subtitle: subtitle,
        actionLabel: actionLabel,
        onAction: onAction,
        actionKey: actionKey,
        compact: !showsDetails,
      ),
    );
  }
}
