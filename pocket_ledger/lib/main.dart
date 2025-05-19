import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'services/settings_service.dart';
import 'services/database_service.dart';
import 'screens/transaction_entry_screen.dart';
import 'screens/monthly_report_screen.dart';
import 'screens/debt_management_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final settingsService = SettingsService();
  final databaseService = DatabaseService();
  
  // Get initial settings
  final String language = await settingsService.getLanguage();
  final bool isDarkMode = await settingsService.isDarkMode();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider(
          create: (_) => AppState(
            language: language,
            isDarkMode: isDarkMode,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  String _language;
  bool _isDarkMode;
  
  AppState({
    required String language,
    required bool isDarkMode,
  })  : _language = language,
        _isDarkMode = isDarkMode;
  
  String get language => _language;
  bool get isDarkMode => _isDarkMode;
  
  void setLanguage(String language) {
    _language = language;
    notifyListeners();
  }
  
  void setDarkMode(bool isDarkMode) {
    _isDarkMode = isDarkMode;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return MaterialApp(
      title: 'Pocket Ledger',
      theme: appState.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      locale: Locale(appState.language),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
      ],
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  static final List<Widget> _screens = [
    const TransactionEntryScreen(),
    const MonthlyReportScreen(),
    const DebtManagementScreen(),
    const SettingsScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle),
            label: localizations.transactionEntryTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: localizations.monthlyReportTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: localizations.debtManagementTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: localizations.settingsTitle,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}