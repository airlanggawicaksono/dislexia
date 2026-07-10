import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/api/api_helper.dart';
import '../../../../core/api/feature_history_datasource.dart';
import '../../../../core/utils/font_utils.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
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

  // Idle-screen data, grouped by session from history.
  bool _loadingResults = true;
  List<FeatureHistoryItem> _completed = const []; // rows carrying ahrq result
  List<_PreScreenSession> _incomplete = const []; // resumable sessions

  @override
  void initState() {
    super.initState();
    // Do NOT auto-start — show the intro + past results first, start on tap.
    // (Preserves any in-progress session across navigate-away-and-back.)
    _loadResults();
  }

  Future<void> _loadResults() async {
    if (mounted) setState(() => _loadingResults = true);
    try {
      final items = await FeatureHistoryDatasource(getIt<ApiHelper>())
          .getHistory(feature: 'screen');
      final grouped = _groupSessions(items);
      if (mounted) {
        setState(() {
          _completed =
              items.where((i) => i.metadata?['ahrq_severity'] != null).toList();
          _incomplete = grouped.where((s) => !s.complete).toList();
          _loadingResults = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _completed = const [];
          _incomplete = const [];
          _loadingResults = false;
        });
      }
    }
  }

  void _start() => context.read<ScreeningBloc>().add(StartScreeningEvent());

  // Rehydrate an incomplete session and continue it.
  void _continue(_PreScreenSession s) {
    context
        .read<ScreeningBloc>()
        .add(ResumeScreeningEvent(s.sessionId, s.messages));
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
        // Backend FeatureType enum value is 'screen', not 'screening'.
        feature: 'screen',
        onSelectInput: (text) => Navigator.pop(ctx),
        onSelectResult: (item) => Navigator.pop(ctx),
      ),
    );
  }

  void _reset() {
    context.read<ScreeningBloc>().add(ResetScreeningEvent());
    _controller.clear();
    // Back to the intro; refresh the results list (a run may have completed).
    _loadResults();
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
        title: Text('Pre-Screening', style: TextStyle(color: theme.colorScheme.onSurface)),
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
            return _IntroView(
              fg: theme.colorScheme.onSurface,
              loading: _loadingResults,
              completed: _completed,
              incomplete: _incomplete,
              onStart: _start,
              onContinue: _continue,
            );
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
                      'Failed to start: ${state.message}',
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
                        child: Text('Starting…',
                            style: TextStyle(color: theme.colorScheme.onSurface)))                      : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = messages[i];
                          if (msg.isUser) {
                            return _UserBubble(text: msg.text, settings: s);
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
                    label: const Text('Done'),
                  ),
                ),
              if (!isComplete)
                _InputBar(
                  controller: _controller,
                  enabled: !isLoading,
                  theme: theme,
                  textStyle:
                      dyslexiaTextStyle(s, theme.colorScheme.onSurface),
                  onSend: _send,
                ),
            ],
          );
        },
      ),
    );
  }
}

const _totalTopics = 23; // ARHQ item count — see backend QUESTIONS.

/// A pre-screening session reconstructed from its history rows.
class _PreScreenSession {
  final String sessionId;
  final List<ChatMessage> messages;
  final int answered;
  final DateTime date;
  final bool complete;
  const _PreScreenSession({
    required this.sessionId,
    required this.messages,
    required this.answered,
    required this.date,
    required this.complete,
  });
}

/// Group flat history rows into sessions (chronological), rebuilding the chat
/// bubbles so an incomplete one can be replayed + resumed.
List<_PreScreenSession> _groupSessions(List<FeatureHistoryItem> items) {
  final sorted = [...items]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final map = <String, List<FeatureHistoryItem>>{};
  for (final it in sorted) {
    (map[it.sessionId] ??= <FeatureHistoryItem>[]).add(it);
  }
  final sessions = <_PreScreenSession>[];
  map.forEach((sid, rows) {
    final messages = <ChatMessage>[];
    for (final r in rows) {
      final input = r.inputText.trim();
      // The start row's input is a placeholder, not a user answer.
      if (input.isNotEmpty && input != '[screening started]') {
        messages.add(ChatMessage(text: input, isUser: true));
      }
      if (r.outputText.trim().isNotEmpty) {
        messages.add(ChatMessage(text: r.outputText));
      }
    }
    final last = rows.last;
    sessions.add(_PreScreenSession(
      sessionId: sid,
      messages: messages,
      answered: (last.metadata?['answered_count'] as num?)?.toInt() ?? 0,
      date: last.createdAt,
      complete: rows.any((r) => r.metadata?['ahrq_severity'] != null),
    ));
  });
  sessions.sort((a, b) => b.date.compareTo(a.date)); // newest first
  return sessions;
}

/// Idle view: short intro + Start + resumable sessions + past results.
class _IntroView extends StatelessWidget {
  final Color fg;
  final bool loading;
  final List<FeatureHistoryItem> completed;
  final List<_PreScreenSession> incomplete;
  final VoidCallback onStart;
  final ValueChanged<_PreScreenSession> onContinue;

  const _IntroView({
    required this.fg,
    required this.loading,
    required this.completed,
    required this.incomplete,
    required this.onStart,
    required this.onContinue,
  });

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: fg)),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Icon(Icons.fact_check_rounded, size: 48, color: fg.withValues(alpha: 0.8)),
        const SizedBox(height: 16),
        Text('Pre-Screening',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: fg),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'A short set of questions about your reading habits. '
          'This is an informal check-in, not a diagnosis.',
          style: TextStyle(fontSize: 14, color: fg.withValues(alpha: 0.7), height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start pre-screening'),
        ),
        if (loading) ...[
          const SizedBox(height: 28),
          const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
          )),
        ] else ...[
          if (incomplete.isNotEmpty) ...[
            const SizedBox(height: 28),
            _heading('Continue where you left off'),
            ...incomplete.map((s) =>
                _ContinueCard(session: s, fg: fg, onTap: () => onContinue(s))),
          ],
          const SizedBox(height: 28),
          _heading('Your results'),
          if (completed.isEmpty)
            Text('No results yet — complete a pre-screening to see it here.',
                style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.5)))
          else
            ...completed.map((r) => _ResultCard(item: r, fg: fg)),
        ],
      ],
    );
  }
}

/// Tappable card for an unfinished session — resumes it.
class _ContinueCard extends StatelessWidget {
  final _PreScreenSession session;
  final Color fg;
  final VoidCallback onTap;
  const _ContinueCard(
      {required this.session, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3D5A99);
    final d = session.date;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('In progress — ${session.answered}/$_totalTopics answered',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: fg)),
                      Text('Started $date · tap to continue',
                          style: TextStyle(
                              fontSize: 12, color: fg.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: fg.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final FeatureHistoryItem item;
  final Color fg;
  const _ResultCard({required this.item, required this.fg});

  static const _severityColors = {
    'mild': Color(0xFF2E7D32),
    'moderate': Color(0xFFED6C02),
    'severe': Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) {
    final m = item.metadata ?? const {};
    final severity = (m['ahrq_severity'] as String?) ?? 'unknown';
    final total = m['ahrq_total'];
    final color = _severityColors[severity] ?? fg;
    final d = item.createdAt;
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(severity.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (total != null)
                  Text('Score: $total',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                Text(date,
                    style: TextStyle(
                        fontSize: 12, color: fg.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  final DisplaySettingsEntity settings;
  const _UserBubble({required this.text, required this.settings});

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
        // Font/size/spacing from display settings; white on the blue bubble.
        child: Text(
          text,
          style: dyslexiaTextStyle(settings, Colors.white),
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
          Row(
            children: [
              if (isSummary) ...[
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
              const Spacer(),
              // Every result is copyable.
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  showAdaptiveFeedback(context, 'Copied to clipboard');
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded,
                      size: 16, color: fg.withValues(alpha: 0.6)),
                ),
              ),
            ],
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
  final TextStyle textStyle;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.theme,
    required this.textStyle,
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
                style: textStyle,
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
