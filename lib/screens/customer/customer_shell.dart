import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/settings_sheet.dart';
import 'create_request_screen.dart';
import 'customer_home_screen.dart';
import 'my_requests_screen.dart';
import 'technicians_list_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CustomerHomeScreen(),
      const TechniciansListScreen(),
      const MyRequestsScreen(),
    ];

    return Scaffold(
      body: pages[_index],
      floatingActionButton: _index == 0 ? const AiComingSoonButton() : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.engineering_outlined), selectedIcon: Icon(Icons.engineering), label: 'Technicians'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Requests'),
        ],
      ),
      appBar: AppBar(
        title: Text(['Home', 'Nearby Technicians', 'My Requests'][_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'New request',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
            ),
          ),
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
    );
  }
}
