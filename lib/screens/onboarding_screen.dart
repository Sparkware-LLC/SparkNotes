import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _OPage(
      icon: Icons.bolt_rounded,
      label: '01 / 04',
      headline: 'Welcome to\nSparkNotes.',
      sub:
          'A fast, focused notes app that gets out of your way. Text, todos, doodles, all in one place.',
    ),
    _OPage(
      icon: Icons.edit_note_rounded,
      label: '02 / 04',
      headline: 'Write anything,\nany way.',
      sub:
          'Rich text notes for long thoughts. Checklists for tasks. Doodle canvas when words aren\'t enough.',
    ),
    _OPage(
      icon: Icons.calendar_month_rounded,
      label: '03 / 04',
      headline: 'Built around\nyour calendar.',
      sub:
          'Every note is tagged by date. Jump to any day and see what you captured like a second brain.',
    ),
    _OPage(
      icon: Icons.tune_rounded,
      label: '04 / 04',
      headline: 'Your style,\nyour rules.',
      sub:
          'Switch themes, pick accent colors, change layouts. SparkNotes adapts to how you think.',
    ),
  ];

  void _next(BuildContext context) {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finish(context);
    }
  }

  void _finish(BuildContext context) {
    context.read<AppState>().completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentOf(context.watch<AppState>().accentKey);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // header row
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              child: Row(
                children: [
                  Image.asset('assets/logo.jpg', width: 32, height: 32),
                  const SizedBox(width: 8),
                  Text(
                    'SparkNotes',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: scheme.onBackground,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _finish(context),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: scheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _PageContent(
                  page: _pages[i],
                  accent: accent,
                  scheme: scheme,
                ),
              ),
            ),
            // dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == i ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _page == i
                              ? accent
                              : scheme.outline.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _next(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _page == _pages.length - 1
                            ? 'Get Started →'
                            : 'Next →',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

class _OPage {
  final IconData icon;
  final String label;
  final String headline;
  final String sub;

  const _OPage({
    required this.icon,
    required this.label,
    required this.headline,
    required this.sub,
  });
}

class _PageContent extends StatelessWidget {
  final _OPage page;
  final Color accent;
  final ColorScheme scheme;

  const _PageContent({
    required this.page,
    required this.accent,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 2),
          // illustration area
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withOpacity(0.18), width: 1.5),
            ),
            child: Center(
              child: Icon(
                page.icon,
                size: 96,
                color: accent,
              ),
            ),
          ),
          const Spacer(flex: 2),
          Text(
            page.label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: accent,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            page.headline,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: scheme.onBackground,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            page.sub,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              height: 1.6,
              color: scheme.onBackground.withOpacity(0.6),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
