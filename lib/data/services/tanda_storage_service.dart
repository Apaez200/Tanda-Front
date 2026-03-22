import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A locally saved tanda reference.
class SavedTanda {
  final String contractId;
  final String name;
  final String role; // 'admin' | 'member'
  final DateTime joinedAt;

  const SavedTanda({
    required this.contractId,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
        'contractId': contractId,
        'name': name,
        'role': role,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory SavedTanda.fromJson(Map<String, dynamic> json) => SavedTanda(
        contractId: json['contractId'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        joinedAt: DateTime.parse(json['joinedAt'] as String),
      );
}

/// Persists tanda references to SharedPreferences.
class TandaStorageService {
  static const _key = 'tanda_saved_list';
  static const _activeKey = 'tanda_active_id';

  Future<List<SavedTanda>> getSavedTandas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => SavedTanda.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveTanda(SavedTanda tanda) async {
    final tandas = await getSavedTandas();
    // Don't duplicate
    tandas.removeWhere((t) => t.contractId == tanda.contractId);
    tandas.insert(0, tanda);
    await _persist(tandas);
  }

  Future<void> removeTanda(String contractId) async {
    final tandas = await getSavedTandas();
    tandas.removeWhere((t) => t.contractId == contractId);
    await _persist(tandas);
  }

  Future<void> setActiveTanda(String contractId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, contractId);
  }

  Future<String?> getActiveTandaId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey);
  }

  Future<void> _persist(List<SavedTanda> tandas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(tandas.map((t) => t.toJson()).toList()));
  }
}
