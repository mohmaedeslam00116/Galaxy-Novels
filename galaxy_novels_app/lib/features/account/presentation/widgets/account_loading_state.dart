import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_skeleton.dart';

class AccountLoadingState extends StatelessWidget {
  const AccountLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'جارٍ تحميل الحساب...',
      excludeSemantics: true,
      child: ListView(
        key: const ValueKey('account-loading-state'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: const [
          Center(
            child: SizedBox(
              width: 620,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSkeleton(height: 88),
                  SizedBox(height: 18),
                  AppSkeleton(height: 20, width: 130),
                  SizedBox(height: 8),
                  AppSkeleton(height: 56, borderRadius: 8),
                  SizedBox(height: 1),
                  AppSkeleton(height: 56, borderRadius: 0),
                  SizedBox(height: 1),
                  AppSkeleton(height: 56, borderRadius: 0),
                  SizedBox(height: 1),
                  AppSkeleton(height: 56, borderRadius: 8),
                  SizedBox(height: 18),
                  AppSkeleton(height: 190),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
