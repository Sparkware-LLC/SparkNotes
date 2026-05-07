import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note note;

  const NoteEditorScreen({super.key, required this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late String _colorHex;
  bool _dirty = false;
  bool _showToolbar = false;

  final _bodyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.note.title);
    _bodyCtrl = TextEditingController(text: widget.note.content);
    _colorHex = widget.note.colorHex;

    _titleCtrl.addListener(_markDirty);
    _bodyCtrl.addListener(_markDirty);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _markDirty() => setState(() => _dirty = true);

  void _save() {
    if (!_dirty &&
        _colorHex == widget.note.colorHex &&
        _titleCtrl.text == widget.note.title &&
        _bodyCtrl.text == widget.note.content) return;

    final updated = Note(
      id: widget.note.id,
      title: _titleCtrl.text.trim(),
      content: _bodyCtrl.text,
      type: NoteType.text,
      colorHex: _colorHex,
      createdAt: widget.note.createdAt,
      updatedAt: DateTime.now(),
      isPinned: widget.note.isPinned,
    );

    context.read<AppState>().updateNote(updated);

    // delete if empty
    if (updated.title.isEmpty && updated.content.isEmpty) {
      context.read<AppState>().deleteNote(updated.id);
    }
  }

  void _insertText(String before, String after) {
    final sel = _bodyCtrl.selection;
    final text = _bodyCtrl.text;
    if (sel.isValid && sel.start != sel.end) {
      final selected = sel.textInside(text);
      final newText =
          text.replaceRange(sel.start, sel.end, '$before$selected$after');
      _bodyCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: sel.start + before.length + selected.length + after.length,
        ),
      );
    } else {
      final offset = sel.isValid ? sel.baseOffset : text.length;
      final newText =
          text.substring(0, offset) + before + after + text.substring(offset);
      _bodyCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: offset + before.length),
      );
    }
    _markDirty();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = noteColor(_colorHex, isDark);
    final bgLum = bg.computeLuminance();
    final onBg = bgLum > 0.5 ? const Color(0xFF1A1A2E) : Colors.white;
    final scheme = Theme.of(context).colorScheme;
    final accent = accentOf(state.accentKey);

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
            // toolbar toggle
            IconButton(
              icon: Icon(
                Icons.text_format_rounded,
                color: _showToolbar ? accent : onBg.withOpacity(0.6),
              ),
              onPressed: () => setState(() => _showToolbar = !_showToolbar),
            ),
            // color
            GestureDetector(
              onTap: () => _showColorSheet(context, isDark),
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: noteColor(_colorHex, false),
                  shape: BoxShape.circle,
                  border: Border.all(color: onBg.withOpacity(0.3), width: 1.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // formatting toolbar
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _showToolbar
                  ? _FormatToolbar(
                      onBold: () => _insertText('**', '**'),
                      onItalic: () => _insertText('_', '_'),
                      onCode: () => _insertText('`', '`'),
                      onBullet: () => _insertText('\n• ', ''),
                      onNumber: () => _insertText('\n1. ', ''),
                      accent: accent,
                      onBg: onBg,
                    )
                  : const SizedBox.shrink(),
            ),
            // editor
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: state.baseFontSize + 5,
                        fontWeight: FontWeight.w700,
                        color: onBg,
                        height: 1.3,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: GoogleFonts.jetBrainsMono(
                          fontSize: state.baseFontSize + 5,
                          fontWeight: FontWeight.w700,
                          color: onBg.withOpacity(0.3),
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _bodyFocus.requestFocus(),
                    ),
                    Text(
                      DateFormat('EEE, MMM d · HH:mm')
                          .format(widget.note.updatedAt),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: onBg.withOpacity(0.35),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bodyCtrl,
                      focusNode: _bodyFocus,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: state.baseFontSize,
                        color: onBg,
                        height: 1.65,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start writing...',
                        hintStyle: GoogleFonts.jetBrainsMono(
                          fontSize: state.baseFontSize,
                          color: onBg.withOpacity(0.3),
                          height: 1.65,
                        ),
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ),
            // word count footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: bg,
              child: Row(
                children: [
                  Text(
                    _wordCount(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: onBg.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _wordCount() {
    final words = _bodyCtrl.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    final chars = _bodyCtrl.text.length;
    return '$words words · $chars chars';
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

class _FormatToolbar extends StatelessWidget {
  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onCode;
  final VoidCallback onBullet;
  final VoidCallback onNumber;
  final Color accent;
  final Color onBg;

  const _FormatToolbar({
    required this.onBold,
    required this.onItalic,
    required this.onCode,
    required this.onBullet,
    required this.onNumber,
    required this.accent,
    required this.onBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: onBg.withOpacity(0.1)),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _ToolBtn(icon: Icons.format_bold_rounded, onTap: onBold, color: onBg),
          _ToolBtn(icon: Icons.format_italic_rounded, onTap: onItalic, color: onBg),
          _ToolBtn(icon: Icons.code_rounded, onTap: onCode, color: onBg),
          const _Divider(),
          _ToolBtn(icon: Icons.format_list_bulleted_rounded, onTap: onBullet, color: onBg),
          _ToolBtn(icon: Icons.format_list_numbered_rounded, onTap: onNumber, color: onBg),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _ToolBtn({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color.withOpacity(0.7)),
      onPressed: onTap,
      splashRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Colors.white.withOpacity(0.15),
      ),
    );
  }
}
