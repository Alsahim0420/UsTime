import 'dart:async';

import 'package:flutter/material.dart';

import '../data/spaces_repository.dart';
import '../models/space.dart';

/// The signed-in user's lists and settings.
class AccountController extends ChangeNotifier {
  AccountController(this.uid, this._repository);

  final String uid;
  final SpacesRepository _repository;

  StreamSubscription<UserPrefs>? _prefsSubscription;
  StreamSubscription<List<Space>>? _spacesSubscription;

  UserPrefs? _prefs;
  List<Space>? _spaces;
  Object? _error;

  bool get loading => _error == null && (_prefs == null || _spaces == null);
  Object? get error => _error;

  List<Space> get spaces => _spaces ?? const [];

  /// The list being shown: the one the user picked, or their first one.
  Space? get activeSpace {
    final spaces = this.spaces;
    if (spaces.isEmpty) return null;
    final activeId = _prefs?.activeSpaceId;
    return spaces.firstWhere((s) => s.id == activeId, orElse: () => spaces[0]);
  }

  ThemeMode get themeMode => switch (_prefs?.theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  void start() {
    void fail(Object error) {
      _error = error;
      notifyListeners();
    }

    _prefsSubscription = _repository.watchPrefs(uid).listen((prefs) {
      _prefs = prefs;
      notifyListeners();
    }, onError: fail);
    _spacesSubscription = _repository.watchSpaces(uid).listen((spaces) {
      _spaces = spaces;
      notifyListeners();
    }, onError: fail);
  }

  Future<void> createSpace(String name) => _repository.createSpace(uid, name);

  /// Throws [SpaceNotFound] if no list has that code.
  Future<void> joinSpace(String code) => _repository.joinSpace(uid, code);

  Future<void> selectSpace(Space space) =>
      _repository.setActiveSpace(uid, space.id);

  Future<void> setThemeMode(ThemeMode mode) {
    return _repository.setTheme(uid, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => null,
    });
  }

  @override
  void dispose() {
    _prefsSubscription?.cancel();
    _spacesSubscription?.cancel();
    super.dispose();
  }
}
