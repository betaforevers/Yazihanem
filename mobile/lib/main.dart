import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yazihanem_mobile/app.dart';
import 'package:yazihanem_mobile/core/api/api_client.dart';
import 'package:yazihanem_mobile/core/config/app_config.dart';
import 'package:yazihanem_mobile/core/storage/local_db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Turkish locale for intl date/number formatting
  await initializeDateFormatting('tr_TR', null);

  // Initialize Hive local database
  final localDb = LocalDbService();
  await localDb.init();

  // Select environment — change this for staging/production builds
  const environment = AppConfig.dev;

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(environment),
        localDbProvider.overrideWithValue(localDb),
      ],
      child: const YazihanemApp(),
    ),
  );
}
