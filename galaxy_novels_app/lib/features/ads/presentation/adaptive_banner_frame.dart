import 'package:flutter/widgets.dart';

class AdaptiveBannerFrame extends StatelessWidget {
  const AdaptiveBannerFrame({
    required this.isLoaded,
    required this.size,
    required this.child,
    super.key,
  });

  final bool isLoaded;
  final Size? size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size;
    if (!isLoaded ||
        resolvedSize == null ||
        !resolvedSize.width.isFinite ||
        !resolvedSize.height.isFinite ||
        resolvedSize.width <= 0 ||
        resolvedSize.height <= 0) {
      return const SizedBox.shrink();
    }

    return SizedBox.fromSize(size: resolvedSize, child: child);
  }
}
