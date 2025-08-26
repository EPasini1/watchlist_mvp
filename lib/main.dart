import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'theme_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    return MaterialApp(
      title: 'Catálogo de Séries e Filmes',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: theme.currentTheme, // começa claro, persiste escolha
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
