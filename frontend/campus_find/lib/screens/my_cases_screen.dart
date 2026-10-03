import 'package:flutter/material.dart';
import 'my_reports_screen.dart';
import 'my_claims_screen.dart';

/// Tabbed container for "My Reports" and "My Claims" (My Active Cases).
class MyCasesScreen extends StatelessWidget {
  const MyCasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: const Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'My Reports', icon: Icon(Icons.folder_outlined)),
              Tab(text: 'My Claims', icon: Icon(Icons.assignment_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                MyReportsScreen(embedded: true),
                MyClaimsScreen(embedded: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
