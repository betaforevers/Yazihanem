import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yazihanem_mobile/core/config/theme_config.dart';
import 'package:yazihanem_mobile/core/routing/app_router.dart';

/// Root application widget.
class YazihanemApp extends ConsumerWidget {
  const YazihanemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Yazıhanem',
      debugShowCheckedModeBanner: false,
      theme: ThemeConfig.darkTheme,
      routerConfig: router,
    );
  }
}
