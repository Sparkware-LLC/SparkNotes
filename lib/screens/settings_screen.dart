import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    final accent = accentOf(state.accentKey);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        // ── Appearance ──────────────────────────────────────────────────
        _SectionHeader('Appearance', scheme),
        _SettingsCard(
          children: [
            _ThemeTile(state: state, accent: accent, scheme: scheme),
            _Divider(scheme),
            _AccentTile(state: state, scheme: scheme),
          ],
        ),

        const SizedBox(height: 20),

        // ── Notes ────────────────────────────────────────────────────────
        _SectionHeader('Notes', scheme),
        _SettingsCard(
          children: [
            _DefaultColorTile(state: state, isDark: isDark, scheme: scheme, accent: accent),
            _Divider(scheme),
            _FontSizeTile(state: state, accent: accent, scheme: scheme),
            _Divider(scheme),
            _ViewModeTile(state: state, scheme: scheme, accent: accent),
          ],
        ),

        const SizedBox(height: 20),

        // ── Doodle ───────────────────────────────────────────────────────
        _SectionHeader('Doodle', scheme),
        _SettingsCard(
          children: [
            _StrokeWidthTile(state: state, accent: accent, scheme: scheme),
          ],
        ),

        const SizedBox(height: 20),

        // ── Data ─────────────────────────────────────────────────────────
        _SectionHeader('Data', scheme),
        _SettingsCard(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(Icons.delete_sweep_outlined,
                  color: Colors.red.shade400, size: 22),
              title: Text(
                'Clear all notes',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  color: Colors.red.shade400,
                ),
              ),
              subtitle: Text(
                'This cannot be undone',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: scheme.onSurface.withOpacity(0.4),
                ),
              ),
              onTap: () => _confirmClear(context, state),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── About ─────────────────────────────────────────────────────────
        _SectionHeader('About', scheme),
        _SettingsCard(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/SparkNotes-Logo-removed-bg.png',
                      width: 52,
                      height: 52,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SparkNotes',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        'SparkPlay  1.0.1 Beta',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        'by Sparkware',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _Divider(scheme),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(Icons.info_outline_rounded,
                  size: 20, color: scheme.onSurface.withOpacity(0.5)),
              title: Text(
                'View onboarding',
                style: GoogleFonts.jetBrainsMono(fontSize: 14),
              ),
              trailing: Icon(Icons.chevron_right_rounded,
                  size: 18, color: scheme.onSurface.withOpacity(0.3)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const _OnboardingPreview()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Center(
          child: Text(
            '© Sparkware. All rights reserved.',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: scheme.onBackground.withOpacity(0.25),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear all notes?',
            style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w600)),
        content: Text(
          'All ${state.notes.length} notes will be permanently deleted.',
          style: GoogleFonts.jetBrainsMono(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              state.clearAllNotes();
              Navigator.pop(ctx);
            },
            child: Text('Delete all',
                style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}

// ─── Tiles ──────────────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  final AppState state;
  final Color accent;
  final ColorScheme scheme;

  const _ThemeTile({required this.state, required this.accent, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: ThemeMode.values.map((mode) {
              final labels = ['System', 'Light', 'Dark'];
              final icons = [
                Icons.brightness_auto_rounded,
                Icons.light_mode_rounded,
                Icons.dark_mode_rounded,
              ];
              final selected = state.themeMode == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => state.setThemeMode(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: mode != ThemeMode.dark ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? accent : scheme.outline.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? accent : Colors.transparent,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icons[mode.index],
                          size: 18,
                          color: selected ? Colors.white : scheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          labels[mode.index],
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : scheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AccentTile extends StatelessWidget {
  final AppState state;
  final ColorScheme scheme;

  const _AccentTile({required this.state, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent color',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: accents.keys.map((key) {
              final c = accentOf(key);
              final selected = state.accentKey == key;
              return GestureDetector(
                onTap: () => state.setAccent(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: selected ? 40 : 34,
                  height: selected ? 40 : 34,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? scheme.onSurface : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8)]
                        : null,
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Text(
            state.accentKey.replaceFirst(state.accentKey[0], state.accentKey[0].toUpperCase()),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: accentOf(state.accentKey),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultColorTile extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final ColorScheme scheme;
  final Color accent;

  const _DefaultColorTile({
    required this.state,
    required this.isDark,
    required this.scheme,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Default note color',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: noteLightColors.keys.map((key) {
              final c = noteColor(key, isDark);
              final selected = state.defaultNoteColor == key;
              return GestureDetector(
                onTap: () => state.setDefaultNoteColor(key),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: noteColor(key, false),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? accent : scheme.outline,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: selected
                      ? Icon(Icons.check_rounded, size: 16, color: c.computeLuminance() > 0.5 ? Colors.black54 : Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _FontSizeTile extends StatelessWidget {
  final AppState state;
  final Color accent;
  final ColorScheme scheme;

  const _FontSizeTile({required this.state, required this.accent, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Font size',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${state.baseFontSize.round()}px',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: accent,
              inactiveTrackColor: scheme.outline,
              thumbColor: accent,
            ),
            child: Slider(
              value: state.baseFontSize,
              min: 12.0,
              max: 22.0,
              divisions: 10,
              onChanged: (v) => state.setFontSize(v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Small', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: scheme.onSurface.withOpacity(0.35))),
              Text('Large', style: GoogleFonts.jetBrainsMono(fontSize: 10, color: scheme.onSurface.withOpacity(0.35))),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewModeTile extends StatelessWidget {
  final AppState state;
  final ColorScheme scheme;
  final Color accent;

  const _ViewModeTile({required this.state, required this.scheme, required this.accent});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        state.gridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
        size: 20,
        color: scheme.onSurface.withOpacity(0.6),
      ),
      title: Text(
        'Note layout',
        style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        state.gridView ? 'Grid view' : 'List view',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          color: scheme.onSurface.withOpacity(0.4),
        ),
      ),
      trailing: Switch(
        value: state.gridView,
        onChanged: state.setGridView,
        activeColor: accent,
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

class _StrokeWidthTile extends StatelessWidget {
  final AppState state;
  final Color accent;
  final ColorScheme scheme;

  const _StrokeWidthTile({required this.state, required this.accent, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Default stroke width',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              Text(
                '${state.defaultStrokeWidth.round()}px',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: accent,
              inactiveTrackColor: scheme.outline,
              thumbColor: accent,
            ),
            child: Slider(
              value: state.defaultStrokeWidth,
              min: 1.0,
              max: 15.0,
              divisions: 14,
              onChanged: (v) => state.setDefaultStrokeWidth(v),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme scheme;

  const _SectionHeader(this.title, this.scheme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: scheme.onBackground.withOpacity(0.4),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  final ColorScheme scheme;
  const _Divider(this.scheme);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: scheme.outline,
      indent: 16,
    );
  }
}

// Quick onboarding preview (non-functional, just shows slides)
class _OnboardingPreview extends StatelessWidget {
  const _OnboardingPreview();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How it works')),
      body: const OnboardingScreen(),
    );
  }
}
