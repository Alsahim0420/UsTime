import 'package:flutter/material.dart';

import '../theme.dart';

/// Gradient page background used by every screen.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.palette.background),
        child: SafeArea(child: Center(child: child)),
      ),
    );
  }
}

/// Width from which pages switch from one stacked column to side-by-side
/// columns.
const wideLayoutBreakpoint = 900.0;

/// A secondary screen: back button and title on top of content that uses the
/// same centered column as the home page. [builder] is told whether there is
/// room for a multi-column layout.
class SubPage extends StatelessWidget {
  const SubPage({
    super.key,
    required this.title,
    required this.builder,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget Function(BuildContext context, bool wide) builder;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subtitle = this.subtitle;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.background),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final wide = width >= wideLayoutBreakpoint;
              final side = ((width - 1120) / 2).clamp(16.0, double.infinity);
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(side, wide ? 28 : 16, side, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Volver',
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: palette.surface,
                            foregroundColor: palette.ink,
                          ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: displayStyle(size: wide ? 34 : 26),
                              ),
                              if (subtitle != null && wide) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(color: palette.muted),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ?action,
                      ],
                    ),
                    SizedBox(height: wide ? 28 : 20),
                    builder(context, wide),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A fixed-width side column next to a flexible main one when [wide];
/// stacked otherwise.
class SideBySide extends StatelessWidget {
  const SideBySide({
    super.key,
    required this.wide,
    required this.side,
    required this.main,
    this.sideWidth = 340,
  });

  final bool wide;
  final Widget side;
  final Widget main;
  final double sideWidth;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [side, const SizedBox(height: 20), main],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: sideWidth, child: side),
        const SizedBox(width: 24),
        Expanded(child: main),
      ],
    );
  }
}

/// Title and description at the top of a card or section.
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title, this.description});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final description = this.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: 13.5, color: context.palette.muted),
          ),
        ],
      ],
    );
  }
}

/// Rounded surface that groups related content.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: palette.shadow(),
      ),
      child: child,
    );
  }
}
