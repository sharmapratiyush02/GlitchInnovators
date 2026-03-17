import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  // ── Theme ──────────────────────────────────────────────────────────────
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // ── Onboarding ──────────────────────────────────────────────────────────
  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  void completeOnboarding(UserProfile profile) {
    _profile = profile;
    _onboardingComplete = true;
    notifyListeners();
  }

  // ── Language ────────────────────────────────────────────────────────────
  AppLanguage _language = AppLanguage.english;
  AppLanguage get language => _language;
  void setLanguage(AppLanguage lang) {
    _language = lang;
    _profile = _profile?.copyWith(language: lang);
    notifyListeners();
  }

  // ── Chat ────────────────────────────────────────────────────────────────
  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool _isTyping = false;
  bool get isTyping => _isTyping;

  void addMessage(ChatMessage msg) {
    _messages.add(msg);
    notifyListeners();
  }

  void updateMessage(String id, {String? text, bool? isLoading, List<Memory>? memories}) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(
        text: text,
        isLoading: isLoading,
        memories: memories,
      );
      notifyListeners();
    }
  }

  void setTyping(bool value) {
    _isTyping = value;
    notifyListeners();
  }

  // ── Journal ────────────────────────────────────────────────────────────
  final List<JournalEntry> _journalEntries = [];
  List<JournalEntry> get journalEntries => List.unmodifiable(_journalEntries);

  int _streakDays = 0;
  int get streakDays => _streakDays;

  Mood? _todayMood;
  Mood? get todayMood => _todayMood;

  void addJournalEntry(JournalEntry entry) {
    _journalEntries.insert(0, entry);
    _todayMood = entry.mood;

    // Check streak
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final hasYesterday = _journalEntries.any((e) =>
      e.date.year == yesterday.year &&
      e.date.month == yesterday.month &&
      e.date.day == yesterday.day);
    if (_streakDays == 0 || hasYesterday) {
      _streakDays += 1;
    }
    notifyListeners();
  }

  // ── Settings ────────────────────────────────────────────────────────────
  bool _biometricEnabled = false;
  bool get biometricEnabled => _biometricEnabled;
  void setBiometricEnabled(bool val) {
    _biometricEnabled = val;
    notifyListeners();
  }

  bool _morningCheckIn = true;
  bool get morningCheckIn => _morningCheckIn;
  void toggleMorningCheckIn() {
    _morningCheckIn = !_morningCheckIn;
    notifyListeners();
  }

  bool _memoryOfDay = true;
  bool get memoryOfDay => _memoryOfDay;
  void toggleMemoryOfDay() {
    _memoryOfDay = !_memoryOfDay;
    notifyListeners();
  }

  bool _weeklySummary = false;
  bool get weeklySummary => _weeklySummary;
  void toggleWeeklySummary() {
    _weeklySummary = !_weeklySummary;
    notifyListeners();
  }

  // ── Navigation ──────────────────────────────────────────────────────────
  int _currentTabIndex = 0;
  int get currentTabIndex => _currentTabIndex;
  void setTabIndex(int idx) {
    _currentTabIndex = idx;
    notifyListeners();
  }
}
