// lib/game/views/game_screen.dart

import 'package:flutter/material.dart';

import '../game_controller.dart';
import '../models/game_state.dart';
import 'widgets/playing_card_view.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.controller});

  final GameController? controller;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? GameController();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final state = _controller.state;
        return Scaffold(
          backgroundColor: const Color(0xFF1B2430),
          body: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      _Header(state: state),
                      const SizedBox(height: 16),
                      _ScoreBoard(state: state),
                      const SizedBox(height: 12),
                      if (state.lastResult != null)
                        _ResultBanner(text: state.lastResult!),
                      const Spacer(),
                      _HandArea(state: state, onToggle: _controller.toggleCard),
                      const SizedBox(height: 20),
                      _ActionBar(
                        state: state,
                        onPlay: _controller.playSelectedCards,
                        onDiscard: _controller.discardSelectedCards,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                if (state.isTerminal)
                  _TerminalOverlay(
                    state: state,
                    onRestart: _controller.restart,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'WORDLOTRO',
          style: TextStyle(
            color: Color(0xFFE8A838),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        _StatChip(label: 'Deck', value: '${state.deck.length}'),
      ],
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final progress = (state.score / state.targetScore).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF243447),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A4F66)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ScoreLabel(
                  title: 'SCORE',
                  value: '${state.score}',
                  accent: const Color(0xFF5AD67D),
                ),
              ),
              Expanded(
                child: _ScoreLabel(
                  title: 'TARGET',
                  value: '${state.targetScore}',
                  accent: const Color(0xFFE8A838),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFF1B2430),
              color: progress >= 1
                  ? const Color(0xFF5AD67D)
                  : const Color(0xFFE8A838),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatChip(label: 'Hands', value: '${state.handsRemaining}'),
              const SizedBox(width: 8),
              _StatChip(label: 'Discards', value: '${state.discardsRemaining}'),
              const Spacer(),
              Text(
                '${state.selectedCards.length}/5 selected',
                style: const TextStyle(color: Color(0xFF9BB0C5), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreLabel extends StatelessWidget {
  const _ScoreLabel({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF9BB0C5),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2430),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: Color(0xFFD5E2EF),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2E4057),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFFFFE6A7),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HandArea extends StatelessWidget {
  const _HandArea({required this.state, required this.onToggle});

  final GameState state;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = state.hand.length;
        if (count == 0) {
          return const SizedBox(height: 110);
        }

        final maxWidth = constraints.maxWidth;
        final cardWidth = (maxWidth / count * 0.92).clamp(48.0, 72.0);
        final cardHeight = cardWidth * 1.5;
        final overlap = count > 1
            ? ((cardWidth * count - maxWidth) / (count - 1)).clamp(
                0.0,
                cardWidth * 0.35,
              )
            : 0.0;

        return SizedBox(
          height: cardHeight + 20,
          width: double.infinity,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < count; i++)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : -overlap),
                    child: PlayingCardView(
                      card: state.hand[i],
                      width: cardWidth,
                      height: cardHeight,
                      onTap: state.isTerminal
                          ? () {}
                          : () => onToggle(state.hand[i].id),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.state,
    required this.onPlay,
    required this.onDiscard,
  });

  final GameState state;
  final VoidCallback onPlay;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final hasSelection = state.selectedCards.isNotEmpty;
    final canPlay =
        hasSelection && state.handsRemaining > 0 && !state.isTerminal;
    final canDiscard =
        hasSelection && state.discardsRemaining > 0 && !state.isTerminal;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: canDiscard ? onDiscard : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5568),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF2A3441),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'DISCARD',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: canPlay ? onPlay : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8A838),
              foregroundColor: const Color(0xFF1B2430),
              disabledBackgroundColor: const Color(0xFF5A4A28),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'PLAY HAND',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _TerminalOverlay extends StatelessWidget {
  const _TerminalOverlay({required this.state, required this.onRestart});

  final GameState state;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final won = state.status == RoundStatus.won;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF243447),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: won ? const Color(0xFF5AD67D) : const Color(0xFFE57373),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? 'BLIND CLEARED' : 'BUSTED',
                style: TextStyle(
                  color: won
                      ? const Color(0xFF5AD67D)
                      : const Color(0xFFE57373),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Score ${state.score} / ${state.targetScore}',
                style: const TextStyle(color: Color(0xFFD5E2EF), fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRestart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A838),
                  foregroundColor: const Color(0xFF1B2430),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'PLAY AGAIN',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
