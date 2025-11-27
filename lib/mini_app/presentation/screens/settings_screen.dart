import 'package:flutter/material.dart';
import 'package:tg_store/l10n/app_localizations.dart';
import 'package:tg_store/core/services/theme_service.dart';
import 'package:tg_store/core/utils/logger.dart';
import 'package:tg_store/mini_app/presentation/app.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.dark;
  Locale? _selectedLocale;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final themeMode = await ThemeService.getThemeMode();
      final locale = await ThemeService.getLocale();
      
      if (mounted) {
        setState(() {
          _themeMode = themeMode;
          _selectedLocale = locale;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      logger.e('Error loading settings', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateThemeMode(ThemeMode newThemeMode) async {
    await ThemeService.setThemeMode(newThemeMode);
    setState(() {
      _themeMode = newThemeMode;
    });
    
    // Уведомляем App об изменении темы
    if (mounted) {
      final appState = App.appStateKey.currentState;
      if (appState != null) {
        appState.updateThemeMode(newThemeMode);
      }
    }
  }

  Future<void> _updateLocale(Locale newLocale) async {
    await ThemeService.setLocale(newLocale);
    setState(() {
      _selectedLocale = newLocale;
    });
    
    // Уведомляем App об изменении локали
    if (mounted) {
      final appState = App.appStateKey.currentState;
      if (appState != null) {
        appState.updateLocale(newLocale);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentLocale = _selectedLocale ?? 
        Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Тема
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.appearance,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppLocalizations.of(context)!.lightTheme),
                  subtitle: Text(AppLocalizations.of(context)!.useLightColorScheme),
                  value: ThemeMode.light,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppLocalizations.of(context)!.darkTheme),
                  subtitle: Text(AppLocalizations.of(context)!.useDarkColorScheme),
                  value: ThemeMode.dark,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateThemeMode(value);
                    }
                  },
                ),
                RadioListTile<ThemeMode>(
                  title: Text(AppLocalizations.of(context)!.systemTheme),
                  subtitle: Text(AppLocalizations.of(context)!.followSystemSettings),
                  value: ThemeMode.system,
                  groupValue: _themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateThemeMode(value);
                    }
                  },
                ),
                const Divider(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Локализация
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.language,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                RadioListTile<String>(
                  title: Text(AppLocalizations.of(context)!.russian),
                  value: 'ru',
                  groupValue: currentLocale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateLocale(Locale(value, 'RU'));
                    }
                  },
                ),
                RadioListTile<String>(
                  title: Text(AppLocalizations.of(context)!.english),
                  value: 'en',
                  groupValue: currentLocale.languageCode,
                  onChanged: (value) {
                    if (value != null) {
                      _updateLocale(Locale(value, 'US'));
                    }
                  },
                ),
                const Divider(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
