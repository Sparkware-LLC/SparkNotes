import 'dart:ui';

enum NoteType { text, todo, doodle }

class TodoItem {
  final String id;
  String text;
  bool isDone;

  TodoItem({required this.id, required this.text, this.isDone = false});

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'isDone': isDone};

  factory TodoItem.fromJson(Map<String, dynamic> j) => TodoItem(
        id: j['id'] as String,
        text: j['text'] as String,
        isDone: j['isDone'] as bool? ?? false,
      );

  TodoItem copyWith({String? text, bool? isDone}) =>
      TodoItem(id: id, text: text ?? this.text, isDone: isDone ?? this.isDone);
}

class DrawPoint {
  final double x;
  final double y;
  final bool isStart;

  const DrawPoint(this.x, this.y, {this.isStart = false});

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 's': isStart};

  factory DrawPoint.fromJson(Map<String, dynamic> j) =>
      DrawPoint((j['x'] as num).toDouble(), (j['y'] as num).toDouble(),
          isStart: j['s'] as bool? ?? false);
}

class DrawStroke {
  final int colorValue;
  final double width;
  final bool isEraser;
  final List<DrawPoint> points;

  const DrawStroke({
    required this.colorValue,
    required this.width,
    required this.points,
    this.isEraser = false,
  });

  Color get color => Color(colorValue);

  Map<String, dynamic> toJson() => {
        'c': colorValue,
        'w': width,
        'e': isEraser,
        'pts': points.map((p) => p.toJson()).toList(),
      };

  factory DrawStroke.fromJson(Map<String, dynamic> j) => DrawStroke(
        colorValue: j['c'] as int,
        width: (j['w'] as num).toDouble(),
        isEraser: j['e'] as bool? ?? false,
        points: (j['pts'] as List)
            .map((p) => DrawPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class Note {
  final String id;
  String title;
  String content;
  NoteType type;
  String colorHex;
  DateTime createdAt;
  DateTime updatedAt;
  List<TodoItem> todos;
  List<DrawStroke> strokes;
  bool isPinned;

  Note({
    required this.id,
    required this.title,
    this.content = '',
    this.type = NoteType.text,
    this.colorHex = 'default',
    required this.createdAt,
    required this.updatedAt,
    List<TodoItem>? todos,
    List<DrawStroke>? strokes,
    this.isPinned = false,
  })  : todos = todos ?? [],
        strokes = strokes ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type.name,
        'colorHex': colorHex,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'todos': todos.map((t) => t.toJson()).toList(),
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'isPinned': isPinned,
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: j['title'] as String,
        content: j['content'] as String? ?? '',
        type: NoteType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => NoteType.text,
        ),
        colorHex: j['colorHex'] as String? ?? 'default',
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
        todos: (j['todos'] as List? ?? [])
            .map((t) => TodoItem.fromJson(t as Map<String, dynamic>))
            .toList(),
        strokes: (j['strokes'] as List? ?? [])
            .map((s) => DrawStroke.fromJson(s as Map<String, dynamic>))
            .toList(),
        isPinned: j['isPinned'] as bool? ?? false,
      );

  int get completedTodos => todos.where((t) => t.isDone).length;
  double get todoProgress =>
      todos.isEmpty ? 0.0 : completedTodos / todos.length;

  String get previewText {
    if (type == NoteType.todo) {
      if (todos.isEmpty) return 'Empty checklist';
      return todos.map((t) => '${t.isDone ? '✓' : '○'} ${t.text}').join('\n');
    }
    if (type == NoteType.doodle) return '✎ Doodle';
    return content;
  }
}
