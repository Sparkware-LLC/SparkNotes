import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../theme/app_theme.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isDark;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = noteColor(note.colorHex, isDark);
    final isDefault = note.colorHex == 'default';

    // compute text color relative to bg
    final bgLum = bg.computeLuminance();
    final textColor = bgLum > 0.5 ? const Color(0xFF1A1A2E) : Colors.white;
    final subColor = textColor.withOpacity(0.55);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDefault
                ? scheme.outline
                : bg.withOpacity(0.0), // no border for colored notes
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // type chip + pin
            Row(
              children: [
                _TypeBadge(type: note.type, textColor: subColor),
                const Spacer(),
                if (note.isPinned)
                  Icon(Icons.push_pin_rounded, size: 14, color: subColor),
              ],
            ),
            const SizedBox(height: 8),
            // title
            if (note.title.isNotEmpty) ...[
              Text(
                note.title,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
            ],
            // content / preview
            if (note.type == NoteType.doodle)
              _DoodlePreview(note: note, textColor: subColor)
            else if (note.type == NoteType.todo)
              _TodoPreview(note: note, textColor: textColor, subColor: subColor)
            else
              Text(
                note.content,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: subColor,
                  height: 1.5,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 10),
            // date
            Text(
              _formatDate(note.updatedAt),
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: subColor.withOpacity(0.7),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return DateFormat('HH:mm').format(dt);
    }
    if (dt.year == now.year) {
      return DateFormat('MMM d').format(dt);
    }
    return DateFormat('MMM d, y').format(dt);
  }
}

class _TypeBadge extends StatelessWidget {
  final NoteType type;
  final Color textColor;

  const _TypeBadge({required this.type, required this.textColor});

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (type) {
      NoteType.text   => (Icons.notes_rounded, 'note'),
      NoteType.todo   => (Icons.check_circle_outline_rounded, 'todo'),
      NoteType.doodle => (Icons.gesture_rounded, 'doodle'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: textColor),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TodoPreview extends StatelessWidget {
  final Note note;
  final Color textColor;
  final Color subColor;

  const _TodoPreview({required this.note, required this.textColor, required this.subColor});

  @override
  Widget build(BuildContext context) {
    if (note.todos.isEmpty) {
      return Text(
        'No items yet',
        style: GoogleFonts.jetBrainsMono(fontSize: 12, color: subColor),
      );
    }

    final visible = note.todos.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (note.todos.length > 1) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: note.todoProgress,
              backgroundColor: subColor.withOpacity(0.15),
              color: subColor,
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 7),
        ],
        ...visible.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    t.isDone
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 12,
                    color: subColor,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      t.text,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: t.isDone ? subColor : textColor,
                        decoration: t.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )),
        if (note.todos.length > 4)
          Text(
            '+${note.todos.length - 4} more',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: subColor.withOpacity(0.6),
            ),
          ),
      ],
    );
  }
}

class _DoodlePreview extends StatelessWidget {
  final Note note;
  final Color textColor;

  const _DoodlePreview({required this.note, required this.textColor});

  @override
  Widget build(BuildContext context) {
    if (note.strokes.isEmpty) {
      return Text(
        'Empty canvas',
        style: GoogleFonts.jetBrainsMono(fontSize: 12, color: textColor),
      );
    }

    return SizedBox(
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: _MiniDoodlePainter(note.strokes),
        ),
      ),
    );
  }
}

class _MiniDoodlePainter extends CustomPainter {
  final List<DrawStroke> strokes;

  _MiniDoodlePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    // figure out bounding box of all points
    double minX = double.infinity, minY = double.infinity;
    double maxX = 0, maxY = 0;

    for (final stroke in strokes) {
      for (final pt in stroke.points) {
        if (pt.x < minX) minX = pt.x;
        if (pt.y < minY) minY = pt.y;
        if (pt.x > maxX) maxX = pt.x;
        if (pt.y > maxY) maxY = pt.y;
      }
    }

    if (minX == double.infinity) return;

    final scaleX = size.width / (maxX - minX + 1);
    final scaleY = size.height / (maxY - minY + 1);
    final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.9;

    for (final stroke in strokes) {
      if (stroke.isEraser || stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width * scale * 0.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      for (int i = 0; i < stroke.points.length; i++) {
        final pt = stroke.points[i];
        final x = (pt.x - minX) * scale;
        final y = (pt.y - minY) * scale;
        if (i == 0 || pt.isStart) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_MiniDoodlePainter old) => old.strokes != strokes;
}
