
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  bool isDarkMode = false;
  double textScale = 1.0;
  String layout = "large";

  ////////////////////////////////////////////////////////////
  /// LOAD
  ////////////////////////////////////////////////////////////
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    isDarkMode = prefs.getBool("darkMode") ?? false;
    textScale = prefs.getDouble("textScale") ?? 1.0;
    layout = prefs.getString("layout") ?? "large";

    notifyListeners();
  }

  ////////////////////////////////////////////////////////////
  /// UPDATE
  ////////////////////////////////////////////////////////////
  Future<void> toggleTheme(bool value) async {
    isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("darkMode", value);
    notifyListeners();
  }

  Future<void> setTextScale(double value) async {
    textScale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble("textScale", value);
    notifyListeners();
  }

  Future<void> setLayout(String value) async {
    layout = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("layout", value);
    notifyListeners();
  }
}