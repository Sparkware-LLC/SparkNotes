import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models/note.dart';

const _uuid = Uuid();

class AppState extends ChangeNotifier {
  final SharedPreferences _prefs;

  List<Note> _notes = [];
  ThemeMode _themeMode = ThemeMode.system;
  String _accentKey = 'periwinkle';
  String _defaultNoteColor = 'default';
  double _baseFontSize = 15.0;
  bool _gridView = true;
  bool _hasSeenOnboarding = false;
  double _defaultStrokeWidth = 3.0;

  AppState(this._prefs) {
    _load();
  }

  List<Note> get notes => _notes;
  List<Note> get pinnedNotes => _notes.where((n) => n.isPinned).toList();
  List<Note> get unpinnedNotes => _notes.where((n) => !n.isPinned).toList();
  ThemeMode get themeMode => _themeMode;
  String get accentKey => _accentKey;
  String get defaultNoteColor => _defaultNoteColor;
  double get baseFontSize => _baseFontSize;
  bool get gridView => _gridView;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  double get defaultStrokeWidth => _defaultStrokeWidth;

  List<Note> get textNotes =>
      _notes.where((n) => n.type == NoteType.text).toList();
  List<Note> get todoNotes =>
      _notes.where((n) => n.type == NoteType.todo).toList();
  List<Note> get doodleNotes =>
      _notes.where((n) => n.type == NoteType.doodle).toList();

  List<Note> notesForDay(DateTime day) {
    return _notes.where((n) {
      final d = n.updatedAt;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  List<Note> search(String query) {
    final q = query.toLowerCase();
    return _notes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q) ||
          n.todos.any((t) => t.text.toLowerCase().contains(q));
    }).toList();
  }

  void _load() {
    _hasSeenOnboarding = _prefs.getBool('onboarding') ?? false;
    _themeMode = ThemeMode.values[_prefs.getInt('theme') ?? 0];
    _accentKey = _prefs.getString('accent') ?? 'periwinkle';
    _defaultNoteColor = _prefs.getString('noteColor') ?? 'default';
    _baseFontSize = _prefs.getDouble('fontSize') ?? 15.0;
    _gridView = _prefs.getBool('gridView') ?? true;
    _defaultStrokeWidth = _prefs.getDouble('strokeWidth') ?? 3.0;

    final raw = _prefs.getString('notes');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _notes = list
            .map((e) => Note.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } catch (_) {
        _notes = [];
      }
    }
  }

  Future<void> _saveNotes() async {
    final encoded = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await _prefs.setString('notes', encoded);
  }

  Note addNote(NoteType type, {String? colorHex}) {
    final now = DateTime.now();
    final note = Note(
      id: _uuid.v4(),
      title: '',
      type: type,
      colorHex: colorHex ?? _defaultNoteColor,
      createdAt: now,
      updatedAt: now,
    );
    _notes.insert(0, note);
    _saveNotes();
    notifyListeners();
    return note;
  }

  void updateNote(Note updated) {
    final idx = _notes.indexWhere((n) => n.id == updated.id);
    if (idx == -1) return;
    _notes[idx] = updated;
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    _saveNotes();
    notifyListeners();
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    _saveNotes();
    notifyListeners();
  }

  void togglePin(String id) {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notes[idx].isPinned = !_notes[idx].isPinned;
    _notes.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    _saveNotes();
    notifyListeners();
  }

  // settings

  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
    await _prefs.setBool('onboarding', true);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setInt('theme', mode.index);
    notifyListeners();
  }

  Future<void> setAccent(String key) async {
    _accentKey = key;
    await _prefs.setString('accent', key);
    notifyListeners();
  }

  Future<void> setDefaultNoteColor(String color) async {
    _defaultNoteColor = color;
    await _prefs.setString('noteColor', color);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _baseFontSize = size;
    await _prefs.setDouble('fontSize', size);
    notifyListeners();
  }

  Future<void> setGridView(bool val) async {
    _gridView = val;
    await _prefs.setBool('gridView', val);
    notifyListeners();
  }

  Future<void> setDefaultStrokeWidth(double w) async {
    _defaultStrokeWidth = w;
    await _prefs.setDouble('strokeWidth', w);
    notifyListeners();
  }

  Future<void> clearAllNotes() async {
    _notes = [];
    await _prefs.remove('notes');
    notifyListeners();
  }
}
