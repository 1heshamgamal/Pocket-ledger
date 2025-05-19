import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/settings_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage;
  late String _selectedCurrency;
  late bool _isDarkMode;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    final language = await settingsService.getLanguage();
    final currency = await settingsService.getCurrency();
    final isDarkMode = await settingsService.isDarkMode();
    
    setState(() {
      _selectedLanguage = language;
      _selectedCurrency = currency;
      _isDarkMode = isDarkMode;
      _isLoading = false;
    });
  }
  
  Future<void> _saveLanguage(String language) async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    
    await settingsService.setLanguage(language);
    appState.setLanguage(language);
    
    setState(() {
      _selectedLanguage = language;
    });
  }
  
  Future<void> _saveCurrency(String currency) async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    
    await settingsService.setCurrency(currency);
    
    setState(() {
      _selectedCurrency = currency;
    });
  }
  
  Future<void> _saveDarkMode(bool isDarkMode) async {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final appState = Provider.of<AppState>(context, listen: false);
    
    await settingsService.setDarkMode(isDarkMode);
    appState.setDarkMode(isDarkMode);
    
    setState(() {
      _isDarkMode = isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.settingsTitle),
      ),
      body: ListView(
        children: [
          // Language settings
          ListTile(
            title: Text(localizations.language),
            trailing: DropdownButton<String>(
              value: _selectedLanguage,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _saveLanguage(newValue);
                }
              },
              items: SettingsService.availableLanguages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          
          // Currency settings
          ListTile(
            title: Text(localizations.currency),
            trailing: DropdownButton<String>(
              value: _selectedCurrency,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _saveCurrency(newValue);
                }
              },
              items: SettingsService.availableCurrencies.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text('${entry.key} (${entry.value})'),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          
          // Dark mode settings
          SwitchListTile(
            title: Text(localizations.darkMode),
            value: _isDarkMode,
            onChanged: _saveDarkMode,
          ),
          const Divider(),
          
          // App info
          const ListTile(
            title: Text('Pocket Ledger'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}