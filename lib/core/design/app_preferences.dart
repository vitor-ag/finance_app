import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences extends ChangeNotifier {
  AppPreferences({SharedPreferencesAsync? store}) : _store = store;

  final SharedPreferencesAsync? _store;
  bool get isPersistent => _store != null;
  bool onboardingDone = true;
  bool discreet = false;
  String name = '';
  ThemeMode theme = ThemeMode.system;
  int accent = 0;

  Future<void> load() async {
    final store = _store;
    if (store == null) return;
    try {
      final (done, hidden, savedName, appearance, savedAccent) = await (
        store.getBool('onboardingDone'),
        store.getBool('discreet'),
        store.getString('profileName'),
        store.getString('theme'),
        store.getInt('accent'),
      ).wait;
      onboardingDone = done ?? false;
      discreet = hidden ?? false;
      name = savedName ?? '';
      theme = ThemeMode.values.firstWhere(
        (value) => value.name == appearance,
        orElse: () => ThemeMode.system,
      );
      accent = (savedAccent ?? 0).clamp(0, 3);
    } on MissingPluginException {
      // Headless Flutter sessions do not have a platform preferences store.
    } on PlatformException {
      // Keep the app accessible with defaults if preferences are unavailable.
    } on ParallelWaitError {
      // Platform plugins may be unavailable during startup.
    }
    notifyListeners();
  }

  Future<void> finishOnboarding(String profileName) async {
    await _store?.setString('profileName', profileName);
    await _store?.setBool('onboardingDone', true);
    name = profileName;
    onboardingDone = true;
    notifyListeners();
  }

  Future<void> setDiscreet(bool value) async {
    discreet = value;
    notifyListeners();
    await _persist((store) => store.setBool('discreet', value));
  }

  Future<void> setTheme(ThemeMode value) async {
    theme = value;
    notifyListeners();
    await _persist((store) => store.setString('theme', value.name));
  }

  Future<void> setAccent(int value) async {
    accent = value;
    notifyListeners();
    await _persist((store) => store.setInt('accent', value));
  }

  Future<void> _persist(
    Future<void> Function(SharedPreferencesAsync) write,
  ) async {
    final store = _store;
    if (store == null) return;
    try {
      await write(store);
    } on MissingPluginException {
      // Keep the preference for the current session.
    }
  }
}

class PreferencesScope extends InheritedNotifier<AppPreferences> {
  const PreferencesScope({
    super.key,
    required AppPreferences preferences,
    required super.child,
  }) : super(notifier: preferences);

  static AppPreferences? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferencesScope>()?.notifier;
}
