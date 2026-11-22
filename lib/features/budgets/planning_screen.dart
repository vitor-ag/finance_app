import 'package:flutter/material.dart';

import '../../core/design/app_theme.dart';
import '../../core/design/components.dart';
import '../goals/presentation/screens/goals_screen.dart';
import 'budgets_screen.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final wide = WindowSizeClass.wide(context);
    const budgets = BudgetsScreen(key: ValueKey('planejar-orçamentos'));
    const goals = GoalsScreen(key: ValueKey('planejar-metas'), embedded: true);
    return Scaffold(
      appBar: AppBar(title: const Text('Planejar')),
      body: AppContent(
        child: Column(
          children: [
            if (!wide)
              Wrap(
                spacing: 8,
                children: [
                  for (final (i, label) in ['Orçamentos', 'Metas'].indexed)
                    ChoiceChip(
                      label: Text(label),
                      selected: i == _tab,
                      onSelected: (_) => setState(() => _tab = i),
                    ),
                ],
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  children: [
                    for (final (i, child) in [budgets, goals].indexed)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: wide && i == 1 ? constraints.maxWidth / 2 + 8 : 0,
                        right: wide && i == 0
                            ? constraints.maxWidth / 2 + 8
                            : 0,
                        child: Offstage(
                          offstage: !wide && _tab != i,
                          child: TickerMode(
                            enabled: wide || _tab == i,
                            child: child,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
