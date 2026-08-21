import 'package:flutter/material.dart';

import '../layout/app_breakpoints.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    this.appBar,
    this.drawer,
    this.floatingActionButton,
    this.maxContentWidth = 1200,
    this.applyHorizontalPadding = true,
    super.key,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final double maxContentWidth;
  final bool applyHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = applyHorizontalPadding
                ? AppBreakpoints.screenPadding(constraints.maxWidth)
                : 0.0;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  child: body,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
