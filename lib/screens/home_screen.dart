import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import 'todo_screen.dart';
import 'doodle_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  bool _fabOpen = false;
  bool _searching = false;
  String _searchQuery = '';
  String _filter = 'all'; // all | text | todo | doodle

  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  late final AnimationController _fabCtrl;
  late final Animation<double> _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fabAnim = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    if (_fabOpen) {
      _fabCtrl.forward();
    } else {
      _fabCtrl.reverse();
    }
  }

  void _closeFab() {
    if (_fabOpen) {
      setState(() => _fabOpen = false);
      _fabCtrl.reverse();
    }
  }

  void _openNote(BuildContext context, Note note) {
    _closeFab();
    switch (note.type) {
      case NoteType.text:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
        );
      case NoteType.todo:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TodoScreen(note: note)),
        );
      case NoteType.doodle:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoodleScreen(note: note)),
        );
    }
  }

  void _createNote(BuildContext context, NoteType type) {
    _closeFab();
    final note = context.read<AppState>().addNote(type);
    _openNote(context, note);
  }

  void _showNoteOptions(BuildContext context, Note note) {
    final state = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _NoteOptionsSheet(
        note: note,
        onPin: () {
          Navigator.pop(ctx);
          state.togglePin(note.id);
        },
        onDelete: () {
          Navigator.pop(ctx);
          state.deleteNote(note.id);
        },
        onChangeColor: () {
          Navigator.pop(ctx);
          _showColorPicker(context, note);
        },
      ),
    );
  }

  void _showColorPicker(BuildContext context, Note note) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Note color',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600),
        ),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: noteLightColors.keys.map((key) {
            final c = noteColor(key, isDark);
            return GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                state.updateNote(
                  Note(
                    id: note.id,
                    title: note.title,
                    content: note.content,
                    type: note.type,
                    colorHex: key,
                    createdAt: note.createdAt,
                    updatedAt: note.updatedAt,
                    todos: note.todos,
                    strokes: note.strokes,
                    isPinned: note.isPinned,
                  ),
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: note.colorHex == key
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: note.colorHex == key ? 2 : 1,
                  ),
                ),
                child: note.colorHex == key
                    ? const Center(
                        child: Icon(Icons.check_rounded, size: 18))
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final accent = accentOf(state.accentKey);

    Widget body;
    switch (_navIndex) {
      case 0:
        body = _NotesTab(
          state: state,
          isDark: isDark,
          searching: _searching,
          searchQuery: _searchQuery,
          filter: _filter,
          onOpenNote: (n) => _openNote(context, n),
          onLongPress: (n) => _showNoteOptions(context, n),
          onFilterChange: (f) => setState(() => _filter = f),
        );
      case 1:
        body = CalendarScreen(
          onOpenNote: (n) => _openNote(context, n),
        );
      case 2:
        body = const SettingsScreen();
      default:
        body = const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _closeFab,
      child: Scaffold(
        appBar: _navIndex == 0
            ? _buildNotesAppBar(scheme, accent)
            : _navIndex == 1
                ? _buildSimpleAppBar('Calendar', scheme)
                : _buildSimpleAppBar('Settings', scheme),
        body: body,
        bottomNavigationBar: _buildBottomNav(scheme, accent),
        floatingActionButton: _navIndex == 0
            ? _buildFab(context, accent)
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildNotesAppBar(ColorScheme scheme, Color accent) {
    return AppBar(
      titleSpacing: 20,
      title: _searching
          ? TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              autofocus: true,
              style: GoogleFonts.jetBrainsMono(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 15,
                  color: scheme.onBackground.withOpacity(0.4),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            )
          : Row(
              children: [
                Image.asset('assets/SparkNotes-Logo-removed-bg.png', width: 28, height: 28),
                const SizedBox(width: 8),
                Text(
                  'SparkNotes',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
      actions: [
        IconButton(
          icon: Icon(
            _searching ? Icons.close_rounded : Icons.search_rounded,
            size: 22,
          ),
          onPressed: () {
            setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchQuery = '';
                _searchCtrl.clear();
              }
            });
          },
        ),
        const SizedBox(width: 4),
        Builder(
          builder: (ctx) => IconButton(
            icon: Icon(
              context.read<AppState>().gridView
                  ? Icons.view_list_rounded
                  : Icons.grid_view_rounded,
              size: 22,
            ),
            onPressed: () =>
                context.read<AppState>().setGridView(!context.read<AppState>().gridView),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PreferredSizeWidget _buildSimpleAppBar(String title, ColorScheme scheme) {
    return AppBar(
      titleSpacing: 20,
      title: Text(
        title,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBottomNav(ColorScheme scheme, Color accent) {
    return NavigationBar(
      selectedIndex: _navIndex,
      onDestinationSelected: (i) {
        _closeFab();
        setState(() => _navIndex = i);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.notes_rounded),
          label: 'Notes',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_rounded),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_rounded),
          label: 'Settings',
        ),
      ],
    );
  }

  Widget _buildFab(BuildContext context, Color accent) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // speed dial items
        AnimatedBuilder(
          animation: _fabAnim,
          builder: (ctx, _) {
            if (_fabAnim.value == 0) return const SizedBox.shrink();
            return Opacity(
              opacity: _fabAnim.value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - _fabAnim.value)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _FabItem(
                      label: 'Doodle',
                      icon: Icons.gesture_rounded,
                      color: accent,
                      onTap: () => _createNote(context, NoteType.doodle),
                    ),
                    const SizedBox(height: 10),
                    _FabItem(
                      label: 'Todo list',
                      icon: Icons.check_circle_outline_rounded,
                      color: accent,
                      onTap: () => _createNote(context, NoteType.todo),
                    ),
                    const SizedBox(height: 10),
                    _FabItem(
                      label: 'Text note',
                      icon: Icons.edit_note_rounded,
                      color: accent,
                      onTap: () => _createNote(context, NoteType.text),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            );
          },
        ),
        // main FAB
        FloatingActionButton(
          onPressed: _toggleFab,
          child: AnimatedRotation(
            turns: _fabOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }
}

class _FabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FabItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: scheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Notes Tab ──────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final bool searching;
  final String searchQuery;
  final String filter;
  final ValueChanged<Note> onOpenNote;
  final ValueChanged<Note> onLongPress;
  final ValueChanged<String> onFilterChange;

  const _NotesTab({
    required this.state,
    required this.isDark,
    required this.searching,
    required this.searchQuery,
    required this.filter,
    required this.onOpenNote,
    required this.onLongPress,
    required this.onFilterChange,
  });

  List<Note> get _displayNotes {
    List<Note> list;
    if (searching && searchQuery.isNotEmpty) {
      list = state.search(searchQuery);
    } else {
      list = switch (filter) {
        'text'   => state.textNotes,
        'todo'   => state.todoNotes,
        'doodle' => state.doodleNotes,
        _        => state.notes,
      };
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final notes = _displayNotes;

    return Column(
      children: [
        // filter chips
        if (!searching) ...[
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                for (final (key, label) in [
                  ('all', 'All'),
                  ('text', 'Notes'),
                  ('todo', 'Todos'),
                  ('doodle', 'Doodles'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label),
                      selected: filter == key,
                      onSelected: (_) => onFilterChange(key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
        // notes grid
        Expanded(
          child: notes.isEmpty
              ? _EmptyState(searching: searching, filter: filter)
              : state.gridView
                  ? _NoteGrid(
                      notes: notes,
                      isDark: isDark,
                      onTap: onOpenNote,
                      onLongPress: onLongPress,
                    )
                  : _NoteList(
                      notes: notes,
                      isDark: isDark,
                      onTap: onOpenNote,
                      onLongPress: onLongPress,
                    ),
        ),
      ],
    );
  }
}

class _NoteGrid extends StatelessWidget {
  final List<Note> notes;
  final bool isDark;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;

  const _NoteGrid({
    required this.notes,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Split pinned and unpinned
    final pinned = notes.where((n) => n.isPinned).toList();
    final rest = notes.where((n) => !n.isPinned).toList();

    return CustomScrollView(
      slivers: [
        if (pinned.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'PINNED',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            sliver: _SliverNoteGrid(
              notes: pinned,
              isDark: isDark,
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'OTHERS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: _SliverNoteGrid(
            notes: rest,
            isDark: isDark,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ],
    );
  }
}

class _SliverNoteGrid extends StatelessWidget {
  final List<Note> notes;
  final bool isDark;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;

  const _SliverNoteGrid({
    required this.notes,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, i) => NoteCard(
          note: notes[i],
          isDark: isDark,
          onTap: () => onTap(notes[i]),
          onLongPress: () => onLongPress(notes[i]),
        ),
        childCount: notes.length,
      ),
    );
  }
}

class _NoteList extends StatelessWidget {
  final List<Note> notes;
  final bool isDark;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;

  const _NoteList({
    required this.notes,
    required this.isDark,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => NoteCard(
        note: notes[i],
        isDark: isDark,
        onTap: () => onTap(notes[i]),
        onLongPress: () => onLongPress(notes[i]),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool searching;
  final String filter;

  const _EmptyState({required this.searching, required this.filter});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            searching ? Icons.search_off_rounded : Icons.sticky_note_2_outlined,
            size: 56,
            color: scheme.onBackground.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            searching ? 'No results found' : 'Nothing here yet',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: scheme.onBackground.withOpacity(0.35),
            ),
          ),
          if (!searching) ...[
            const SizedBox(height: 6),
            Text(
              'Tap + to create your first note',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: scheme.onBackground.withOpacity(0.25),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Note Options Bottom Sheet ───────────────────────────────────────────────

class _NoteOptionsSheet extends StatelessWidget {
  final Note note;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onChangeColor;

  const _NoteOptionsSheet({
    required this.note,
    required this.onPin,
    required this.onDelete,
    required this.onChangeColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // drag handle
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: scheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                note.title.isNotEmpty ? note.title : 'Untitled',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                note.isPinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
              ),
              title: Text(
                note.isPinned ? 'Unpin note' : 'Pin note',
                style: GoogleFonts.jetBrainsMono(fontSize: 14),
              ),
              onTap: onPin,
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(
                'Change color',
                style: GoogleFonts.jetBrainsMono(fontSize: 14),
              ),
              onTap: onChangeColor,
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded,
                  color: Colors.red.shade400),
              title: Text(
                'Delete note',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  color: Colors.red.shade400,
                ),
              ),
              onTap: onDelete,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
