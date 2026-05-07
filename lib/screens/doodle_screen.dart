import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class DoodleScreen extends StatefulWidget {
  final Note note;

  const DoodleScreen({super.key, required this.note});

  @override
  State<DoodleScreen> createState() => _DoodleScreenState();
}

class _DoodleScreenState extends State<DoodleScreen> {
  late final TextEditingController _titleCtrl;
  late List<DrawStroke> _strokes;
  final List<List<DrawStroke>> _undoStack = [];

  Color _penColor = const Color(0xFF1A1A2E);
  double _strokeWidth = 3.0;
  bool _isEraser = false;
  bool _drawing = false;

  static const _colors = [
    Color(0xFF1A1A2E),
    Color(0xFF8B8FF4),
    Color(0xFFEF4444),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFF0EA5E9),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFFFFFFF),
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note.title);
    _strokes = List.of(widget.note.strokes);
    _strokeWidth = context.read<AppState>().defaultStrokeWidth;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final updated = Note(
      id: widget.note.id,
      title: _titleCtrl.text.trim(),
      type: NoteType.doodle,
      colorHex: widget.note.colorHex,
      createdAt: widget.note.createdAt,
      updatedAt: DateTime.now(),
      strokes: List.of(_strokes),
      isPinned: widget.note.isPinned,
    );
    context.read<AppState>().updateNote(updated);
    if (updated.title.isEmpty && updated.strokes.isEmpty) {
      context.read<AppState>().deleteNote(updated.id);
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    setState(() => _strokes = _undoStack.removeLast());
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear canvas?',
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600)),
        content: Text('This will erase all strokes.',
            style: GoogleFonts.jetBrainsMono(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _undoStack.add(List.of(_strokes));
                _strokes.clear();
              });
            },
            child: Text('Clear',
                style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails d) {
    _undoStack.add(List.of(_strokes));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    setState(() {
      _drawing = true;
      _strokes.add(DrawStroke(
        colorValue: _isEraser ? 0xFFFFFFFF : _penColor.value,
        width: _isEraser ? _strokeWidth * 3 : _strokeWidth,
        isEraser: _isEraser,
        points: [DrawPoint(d.localPosition.dx, d.localPosition.dy, isStart: true)],
      ));
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_drawing || _strokes.isEmpty) return;
    setState(() {
      _strokes.last.points.add(
        DrawPoint(d.localPosition.dx, d.localPosition.dy),
      );
    });
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() => _drawing = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final accent = accentOf(state.accentKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canvasColor = isDark ? const Color(0xFF1A1A28) : Colors.white;

    return WillPopScope(
      onWillPop: () async {
        _save();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              _save();
              Navigator.pop(context);
            },
          ),
          title: SizedBox(
            width: 180,
            child: TextField(
              controller: _titleCtrl,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Untitled doodle',
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 15,
                  color: scheme.onBackground.withOpacity(0.35),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.undo_rounded,
                color: _undoStack.isNotEmpty
                    ? scheme.onBackground
                    : scheme.onBackground.withOpacity(0.25),
              ),
              onPressed: _undoStack.isNotEmpty ? _undo : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: _strokes.isNotEmpty
                  ? Colors.red.shade400
                  : scheme.onBackground.withOpacity(0.25),
              onPressed: _strokes.isNotEmpty ? _clear : null,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // canvas
            Expanded(
              child: ClipRect(
                child: Container(
                  color: canvasColor,
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: _DoodlePainter(
                        strokes: _strokes,
                        canvasColor: canvasColor,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
            // toolbar
            _DoodleToolbar(
              penColor: _penColor,
              strokeWidth: _strokeWidth,
              isEraser: _isEraser,
              colors: _colors,
              accent: accent,
              scheme: scheme,
              isDark: isDark,
              onColorSelect: (c) => setState(() {
                _penColor = c;
                _isEraser = false;
              }),
              onWidthChange: (w) => setState(() => _strokeWidth = w),
              onToggleEraser: () => setState(() => _isEraser = !_isEraser),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final List<DrawStroke> strokes;
  final Color canvasColor;

  _DoodlePainter({required this.strokes, required this.canvasColor});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.isEraser ? canvasColor : stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < stroke.points.length; i++) {
        final pt = stroke.points[i];
        if (i == 0 || pt.isStart) {
          path.moveTo(pt.x, pt.y);
        } else {
          // smooth curve through midpoints
          if (i < stroke.points.length - 1) {
            final curr = stroke.points[i];
            final next = stroke.points[i + 1];
            final mx = (curr.x + next.x) / 2;
            final my = (curr.y + next.y) / 2;
            path.quadraticBezierTo(curr.x, curr.y, mx, my);
          } else {
            path.lineTo(pt.x, pt.y);
          }
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) =>
      old.strokes != strokes || old.canvasColor != canvasColor;
}

class _DoodleToolbar extends StatelessWidget {
  final Color penColor;
  final double strokeWidth;
  final bool isEraser;
  final List<Color> colors;
  final Color accent;
  final ColorScheme scheme;
  final bool isDark;
  final ValueChanged<Color> onColorSelect;
  final ValueChanged<double> onWidthChange;
  final VoidCallback onToggleEraser;

  const _DoodleToolbar({
    required this.penColor,
    required this.strokeWidth,
    required this.isEraser,
    required this.colors,
    required this.accent,
    required this.scheme,
    required this.isDark,
    required this.onColorSelect,
    required this.onWidthChange,
    required this.onToggleEraser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // stroke width slider
              Row(
                children: [
                  Icon(Icons.edit_rounded, size: 14, color: scheme.onSurface.withOpacity(0.4)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        trackHeight: 3,
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: accent,
                        inactiveTrackColor: scheme.outline,
                        thumbColor: accent,
                      ),
                      child: Slider(
                        value: strokeWidth,
                        min: 1.0,
                        max: 20.0,
                        onChanged: onWidthChange,
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEraser ? Colors.white : penColor,
                      border: Border.all(
                        color: scheme.outline,
                        width: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // color row + eraser
              Row(
                children: [
                  // eraser
                  GestureDetector(
                    onTap: onToggleEraser,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isEraser
                            ? accent.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isEraser ? accent : scheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.auto_fix_normal_rounded,
                        size: 18,
                        color: isEraser ? accent : scheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // color swatches
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: colors.map((c) {
                          final selected = !isEraser && penColor == c;
                          return GestureDetector(
                            onTap: () => onColorSelect(c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: selected ? 34 : 28,
                              height: selected ? 34 : 28,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected ? accent : scheme.outline,
                                  width: selected ? 2.5 : 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
