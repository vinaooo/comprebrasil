import 'package:shared_preferences/shared_preferences.dart';

/// Classe para gerenciar opções de desenvolvedor
class DeveloperOptions {
  static bool _showTestCodes = false;
  static bool _showOpenFoodFactsJson = false;
  static bool _isInitialized = false;

  // Chaves para SharedPreferences
  static const String _keyShowTestCodes = 'show_test_codes';
  static const String _keyShowOpenFoodFactsJson = 'show_open_food_facts_json';

  /// Inicializa as opções carregando valores do SharedPreferences
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _showTestCodes = prefs.getBool(_keyShowTestCodes) ?? false;
    _showOpenFoodFactsJson = prefs.getBool(_keyShowOpenFoodFactsJson) ?? false;
    _isInitialized = true;
  }

  static bool get showTestCodes => _showTestCodes;
  static bool get showOpenFoodFactsJson => _showOpenFoodFactsJson;

  static Future<void> setShowTestCodes(bool value) async {
    _showTestCodes = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowTestCodes, value);
  }

  static Future<void> setShowOpenFoodFactsJson(bool value) async {
    _showOpenFoodFactsJson = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowOpenFoodFactsJson, value);
  }
}
