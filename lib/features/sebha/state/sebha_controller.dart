import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quran_app/features/sebha/data/sebha_dhikr.dart';

class SebhaController extends ChangeNotifier {
  static const _selectedDhikrKey = 'sebha_selected_dhikr';
  static const _countKeyPrefix = 'sebha_count_';
  static const _defaultDhikrId = 'subhan_allah';

  final Map<String, int> _counts = {
    for (final dhikr in SebhaDhikrList.items) dhikr.id: 0,
  };
  Future<void> _writeQueue = Future<void>.value();
  String _selectedDhikrId = _defaultDhikrId;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<SebhaDhikr> get dhikrs => SebhaDhikrList.items;
  String get selectedDhikrId => _selectedDhikrId;

  SebhaDhikr get selectedDhikr => SebhaDhikrList.items.firstWhere(
    (dhikr) => dhikr.id == _selectedDhikrId,
  );

  int get selectedCount => _counts[_selectedDhikrId] ?? 0;

  int countFor(String dhikrId) => _counts[dhikrId] ?? 0;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final preferences = await SharedPreferences.getInstance();
      final savedDhikrId = preferences.getString(_selectedDhikrKey);
      if (savedDhikrId != null &&
          SebhaDhikrList.items.any((dhikr) => dhikr.id == savedDhikrId)) {
        _selectedDhikrId = savedDhikrId;
      }

      for (final dhikr in SebhaDhikrList.items) {
        _counts[dhikr.id] =
            preferences.getInt('$_countKeyPrefix${dhikr.id}') ?? 0;
      }
    } catch (_) {
      // Keep the counters usable in memory if local storage is unavailable.
    }

    _isLoaded = true;
    notifyListeners();
  }

  void selectDhikr(String dhikrId) {
    if (!_isLoaded || _selectedDhikrId == dhikrId) return;
    if (!SebhaDhikrList.items.any((dhikr) => dhikr.id == dhikrId)) return;

    _selectedDhikrId = dhikrId;
    notifyListeners();
    _persistSelectedState();
  }

  void increment() {
    if (!_isLoaded) return;
    _counts[_selectedDhikrId] = selectedCount + 1;
    notifyListeners();
    _persistSelectedState();
  }

  void resetSelected() {
    if (!_isLoaded || selectedCount == 0) return;
    _counts[_selectedDhikrId] = 0;
    notifyListeners();
    _persistSelectedState();
  }

  void _persistSelectedState() {
    final selectedId = _selectedDhikrId;
    final count = _counts[selectedId] ?? 0;
    _writeQueue = _writeQueue.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setInt('$_countKeyPrefix$selectedId', count);
        await preferences.setString(_selectedDhikrKey, selectedId);
      } catch (_) {
        // Retain the latest count in memory for this session.
      }
    });
  }
}
