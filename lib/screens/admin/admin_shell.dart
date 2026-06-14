import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/settings_sheet.dart';
import 'admin_reports_screen.dart';
import 'admin_technician_list_screen.dart';
import 'admin_users_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final titles = ['Pending', 'Technicians', 'Users', 'Reports'];
    final pages = [
      const AdminTechnicianListScreen(status: 'pending_admin', title: 'Pending Approval'),
      const AdminTechnicianListScreen(status: null, title: 'All Technicians'),
      const AdminUsersScreen(),
      const AdminReportsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            icon: Icon(context.watch<AppState>().isDark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => context.read<AppState>().toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pending_actions), label: 'Pending'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Techs'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Reports'),
        ],
      ),
    );
  }
}
