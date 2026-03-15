import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/claude_service.dart';

class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  final TextEditingController _ctrl    = TextEditingController();
  final ScrollController       _scroll = ScrollController();
  bool _isTyping = false;
  final List<Map<String, String>> _history = [];

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    _ctrl.clear();
    ref.read(chatProvider.notifier).addMessage(text, true);
    _history.add({'role': 'user', 'content': text});
    setState(() => _isTyping = true);
    _scrollToBottom();

    final cycle    = ref.read(cycleProvider);
    final tasks    = ref.read(tasksProvider);
    final userName = ref.read(userNameProvider);

    final response = await ClaudeService.sendMessage(
      userMessage: text,
      history:     _history,
      cycle:       cycle,
      tasks:       tasks,
      userName:    userName,
    );

    _history.add({'role': 'assistant', 'content': response});

    if (mounted) {
      ref.read(chatProvider.notifier).addSakhiResponse(response);
      setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final cycle    = ref.watch(cycleProvider);

    return Scaffold(
      backgroundColor: SakhiColors.vblush,
      appBar: AppBar(
        title: const Text('Sakhi'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PhaseBadge(phase: cycle.phase),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == messages.length && _isTyping) return const _TypingIndicator();
                return _MessageBubble(message: messages[i]);
              },
            ),
          ),
          if (messages.length <= 1)
            _QuickPrompts(onTap: (p) { _ctrl.text = p; _send(); }),
          _InputBar(ctrl: _ctrl, onSend: _send),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(color: SakhiColors.deep, shape: BoxShape.circle),
              child: const Center(child: Text('S', style: TextStyle(color: SakhiColors.gold, fontWeight: FontWeight.w700, fontSize: 14))),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? SakhiColors.rose : SakhiColors.white,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4  : 16),
                ),
                border: isUser ? null : Border.all(color: SakhiColors.petal),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.text, style: TextStyle(color: isUser ? Colors.white : SakhiColors.gray, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 4),
                  Text(DateFormat('h:mm a').format(message.time),
                      style: TextStyle(color: isUser ? Colors.white.withOpacity(0.6) : SakhiColors.lgray, fontSize: 10)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(color: SakhiColors.deep, shape: BoxShape.circle),
            child: const Center(child: Text('S', style: TextStyle(color: SakhiColors.gold, fontWeight: FontWeight.w700, fontSize: 14))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: SakhiColors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: SakhiColors.petal)),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) => Container(
                  width: 6, height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                      color: SakhiColors.rose.withOpacity((_ctrl.value + i * 0.2).clamp(0.2, 1.0)),
                      shape: BoxShape.circle),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPrompts extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _QuickPrompts({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final prompts = ["How am I doing today?", "I'm feeling nervous", "I'm exhausted", "What should I focus on?"];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: prompts.map((p) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onTap(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: SakhiColors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: SakhiColors.petal)),
              child: Text(p, style: const TextStyle(color: SakhiColors.rose, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
        )).toList(),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  const _InputBar({required this.ctrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: const BoxDecoration(color: SakhiColors.white, border: Border(top: BorderSide(color: SakhiColors.petal))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: 3, minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Talk to Sakhi...',
                filled: true, fillColor: SakhiColors.vblush,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: SakhiColors.petal)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: SakhiColors.petal)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: SakhiColors.rose, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(color: SakhiColors.rose, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}