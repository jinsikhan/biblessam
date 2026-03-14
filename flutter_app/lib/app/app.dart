import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'router.dart';
import '../services/storage_service.dart';
import '../services/bible_api_service.dart';
import '../services/ai_api_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StorageService()..load()),
        Provider(create: (_) => BibleApiService()),
        Provider(create: (_) => AiApiService()),
      ],
      child: Consumer<StorageService>(
        builder: (context, storage, _) {
          return MaterialApp.router(
            title: '바이블쌤',
            debugShowCheckedModeBanner: false,
            theme: buildLightTheme(),
            darkTheme: buildDarkTheme(),
            themeMode: storage.themeMode,
            scrollBehavior: ScrollBehavior().copyWith(scrollbars: false),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
