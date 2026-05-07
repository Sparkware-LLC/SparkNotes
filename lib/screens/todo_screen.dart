import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

class TodoScreen extends StatefulWidget {
  final Note note;

  const TodoScreen({super.key, required this.note});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late final TextEditingController _titleCtrl;
  late List<TodoItem> _todos;
  late String _colorHex;
  bool _dirty = false;

  final _newItemCtrl = TextEditingController();
  final _newItemFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note.title);
    _todos = widget.note.todos.map((t) => TodoItem(
      id: t.id,
      text: t.text,
      isDone: t.isDone,
    )).toList();
    _colorHex = widget.note.colorHex;
    _titleCtrl.addListener(() => setState(() => _dirty = true));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _newItemCtrl.dispose();
    _newItemFocus.dispose();
    super.dispose();
  }

  void _save() {
    final updated = Note(
      id: widget.note.id,
      title: _titleCtrl.text.trim(),
      type: NoteType.todo,
      colorHex: _colorHex,
      createdAt: widget.note.createdAt,
      updatedAt: DateTime.now(),
      todos: List.of(_todos),
      isPinned: widget.note.isPinned,
    );
    context.read<AppState>().updateNote(updated);
    if (updated.title.isEmpty && updated.todos.isEmpty) {
      context.read<AppState>().deleteNote(updated.id);
    }
  }

  void _addItem(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _todos.add(TodoItem(id: _uuid.v4(), text: text.trim()));
      _dirty = true;
    });
    _newItemCtrl.clear();
  }

  void _toggleItem(int idx) {
    HapticFeedback.selectionClick();
    setState(() {
      _todos[idx] = _todos[idx].copyWith(isDone: !_todos[idx].isDone);
      _dirty = true;
    });
  }

  void _deleteItem(int idx) {
    setState(() {
      _todos.removeAt(idx);
      _dirty = true;
    });
  }

  void _editItem(int idx, String newText) {
    if (newText.trim().isEmpty) {
      _deleteItem(idx);
    } else {
      setState(() {
        _todos[idx] = _todos[idx].copyWith(text: newText.trim());
        _dirty = true;
      });
    }
  }

  void _clearDone() {
    setState(() {
      _todos.removeWhere((t) => t.isDone);
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = noteColor(_colorHex, isDark);
    final bgLum = bg.computeLuminance();
    final onBg = bgLum > 0.5 ? const Color(0xFF1A1A2E) : Colors.white;
    final accent = accentOf(state.accentKey);

    final done = _todos.where((t) => t.isDone).length;
    final total = _todos.length;
    final progress = total == 0 ? 0.0 : done / total;

    final pending = _todos.where((t) => !t.isDone).toList();
    final completed = _todos.where((t) => t.isDone).toList();

    return WillPopScope(
      onWillPop: () async {
        _save();
        return true;
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          iconTheme: IconThemeData(color: onBg),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              _save();
              Navigator.pop(context);
            },
          ),
          actions: [
            if (done > 0)
              TextButton.icon(
                onPressed: _clearDone,
                icon: Icon(Icons.clear_all_rounded, size: 18, color: onBg.withOpacity(0.5)),
                label: Text(
                  'Clear done',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: onBg.withOpacity(0.5),
                  ),
                ),
              ),
            GestureDetector(
              onTap: () => _showColorSheet(context, isDark),
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: noteColor(_colorHex, false),
                  shape: BoxShape.circle,
                  border: Border.all(color: onBg.withOpacity(0.3), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // title + progress
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: state.baseFontSize + 6,
                      fontWeight: FontWeight.w700,
                      color: onBg,
                    ),
                    decoration: InputDecoration(
                      hintText: 'List title',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: state.baseFontSize + 6,
                        fontWeight: FontWeight.w700,
                        color: onBg.withOpacity(0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$done / $total done',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: onBg.withOpacity(0.4),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('MMM d, HH:mm').format(DateTime.now()),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: onBg.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                  if (total > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: onBg.withOpacity(0.1),
                        color: accent,
                        minHeight: 4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // add new item
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 1.5),
                    ),
                    child: Icon(Icons.add_rounded, size: 14, color: accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _newItemCtrl,
                      focusNode: _newItemFocus,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: state.baseFontSize,
                        color: onBg,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add item...',
                        hintStyle: GoogleFonts.jetBrainsMono(
                          fontSize: state.baseFontSize,
                          color: onBg.withOpacity(0.3),
                        ),
                      ),
                      onSubmitted: (v) {
                        _addItem(v);
                        _newItemFocus.requestFocus();
                      },
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: onBg.withOpacity(0.1),
            ),
            // todo list
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: pending.length + (completed.isNotEmpty ? 1 : 0) + completed.length,
                onReorder: (oldIdx, newIdx) {
                  // only reorder within pending
                  if (oldIdx >= pending.length || newIdx > pending.length) return;
                  if (newIdx > oldIdx) newIdx--;
                  setState(() {
                    final item = pending.removeAt(oldIdx);
                    pending.insert(newIdx, item);
                    _todos = [...pending, ...completed];
                    _dirty = true;
                  });
                },
                itemBuilder: (context, idx) {
                  if (idx < pending.length) {
                    final item = pending[idx];
                    return _TodoItemTile(
                      key: ValueKey('p_${item.id}'),
                      item: item,
                      onBg: onBg,
                      accent: accent,
                      fontSize: state.baseFontSize,
                      onToggle: () => _toggleItem(_todos.indexOf(item)),
                      onDelete: () => _deleteItem(_todos.indexOf(item)),
                      onEdit: (t) => _editItem(_todos.indexOf(item), t),
                    );
                  }
                  if (idx == pending.length && completed.isNotEmpty) {
                    return Container(
                      key: const ValueKey('separator'),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Text(
                        'Completed',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: onBg.withOpacity(0.35),
                        ),
                      ),
                    );
                  }
                  final cIdx = idx - pending.length - (completed.isNotEmpty ? 1 : 0);
                  final item = completed[cIdx];
                  return _TodoItemTile(
                    key: ValueKey('c_${item.id}'),
                    item: item,
                    onBg: onBg,
                    accent: accent,
                    fontSize: state.baseFontSize,
                    onToggle: () => _toggleItem(_todos.indexOf(item)),
                    onDelete: () => _deleteItem(_todos.indexOf(item)),
                    onEdit: (t) => _editItem(_todos.indexOf(item), t),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Note color',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: noteLightColors.keys.map((key) {
                  final c = noteColor(key, false);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _colorHex = key;
                        _dirty = true;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _colorHex == key
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFFDDDDE8),
                          width: _colorHex == key ? 2.5 : 1,
                        ),
                      ),
                      child: _colorHex == key
                          ? const Icon(Icons.check_rounded, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoItemTile extends StatefulWidget {
  final TodoItem item;
  final Color onBg;
  final Color accent;
  final double fontSize;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  const _TodoItemTile({
    super.key,
    required this.item,
    required this.onBg,
    required this.accent,
    required this.fontSize,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_TodoItemTile> createState() => _TodoItemTileState();
}

class _TodoItemTileState extends State<_TodoItemTile> {
  bool _editing = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.item.text);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.onBg.withOpacity(widget.item.isDone ? 0.35 : 0.85);

    return Dismissible(
      key: ValueKey('d_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline_rounded,
            color: Colors.red.shade400, size: 22),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // checkbox
            GestureDetector(
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.only(top: 2, right: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.item.isDone
                          ? widget.accent
                          : widget.onBg.withOpacity(0.3),
                      width: 1.5,
                    ),
                    color: widget.item.isDone ? widget.accent : Colors.transparent,
                  ),
                  child: widget.item.isDone
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white)
                      : null,
                ),
              ),
            ),
            // text / edit
            Expanded(
              child: _editing
                  ? TextField(
                      controller: _ctrl,
                      autofocus: true,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: widget.fontSize,
                        color: widget.onBg,
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(),
                      onSubmitted: (v) {
                        setState(() => _editing = false);
                        widget.onEdit(v);
                      },
                      onEditingComplete: () {
                        setState(() => _editing = false);
                        widget.onEdit(_ctrl.text);
                      },
                    )
                  : GestureDetector(
                      onDoubleTap: () => setState(() => _editing = true),
                      child: Text(
                        widget.item.text,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: widget.fontSize,
                          color: sub,
                          height: 1.5,
                          decoration: widget.item.isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: sub,
                        ),
                      ),
                    ),
            ),
            // drag handle
            ReorderableDragStartListener(
              index: 0,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(
                  Icons.drag_handle_rounded,
                  size: 18,
                  color: widget.onBg.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
