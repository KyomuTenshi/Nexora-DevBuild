import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexora/core/constants/store_catalog.dart';
import 'package:nexora/core/di/providers.dart';
import 'package:nexora/core/theme/app_colors.dart';

/// Сколько опыта нужно на один уровень.
const int kXpPerLevel = 2000;

/// Инициалы для аватара: «Данияр Ш» -> «ДШ», «Анна» -> «АН».
String initialsOf(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final list = words.toList();
  if (list.isEmpty) return '?';
  if (list.length >= 2) return (list[0][0] + list[1][0]).toUpperCase();
  final w = list.first;
  return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
}

/// Профиль пользователя. Неизменяемый объект: меняем только через copyWith.
class ProfileState {
  const ProfileState({
    required this.name,
    required this.avatarText,
    required this.bio,
    required this.accentIndex,
    required this.bannerId,
    required this.frameId,
    required this.badgeId,
    required this.genres,
    required this.points,
    required this.xp,
    required this.unlocked,
    required this.showFavorites,
    required this.showAchievements,
    required this.showStats,
  });

  /// Профиль нового пользователя (значения как в макете).
  factory ProfileState.initial() => const ProfileState(
        name: 'Данияр',
        avatarText: 'ДШ',
        bio: '',
        accentIndex: 0,
        bannerId: kBannerBase,
        frameId: kFrameGold,
        badgeId: kBadgeFan,
        genres: [],
        points: 1200,
        xp: 33440, // уровень 17, 1 440 / 2 000 XP
        unlocked: kInitiallyUnlocked,
        showFavorites: true,
        showAchievements: true,
        showStats: true,
      );

  final String name;
  final String avatarText;
  final String bio;
  final int accentIndex;
  final String bannerId;
  final String frameId;
  final String badgeId;
  final List<String> genres;
  final int points;
  final int xp;
  final Set<String> unlocked;
  final bool showFavorites;
  final bool showAchievements;
  final bool showStats;

  Color get accent => AppColors.accents[accentIndex % AppColors.accents.length];
  int get level => 1 + xp ~/ kXpPerLevel;
  int get xpInLevel => xp % kXpPerLevel;

  ProfileState copyWith({
    String? name,
    String? avatarText,
    String? bio,
    int? accentIndex,
    String? bannerId,
    String? frameId,
    String? badgeId,
    List<String>? genres,
    int? points,
    int? xp,
    Set<String>? unlocked,
    bool? showFavorites,
    bool? showAchievements,
    bool? showStats,
  }) {
    return ProfileState(
      name: name ?? this.name,
      avatarText: avatarText ?? this.avatarText,
      bio: bio ?? this.bio,
      accentIndex: accentIndex ?? this.accentIndex,
      bannerId: bannerId ?? this.bannerId,
      frameId: frameId ?? this.frameId,
      badgeId: badgeId ?? this.badgeId,
      genres: genres ?? this.genres,
      points: points ?? this.points,
      xp: xp ?? this.xp,
      unlocked: unlocked ?? this.unlocked,
      showFavorites: showFavorites ?? this.showFavorites,
      showAchievements: showAchievements ?? this.showAchievements,
      showStats: showStats ?? this.showStats,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatarText': avatarText,
        'bio': bio,
        'accentIndex': accentIndex,
        'bannerId': bannerId,
        'frameId': frameId,
        'badgeId': badgeId,
        'genres': genres,
        'points': points,
        'xp': xp,
        'unlocked': unlocked.toList(),
        'showFavorites': showFavorites,
        'showAchievements': showAchievements,
        'showStats': showStats,
      };

  /// Читаем осторожно: если поля нет или тип другой, берём значение по умолчанию.
  factory ProfileState.fromJson(Map<String, dynamic> json) {
    final d = ProfileState.initial();
    return ProfileState(
      name: json['name'] as String? ?? d.name,
      avatarText: json['avatarText'] as String? ?? d.avatarText,
      bio: json['bio'] as String? ?? d.bio,
      accentIndex: json['accentIndex'] as int? ?? d.accentIndex,
      bannerId: json['bannerId'] as String? ?? d.bannerId,
      frameId: json['frameId'] as String? ?? d.frameId,
      badgeId: json['badgeId'] as String? ?? d.badgeId,
      genres: (json['genres'] as List<dynamic>?)?.cast<String>() ?? d.genres,
      points: json['points'] as int? ?? d.points,
      xp: json['xp'] as int? ?? d.xp,
      unlocked: (json['unlocked'] as List<dynamic>?)?.cast<String>().toSet() ??
          d.unlocked,
      showFavorites: json['showFavorites'] as bool? ?? d.showFavorites,
      showAchievements: json['showAchievements'] as bool? ?? d.showAchievements,
      showStats: json['showStats'] as bool? ?? d.showStats,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  static const _key = 'profile_v1';

  @override
  ProfileState build() {
    final raw = ref.read(prefsProvider).getString(_key);
    if (raw != null) {
      try {
        return ProfileState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Повреждённые данные: начинаем с чистого профиля.
      }
    }
    return ProfileState.initial();
  }

  void _commit(ProfileState next) {
    state = next;
    ref.read(prefsProvider).setString(_key, jsonEncode(next.toJson()));
  }

  /// Применить любое изменение профиля и сохранить.
  void edit(ProfileState Function(ProfileState current) change) =>
      _commit(change(state));

  /// Начислить очки и опыт (за серии, главы и т. д.).
  void earn(int amount) {
    if (amount <= 0) return;
    _commit(state.copyWith(points: state.points + amount, xp: state.xp + amount));
  }

  /// Купить предмет. Возвращает false, если очков не хватает.
  bool unlock(StoreItem item) {
    if (state.unlocked.contains(item.id)) return true;
    if (state.points < item.price) return false;
    _commit(state.copyWith(
      points: state.points - item.price,
      unlocked: {...state.unlocked, item.id},
    ));
    return true;
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
