// =============================================================================
// FILE: lib/core/theme/theme_provider.dart
// PURPOSE: Riverpod StateNotifier for dynamic theme — loads, caches, saves
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme_tokens.dart';
import '../services/theme_service.dart';
import '../network/dio_client.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class ThemeConfigState {
  const ThemeConfigState({
    this.lightTokens = AppThemeTokens.lightDefaults,
    this.darkTokens = AppThemeTokens.darkDefaults,
    this.presetName = 'Default',
    this.customPresets = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.isApplying = false,
    this.error,
    this.saveSuccess = false,
    this.applySuccess = false,
  });

  final AppThemeTokens lightTokens;
  final AppThemeTokens darkTokens;
  final String presetName;
  /// User-saved named presets (name → light+dark token pair).
  final Map<String, ({AppThemeTokens light, AppThemeTokens dark})> customPresets;
  final bool isLoading;
  final bool isSaving;
  final bool isApplying;
  final String? error;
  final bool saveSuccess;
  final bool applySuccess;

  ThemeConfigState copyWith({
    AppThemeTokens? lightTokens,
    AppThemeTokens? darkTokens,
    String? presetName,
    Map<String, ({AppThemeTokens light, AppThemeTokens dark})>? customPresets,
    bool? isLoading,
    bool? isSaving,
    bool? isApplying,
    String? error,
    bool? saveSuccess,
    bool? applySuccess,
    bool clearError = false,
  }) => ThemeConfigState(
    lightTokens:   lightTokens   ?? this.lightTokens,
    darkTokens:    darkTokens    ?? this.darkTokens,
    presetName:    presetName    ?? this.presetName,
    customPresets: customPresets ?? this.customPresets,
    isLoading:     isLoading     ?? this.isLoading,
    isSaving:      isSaving      ?? this.isSaving,
    isApplying:    isApplying    ?? this.isApplying,
    error:         clearError ? null : (error ?? this.error),
    saveSuccess:   saveSuccess   ?? false,
    applySuccess:  applySuccess  ?? false,
  );

  /// All presets: built-in + user-saved (user-saved appear first).
  Map<String, ({AppThemeTokens light, AppThemeTokens dark})> get allPresets => {
    ...customPresets,
    ...AppThemeTokens.presets,
  };
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class ThemeConfigNotifier extends StateNotifier<ThemeConfigState> {
  ThemeConfigNotifier(this._service) : super(const ThemeConfigState());

  final ThemeService _service;
  static const _cacheKey        = 'vidyron_theme_config_v5';
  static const _customPresetsKey = 'vidyron_custom_presets_v5';

  /// Load theme + custom presets: cache-first for instant paint, then API.
  Future<void> loadTheme() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _restoreCustomPresets();   // load saved presets first (instant)
    try {
      await _restoreFromCache();
      final data = await _service.getSuperAdminTheme();
      if (data != null) {
        final lightRaw = data['lightTokens'] ?? data['light'];
        final darkRaw = data['darkTokens'] ?? data['dark'];
        final light = lightRaw != null
            ? AppThemeTokens.fromJson(Map<String, dynamic>.from(lightRaw))
            : AppThemeTokens.lightDefaults;
        final dark = darkRaw != null
            ? AppThemeTokens.fromJson(Map<String, dynamic>.from(darkRaw))
            : AppThemeTokens.darkDefaults;
        state = state.copyWith(
          lightTokens: light,
          darkTokens: dark,
          presetName: data['presetName'] as String? ?? 'Custom',
          isLoading: false,
        );
        await _persistToCache(light, dark, state.presetName);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Live-update a single token without saving to API (instant preview)
  void updateToken({
    required bool isLight,
    required String tokenKey,
    required Color color,
  }) {
    if (isLight) {
      state = state.copyWith(
        lightTokens: _applyTokenByKey(state.lightTokens, tokenKey, color),
      );
    } else {
      state = state.copyWith(
        darkTokens: _applyTokenByKey(state.darkTokens, tokenKey, color),
      );
    }
  }

  /// Apply a named preset — checks custom presets first, then built-in.
  void applyPreset(String presetName) {
    final preset = state.customPresets[presetName]
        ?? AppThemeTokens.presets[presetName];
    if (preset == null) return;
    state = state.copyWith(
      lightTokens: preset.light,
      darkTokens: preset.dark,
      presetName: presetName,
    );
  }

  /// Reset to built-in defaults
  void resetToDefaults() {
    state = state.copyWith(
      lightTokens: AppThemeTokens.lightDefaults,
      darkTokens: AppThemeTokens.darkDefaults,
      presetName: 'Default',
    );
  }

  /// Save current tokens to backend
  Future<void> saveTheme() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _service.saveSuperAdminTheme(
        light: state.lightTokens.toJson(),
        dark: state.darkTokens.toJson(),
        presetName: state.presetName,
      );
      await _persistToCache(state.lightTokens, state.darkTokens, state.presetName);
      state = state.copyWith(isSaving: false, saveSuccess: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  /// Push theme to selected portals
  Future<void> applyToPortals(List<String> portals) async {
    state = state.copyWith(isApplying: true, clearError: true);
    try {
      await _service.applyThemeToPortals(
        portals: portals,
        light: state.lightTokens.toJson(),
        dark: state.darkTokens.toJson(),
      );
      state = state.copyWith(isApplying: false, applySuccess: true);
    } catch (e) {
      state = state.copyWith(isApplying: false, error: e.toString());
    }
  }

  // ─── Cache ────────────────────────────────────────────────────────────────

  Future<void> _restoreFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['light'] != null && json['dark'] != null) {
        state = state.copyWith(
          lightTokens: AppThemeTokens.fromJson(Map<String, dynamic>.from(json['light'])),
          darkTokens: AppThemeTokens.fromJson(Map<String, dynamic>.from(json['dark'])),
          presetName: json['presetName'] as String? ?? 'Custom',
        );
      }
    } catch (_) {}
  }

  Future<void> _persistToCache(
      AppThemeTokens light, AppThemeTokens dark, String presetName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode({
        'light': light.toJson(),
        'dark': dark.toJson(),
        'presetName': presetName,
      }));
    } catch (_) {}
  }

  // ─── Custom Presets ───────────────────────────────────────────────────────

  /// Save current tokens as a named custom preset.
  Future<void> saveAsCustomPreset(String name) async {
    if (name.trim().isEmpty) return;
    final updated = {
      ...state.customPresets,
      name.trim(): (light: state.lightTokens, dark: state.darkTokens),
    };
    state = state.copyWith(customPresets: updated, presetName: name.trim());
    await _persistCustomPresets(updated);
  }

  /// Delete a saved custom preset by name.
  Future<void> deleteCustomPreset(String name) async {
    final updated = Map<String, ({AppThemeTokens light, AppThemeTokens dark})>
        .from(state.customPresets)
      ..remove(name);
    state = state.copyWith(customPresets: updated);
    await _persistCustomPresets(updated);
  }

  Future<void> _restoreCustomPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_customPresetsKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final presets = <String, ({AppThemeTokens light, AppThemeTokens dark})>{};
      for (final entry in json.entries) {
        final v = entry.value as Map<String, dynamic>;
        presets[entry.key] = (
          light: AppThemeTokens.fromJson(Map<String, dynamic>.from(v['light'] ?? {})),
          dark:  AppThemeTokens.fromJson(Map<String, dynamic>.from(v['dark']  ?? {})),
        );
      }
      if (presets.isNotEmpty) {
        state = state.copyWith(customPresets: presets);
      }
    } catch (_) {}
  }

  Future<void> _persistCustomPresets(
      Map<String, ({AppThemeTokens light, AppThemeTokens dark})> presets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = <String, dynamic>{};
      for (final entry in presets.entries) {
        json[entry.key] = {
          'light': entry.value.light.toJson(),
          'dark':  entry.value.dark.toJson(),
        };
      }
      await prefs.setString(_customPresetsKey, jsonEncode(json));
    } catch (_) {}
  }

  // ─── Token key dispatch ───────────────────────────────────────────────────

  AppThemeTokens _applyTokenByKey(AppThemeTokens t, String key, Color color) {
    switch (key) {
      case 'surfaceBg':         return t.copyWith(surfaceBg: color);
      case 'cardBg':            return t.copyWith(cardBg: color);
      case 'sidebarBg':         return t.copyWith(sidebarBg: color);
      case 'topbarBg':          return t.copyWith(topbarBg: color);
      case 'textPrimary':       return t.copyWith(textPrimary: color);
      case 'textSecondary':     return t.copyWith(textSecondary: color);
      case 'textHint':          return t.copyWith(textHint: color);
      case 'textLink':          return t.copyWith(textLink: color);
      case 'primary':           return t.copyWith(primary: color);
      case 'primaryLight':      return t.copyWith(primaryLight: color);
      case 'primaryDark':       return t.copyWith(primaryDark: color);
      case 'onPrimary':         return t.copyWith(onPrimary: color);
      case 'tableHeaderBg':     return t.copyWith(tableHeaderBg: color);
      case 'tableHeaderText':   return t.copyWith(tableHeaderText: color);
      case 'tableRowEvenBg':    return t.copyWith(tableRowEvenBg: color);
      case 'tableRowOddBg':     return t.copyWith(tableRowOddBg: color);
      case 'tableBorder':       return t.copyWith(tableBorder: color);
      case 'tableHoverBg':      return t.copyWith(tableHoverBg: color);
      case 'inputBg':           return t.copyWith(inputBg: color);
      case 'inputBorder':       return t.copyWith(inputBorder: color);
      case 'inputFocusBorder':  return t.copyWith(inputFocusBorder: color);
      case 'inputLabel':        return t.copyWith(inputLabel: color);
      case 'buttonPrimaryBg':   return t.copyWith(buttonPrimaryBg: color);
      case 'buttonPrimaryText': return t.copyWith(buttonPrimaryText: color);
      case 'buttonSecondaryBg': return t.copyWith(buttonSecondaryBg: color);
      case 'buttonSecondaryText': return t.copyWith(buttonSecondaryText: color);
      case 'buttonDangerBg':    return t.copyWith(buttonDangerBg: color);
      case 'chipActiveBg':      return t.copyWith(chipActiveBg: color);
      case 'chipActiveText':    return t.copyWith(chipActiveText: color);
      case 'chipInactiveBg':    return t.copyWith(chipInactiveBg: color);
      case 'successBg':         return t.copyWith(successBg: color);
      case 'successText':       return t.copyWith(successText: color);
      case 'warningBg':         return t.copyWith(warningBg: color);
      case 'warningText':       return t.copyWith(warningText: color);
      case 'errorBg':           return t.copyWith(errorBg: color);
      case 'errorText':         return t.copyWith(errorText: color);
      case 'infoBg':            return t.copyWith(infoBg: color);
      case 'infoText':          return t.copyWith(infoText: color);
      case 'navItemBg':         return t.copyWith(navItemBg: color);
      case 'navItemActiveBg':   return t.copyWith(navItemActiveBg: color);
      case 'navItemText':       return t.copyWith(navItemText: color);
      case 'navItemActiveText': return t.copyWith(navItemActiveText: color);
      case 'navItemIcon':       return t.copyWith(navItemIcon: color);
      case 'navItemActiveIcon': return t.copyWith(navItemActiveIcon: color);
      case 'divider':           return t.copyWith(divider: color);
      case 'cardBorder':        return t.copyWith(cardBorder: color);
      case 'shadowColor':       return t.copyWith(shadowColor: color);
      case 'shimmerBase':       return t.copyWith(shimmerBase: color);
      case 'shimmerHighlight':  return t.copyWith(shimmerHighlight: color);
      default: return t;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final themeServiceProvider = Provider<ThemeService>(
  (ref) => ThemeService(ref.read(dioProvider)),
);

final themeConfigProvider =
    StateNotifierProvider<ThemeConfigNotifier, ThemeConfigState>(
  (ref) => ThemeConfigNotifier(ref.read(themeServiceProvider)),
);

/// Convenience providers for direct token access
final lightThemeTokensProvider = Provider<AppThemeTokens>(
  (ref) => ref.watch(themeConfigProvider).lightTokens,
);

final darkThemeTokensProvider = Provider<AppThemeTokens>(
  (ref) => ref.watch(themeConfigProvider).darkTokens,
);
