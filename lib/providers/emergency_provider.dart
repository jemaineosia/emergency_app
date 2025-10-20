import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/emergency_contact.dart';

class EmergencyProvider extends ChangeNotifier {
  List<EmergencyContact> _contacts = [];
  AppSettings _settings = AppSettings();
  bool _isListening = false;
  String _lastRecognizedText = '';

  List<EmergencyContact> get contacts => _contacts;
  AppSettings get settings => _settings;
  bool get isListening => _isListening;
  String get lastRecognizedText => _lastRecognizedText;

  EmergencyProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load contacts
    final contactsJson = prefs.getString('contacts');
    if (contactsJson != null) {
      final List<dynamic> decoded = jsonDecode(contactsJson);
      _contacts = decoded
          .map((json) => EmergencyContact.fromJson(json))
          .toList();
    }

    // Load settings
    final settingsJson = prefs.getString('settings');
    if (settingsJson != null) {
      _settings = AppSettings.fromJson(jsonDecode(settingsJson));
    }

    notifyListeners();
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = jsonEncode(_contacts.map((c) => c.toJson()).toList());
    await prefs.setString('contacts', contactsJson);
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(_settings.toJson());
    await prefs.setString('settings', settingsJson);
  }

  Future<void> addContact(EmergencyContact contact) async {
    _contacts.add(contact);
    await _saveContacts();
    notifyListeners();
  }

  Future<void> updateContact(EmergencyContact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      await _saveContacts();
      notifyListeners();
    }
  }

  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    await _saveContacts();
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _saveSettings();
    notifyListeners();
  }

  void setListening(bool value) {
    _isListening = value;
    notifyListeners();
  }

  void setLastRecognizedText(String text) {
    _lastRecognizedText = text;
    notifyListeners();
  }

  EmergencyContact? findContactByWakeWord(String text) {
    final lowerText = text.toLowerCase();

    // Check for "help emergency" followed by wake word
    if (lowerText.contains('help emergency')) {
      for (var contact in _contacts) {
        if (lowerText.contains(contact.wakeWord.toLowerCase())) {
          return contact;
        }
      }
    }

    return null;
  }
}
