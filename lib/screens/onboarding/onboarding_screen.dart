import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;
  final TextEditingController _nameCtrl = TextEditingController();

  final List<_OnboardSlide> _slides = const [
    _OnboardSlide(
      emoji:    '🌸',
      title:    'Meet Sakhi',
      subtitle: 'Your AI companion who knows your schedule, your cycle, and your mind — '
                'and shows up before you have to ask.',
    ),
    _OnboardSlide(
      emoji:    '🛡️',
      title:    'Always protected',
      subtitle: 'Sakhi Shield gives you passive, always-on safety before you need it — '
                'not a panic button, but a companion already watching.',
    ),
    _OnboardSlide(
      emoji:    '🌙',
      title:    'Your cycle, your superpower',
      subtitle: 'Sakhi connects your hormonal cycle to your calendar so every task '
                'is planned around your biology, not against it.',
    ),
  ];

  void _next() {
    if (_page < _slides.length) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finish() {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      ref.read(userNameProvider.notifier).state = name;
      StorageService.saveUserName(name);
    }
    StorageService.saveOnboardingComplete(true);
    ref.read(onboardingCompleteProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SakhiColors.deep,
      body: SafeArea(
        child: PageView(
          controller: _controller,
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            ..._slides.map((s) => _SlidePage(slide: s)),
            _NamePage(controller: _nameCtrl, onFinish: _finish),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: SakhiColors.deep,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length + 1, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width:  _page == i ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color:        _page == i ? SakhiColors.gold : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _page < _slides.length ? _next : _finish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: SakhiColors.rose,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _page < _slides.length ? 'Continue' : 'Get started',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlidePage extends StatelessWidget {
  final _OnboardSlide slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(slide.emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 32),
          Text(slide.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28, fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(slide.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16, height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onFinish;

  const _NamePage({required this.controller, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 24),
          const Text("What should Sakhi call you?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text("Sakhi will use your name in every check-in, every morning, every hard day.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 15, height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller:    controller,
            autofocus:     true,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText:    'Your name',
              hintStyle:   TextStyle(color: Colors.white.withOpacity(0.4)),
              filled:      true,
              fillColor:   Colors.white.withOpacity(0.08),
              border:      OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: SakhiColors.gold, width: 1.5),
              ),
            ),
            onSubmitted: (_) => onFinish(),
          ),
        ],
      ),
    );
  }
}

class _OnboardSlide {
  final String emoji;
  final String title;
  final String subtitle;
  const _OnboardSlide({required this.emoji, required this.title, required this.subtitle});
}
