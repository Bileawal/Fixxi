import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_state.dart';
import 'services/api_client.dart';
import 'services/fixxi_api.dart';
import 'services/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  final client = ApiClient();
  final api = FixxiApi(client);
  final appState = AppState(api, client, storage);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: client),
        Provider<FixxiApi>.value(value: api),
        ChangeNotifierProvider<AppState>.value(value: appState),
      ],
      child: const FixxiApp(),
    ),
  );

  appState.initialize();
}
