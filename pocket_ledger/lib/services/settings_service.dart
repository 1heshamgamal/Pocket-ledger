import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  
  // Keys for SharedPreferences
  static const String _languageKey = 'language';
  static const String _currencyKey = 'currency';
  static const String _themeKey = 'theme';
  
  // Default values
  static const String defaultLanguage = 'en';
  static const String defaultCurrency = 'USD';
  static const bool defaultTheme = false; // false = light, true = dark
  
  // Available languages
  static const Map<String, String> availableLanguages = {
    'en': 'English',
    'ar': 'العربية', // Arabic
  };
  
  // Available currencies
  static const Map<String, String> availableCurrencies = {
    'USD': '\$',
    'SAR': 'ر.س', // Saudi Riyal
    'EGP': 'ج.م', // Egyptian Pound
  };
  
  // Singleton pattern
  factory SettingsService() => _instance;
  
  SettingsService._internal();
  
  // Get language
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? defaultLanguage;
  }
  
  // Set language
  Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }
  
  // Get currency
  Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currencyKey) ?? defaultCurrency;
  }
  
  // Set currency
  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, currency);
  }
  
  // Get currency symbol
  Future<String> getCurrencySymbol() async {
    final currency = await getCurrency();
    return availableCurrencies[currency] ?? availableCurrencies[defaultCurrency]!;
  }
  
  // Get theme
  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? defaultTheme;
  }
  
  // Set theme
  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
  
  // Get theme data
  Future<ThemeData> getTheme() async {
    final isDark = await isDarkMode();
    return isDark ? ThemeData.dark() : ThemeData.light();
  }
}