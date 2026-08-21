import 'package:flutter/material.dart';

typedef ReaderSegmentOption<T> = ({
  T value,
  String label,
  IconData icon,
  Key key,
});

class ReaderSegmentedControl<T> extends StatelessWidget {
  const ReaderSegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<ReaderSegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final buttons = _buttons();
          if (_usesCompactLayout(context, constraints)) {
            return options.length > 3
                ? _ScrollableSegments(buttons: buttons)
                : _VerticalSegments(buttons: buttons);
          }
          return _HorizontalSegments(buttons: buttons);
        },
      ),
    );
  }

  List<Widget> _buttons() {
    return [
      for (final option in options)
        _ReaderSegmentButton<T>(
          option: option,
          selected: selected == option.value,
          onTap: () => onChanged(option.value),
        ),
    ];
  }

  bool _usesCompactLayout(BuildContext context, BoxConstraints constraints) {
    return constraints.maxWidth < 280 ||
        MediaQuery.textScalerOf(context).scale(1) >= 1.5;
  }
}

class _ScrollableSegments extends StatelessWidget {
  const _ScrollableSegments({required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final button in buttons) SizedBox(width: 148, child: button),
        ],
      ),
    );
  }
}

class _HorizontalSegments extends StatelessWidget {
  const _HorizontalSegments({required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < buttons.length; index++) ...[
          if (index > 0)
            const SizedBox(height: 48, child: VerticalDivider(width: 1)),
          Expanded(child: buttons[index]),
        ],
      ],
    );
  }
}

class _VerticalSegments extends StatelessWidget {
  const _VerticalSegments({required this.buttons});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < buttons.length; index++) ...[
          if (index > 0) const Divider(height: 1),
          buttons[index],
        ],
      ],
    );
  }
}

class _ReaderSegmentButton<T> extends StatelessWidget {
  const _ReaderSegmentButton({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ReaderSegmentOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      excludeSemantics: true,
      child: InkWell(
        key: option.key,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: ColoredBox(
            color: selected
                ? colors.primary.withValues(alpha: 0.16)
                : Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    option.icon,
                    size: 18,
                    color: selected ? colors.primary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      option.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected
                            ? colors.primary
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
