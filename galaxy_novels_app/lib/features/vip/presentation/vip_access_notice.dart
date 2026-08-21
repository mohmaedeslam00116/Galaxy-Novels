import 'package:flutter/material.dart';

import '../../../shared/widgets/app_notice.dart';

class VipAccessNotice extends StatelessWidget {
  const VipAccessNotice({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AppNotice(
            kind: AppNoticeKind.warning,
            message: message,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ],
      ),
    );
  }
}
