import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../models/note.dart';
import '../theme/app_theme.dart';
import '../widgets/note_card.dart';

class CalendarScreen extends StatefulWidget {
  final ValueChanged<Note>? onOpenNote;

  const CalendarScreen({super.key, this.onOpenNote});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final accent = accentOf(state.accentKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final todayNotes = state.notesForDay(_selectedDay);
    final totalNotes = state.notes.length;

    return Column(
      children: [
        // stats strip
        Container(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Row(
            children: [
              _StatPill(
                label: 'Total notes',
                value: '$totalNotes',
                accent: accent,
                scheme: scheme,
              ),
              const SizedBox(width: 10),
              _StatPill(
                label: 'Today',
                value: '${state.notesForDay(DateTime.now()).length}',
                accent: accent,
                scheme: scheme,
              ),
              const SizedBox(width: 10),
              _StatPill(
                label: 'Todos',
                value: '${state.todoNotes.length}',
                accent: accent,
                scheme: scheme,
              ),
            ],
          ),
        ),
        // calendar
        TableCalendar<Note>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
          eventLoader: state.notesForDay,
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) => setState(() => _focusedDay = focused),
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            todayTextStyle: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
            selectedDecoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            defaultTextStyle: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: scheme.onBackground,
            ),
            weekendTextStyle: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: scheme.onBackground.withOpacity(0.6),
            ),
            outsideTextStyle: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: scheme.onBackground.withOpacity(0.25),
            ),
            markerDecoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            markerSize: 5,
            markersMaxCount: 3,
            markersAlignment: Alignment.bottomCenter,
            cellMargin: const EdgeInsets.all(4),
            rowDecoration: const BoxDecoration(),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: scheme.onBackground,
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left_rounded,
              color: scheme.onBackground,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right_rounded,
              color: scheme.onBackground,
            ),
            headerPadding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onBackground.withOpacity(0.4),
            ),
            weekendStyle: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onBackground.withOpacity(0.3),
            ),
          ),
        ),
        // divider + selected day label
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              Text(
                _formatSelectedDay(),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onBackground.withOpacity(0.5),
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (todayNotes.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${todayNotes.length} note${todayNotes.length == 1 ? '' : 's'}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // notes for day
        Expanded(
          child: todayNotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 40,
                        color: scheme.onBackground.withOpacity(0.18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No notes on this day',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          color: scheme.onBackground.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: todayNotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final note = todayNotes[i];
                    return NoteCard(
                      note: note,
                      isDark: isDark,
                      onTap: () => widget.onOpenNote?.call(note),
                      onLongPress: () {},
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _formatSelectedDay() {
    final now = DateTime.now();
    if (isSameDay(_selectedDay, now)) return 'TODAY';
    if (isSameDay(_selectedDay, now.subtract(const Duration(days: 1)))) {
      return 'YESTERDAY';
    }
    return DateFormat('EEE, MMM d').format(_selectedDay).toUpperCase();
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final ColorScheme scheme;

  const _StatPill({
    required this.label,
    required this.value,
    required this.accent,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: accent,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: scheme.onBackground.withOpacity(0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
