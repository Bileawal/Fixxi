import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: Text(app.isDark ? 'On' : 'Off'),
            value: app.isDark,
            onChanged: (_) => app.toggleTheme(),
            secondary: Icon(app.isDark ? Icons.dark_mode : Icons.light_mode),
          ),
          if (app.currentUser != null) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(app.currentUser!.name),
              subtitle: Text(app.currentUser!.email),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context); // Close sheet
                await app.logout();
              },
            ),
          ],
        ],
      ),
    );
  }
}

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const SettingsSheet(),
  );
}
