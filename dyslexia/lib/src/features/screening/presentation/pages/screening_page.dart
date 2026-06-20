import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/history_panel.dart';
import '../../../../core/widgets/reader_text_display.dart';
import '../../../display_settings/domain/entities/display_settings_entity.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../display_settings/presentation/theme/display_colors.dart';
import '../bloc/screening_bloc.dart';
import '../bloc/screening_event.dart';
import '../bloc/screening_state.dart';

class ScreeningPage extends StatefulWidget {
  const ScreeningPage({super.key});
  @override
  State<ScreeningPage> createState() => _ScreeningPageState();
}

class _ScreeningPageState extends State<ScreeningPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Only start screening if the session hasn't already begun.
    // This preserves the conversation when navigating away and back.
    final bloc = context.read<ScreeningBloc>();
    if (bloc.state is ScreeningInitial) {
      bloc.add(StartScreeningEvent());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    _controller.clear();
    context.read<ScreeningBloc>().add(ReplyScreeningEvent(t));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => HistoryPanel(
        feature: 'screening',
        onSelectInput: (text) => Navigator.pop(ctx),
        onSelectResult: (item) => Navigator.pop(ctx),
      ),
    );
  }

  void _reset() {
    context.read<ScreeningBloc>().add(ResetScreeningEvent());
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScreeningBloc>().add(StartScreeningEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ds = context.watch<DisplaySettingsBloc>().state;
    final s = ds.settings;
    final bg = bgColor(s.colorTheme);
    final fg = fgColor(s.colorTheme);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text('Screening', style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: [
          _BarAction(
            icon: Icons.history_rounded,
            label: 'History',
            color: theme.colorScheme.onSurface,
            onTap: _showHistory,
          ),
          const SizedBox(width: 4),
          _BarAction(
            icon: Icons.refresh_rounded,
            label: 'Restart',
            color: theme.colorScheme.onSurface,
            onTap: _reset,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: BlocConsumer<ScreeningBloc, ScreeningState>(
        listener: (ctx, state) {
          if (state is ScreeningQuestionState || state is ScreeningLoading) {
            _scrollToBottom();
          }
        },
        builder: (ctx, state) {
          if (state is ScreeningInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ScreeningErrorState && state.messages.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to start screening: ${state.message}',
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<ScreeningBloc>().add(StartScreeningEvent()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final messages = state is ScreeningQuestionState
              ? state.messages
              : state is ScreeningLoading
                  ? state.messages
                  : state is ScreeningErrorState
                      ? state.messages
                      : <ChatMessage>[];

          final isComplete =
              state is ScreeningQuestionState && state.isComplete;
          final isLoading = state is ScreeningLoading;

          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text('Starting screening…',
                            style: TextStyle(color: theme.colorScheme.onSurface)))                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = messages[i];
                          if (msg.isUser) {
                            return _UserBubble(text: msg.text);
                          }
                          return _AssistantCard(
                            text: msg.text,
                            isSummary: msg.isSummary,
                            bg: bg,
                            fg: fg,
                            settings: s,
                          );
                        },
                      ),
              ),
              if (isComplete)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: FilledButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Start New Screening'),
                  ),
                ),
              if (!isComplete)
                _InputBar(
                  controller: _controller,
                  enabled: !isLoading,
                  theme: theme,
                  onSend: _send,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF3D5A99),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: Radius.zero,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }
}

class _AssistantCard extends StatelessWidget {
  final String text;
  final bool isSummary;
  final Color bg;
  final Color fg;
  final DisplaySettingsEntity settings;

  const _AssistantCard({
    required this.text,
    required this.isSummary,
    required this.bg,
    required this.fg,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomLeft: Radius.zero,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSummary)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 18, color: Colors.green.shade400),
                  const SizedBox(width: 6),
                  Text(
                    'Screening Complete',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.green.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ReaderTextDisplay(
            text: text,
            settings: settings,
            fgColor: fg,
            bgColor: bg,
            scrollable: false,
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ThemeData theme;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.theme,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final fg = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.04),
        border: Border(top: BorderSide(color: fg.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: fg, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type your answer…',
                  hintStyle: TextStyle(color: fg.withValues(alpha: 0.4)),
                  fillColor: fg.withValues(alpha: 0.08),
                  filled: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: enabled ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: enabled
                    ? const Color(0xFF3D5A99)
                    : fg.withValues(alpha: 0.3),
              ),
              onPressed: enabled ? onSend : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _BarAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ]),
          ),
        ),
      );
}
