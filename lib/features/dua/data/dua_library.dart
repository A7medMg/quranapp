import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DuaCategory {
  const DuaCategory({
    required this.id,
    required this.title,
    required this.icon,
  });

  final String id;
  final String title;
  final IconData icon;
}

class DuaEntry {
  const DuaEntry({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryTitle,
    required this.whenToSay,
    required this.text,
    required this.source,
    required this.kind,
  });

  factory DuaEntry.fromJson(Map<String, dynamic> json) => DuaEntry(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    categoryId: json['categoryId'] as String? ?? 'other',
    categoryTitle: json['categoryTitle'] as String? ?? 'أدعية متنوعة',
    whenToSay: json['whenToSay'] as String? ?? '',
    text: json['text'] as String? ?? '',
    source: json['source'] as String? ?? 'لم يذكر المرجع في المصدر',
    kind: json['kind'] as String? ?? 'dua',
  );

  final String id;
  final String title;
  final String categoryId;
  final String categoryTitle;
  final String whenToSay;
  final String text;
  final String source;
  final String kind;

  bool get isDhikr => kind == 'adhkar' || kind == 'both';

  bool get isDua => kind == 'dua' || kind == 'both';
}

abstract final class DuaLibrary {
  static List<DuaEntry>? _cache;
  static Future<List<DuaEntry>>? _pending;

  static Future<List<DuaEntry>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final pending = _pending;
    if (pending != null) return pending;

    final future = _read();
    _pending = future;
    try {
      return await future;
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }

  static Future<List<DuaEntry>> _read() async {
    final source = await rootBundle.loadString(
      'assets/files/dua_adhkar_source.json',
    );
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final values = decoded['entries'] as List<dynamic>;
    final entries = values
        .whereType<Map<String, dynamic>>()
        .map(DuaEntry.fromJson)
        .where((entry) => entry.text.trim().isNotEmpty)
        .toList(growable: false);
    _cache = entries;
    return entries;
  }

  static List<DuaCategory> categoriesFor(Iterable<DuaEntry> entries) {
    final categories = <String, DuaCategory>{};
    for (final entry in entries) {
      categories.putIfAbsent(
        entry.categoryTitle,
        () => DuaCategory(
          id: entry.categoryTitle,
          title: entry.categoryTitle,
          icon: _iconFor(entry.categoryId),
        ),
      );
    }
    return categories.values.toList(growable: false);
  }

  static IconData _iconFor(String categoryId) {
    final key = categoryId.toLowerCase();
    if (key.contains('morning') || key.contains('evening')) {
      return Icons.wb_twilight_rounded;
    }
    if (key.contains('sleep')) return Icons.bedtime_rounded;
    if (key.contains('travel')) return Icons.directions_car_filled_rounded;
    if (key.contains('mosque') || key.contains('salah')) {
      return Icons.mosque_rounded;
    }
    if (key.contains('food')) return Icons.restaurant_rounded;
    if (key.contains('home')) return Icons.home_outlined;
    if (key.contains('sickness')) return Icons.healing_rounded;
    return Icons.auto_awesome_rounded;
  }
}