import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../configs/injector/injector_conf.dart';
import '../../../../core/api/api_helper.dart';
import '../../../../core/utils/font_utils.dart';
import '../../../../core/widgets/adaptive/adaptive.dart';
import '../../../../core/widgets/reader_text_display.dart';
import '../../../display_settings/domain/entities/display_settings_entity.dart';
import '../../../display_settings/presentation/bloc/display_settings/display_settings_bloc.dart';
import '../../../display_settings/presentation/theme/display_colors.dart';
import '../../data/datasources/screening_remote_datasource.dart';
import '../../data/models/screening_model.dart';
import '../bloc/screening_bloc.dart';
import '../bloc/screening_event.dart';
import '../bloc/screening_state.dart';

class ScreeningPage extends StatefulWidget {
  const ScreeningPage({super.key});

  @override
  State<ScreeningPage> createState() => _ScreeningPageState();
}

enum _PpPhase { processing, success, failed }

const Color _purplePrimary = Color(0xFFB596E5);
const Color _purpleLight = Color(0xFFE0D5F7);

class _ScreeningPageState extends State<ScreeningPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _loadingResults = true;
  List<ScreeningSessionModel> _completed = const [];
  List<ScreeningSessionModel> _incomplete = const [];

  _PpPhase? _ppPhase;
  String? _ppSeverity;
  Object? _ppTotal;
  String? _pollingSession;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<ScreeningBloc>();
    if (bloc.state is! ScreeningInitial) {
      bloc.add(ResetScreeningEvent());
    }
    _loadResults();
  }

  Future<void> _loadResults() async {
    if (mounted) setState(() => _loadingResults = true);
    try {
      final sets = await getIt<ScreeningRemoteDatasource>().sessions();
      if (mounted) {
        setState(() {
          _completed = sets.where((s) => s.isComplete && s.messages.isNotEmpty).toList();
          _incomplete = sets.where((s) => !s.isComplete && s.messages.isNotEmpty).toList();
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

  List<ChatMessage> _toChat(ScreeningSessionModel s) =>
      s.messages.map((m) => ChatMessage(text: m.content, isUser: m.role == 'user')).toList();

  void _continue(ScreeningSessionModel s) {
    context.read<ScreeningBloc>().add(ResumeScreeningEvent(s.sessionId, _toChat(s)));
  }

  @override
  void dispose() {
    _pollingSession = null;
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pollPostProcess(String sessionId) async {
    if (_pollingSession == sessionId) return;
    _pollingSession = sessionId;
    if (mounted) {
      setState(() {
        _ppPhase = _PpPhase.processing;
        _ppSeverity = null;
        _ppTotal = null;
      });
    }
    final api = getIt<ApiHelper>();
    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted || _pollingSession != sessionId) return;
      try {
        final res = await api.execute(
          method: Method.get,
          url: '/me/screen/$sessionId/postprocess/status',
        );
        final status = res['status'] as String?;
        if (status == 'success' || status == 'failed') {
          if (!mounted || _pollingSession != sessionId) return;
          final m = (res['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
          setState(() {
            _ppPhase = status == 'success' ? _PpPhase.success : _PpPhase.failed;
            _ppSeverity = m['ahrq_severity'] as String?;
            _ppTotal = m['ahrq_total'];
          });
          return;
        }
      } catch (_) {}
    }
    if (mounted && _pollingSession == sessionId) {
      setState(() => _ppPhase = _PpPhase.failed);
    }
  }

  Future<void> _retryPostProcess(String sessionId) async {
    _pollingSession = null;
    if (mounted) setState(() => _ppPhase = _PpPhase.processing);
    try {
      await getIt<ApiHelper>().execute(
        method: Method.post,
        url: '/me/screen/$sessionId/postprocess',
        queryParameters: {'force': true},
      );
    } catch (_) {}
    _pollPostProcess(sessionId);
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

  void _viewSession(ScreeningSessionModel s) {
    final ds = context.read<DisplaySettingsBloc>().state.settings;
    final theme = Theme.of(context);
    final bg = bgColor(ds.colorTheme);
    final fg = fgColor(ds.colorTheme);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (ctx, scroll) => ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          itemCount: s.messages.length,
          itemBuilder: (ctx, i) {
            final m = s.messages[i];
            if (m.role == 'user') {
              return _UserBubble(text: m.content, settings: ds);
            }
            return _AssistantCard(text: m.content, isSummary: false, bg: bg, fg: fg, settings: ds);
          },
        ),
      ),
    );
  }

  void _reset() {
    _pollingSession = null;
    _ppPhase = null;
    context.read<ScreeningBloc>().add(ResetScreeningEvent());
    _controller.clear();
    _loadResults();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ds = context.watch<DisplaySettingsBloc>().state;
    final s = ds.settings;
    final bg = bgColor(s.colorTheme);
    final fg = fgColor(s.colorTheme);
    
    // ✅ DETEKSI UKURAN LAYAR UNTUK DESKTOP
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ✅ PERUBAHAN: Background ungu HANYA untuk mobile
          if (!isDesktop) ...[
            // Lapisan bawah
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
              ),
            ),
            // Lapisan atas (gradient)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_purpleLight, _purplePrimary],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
              ),
            ),
          ],

          // === KONTEN UTAMA ===
          Column(
            children: [
              // ✅ PERUBAHAN: Kirim isDesktop ke header
              _buildHeader(context, isDesktop),
              Expanded(
                child: BlocConsumer<ScreeningBloc, ScreeningState>(
                  listener: (ctx, state) {
                    if (state is ScreeningQuestionState || state is ScreeningLoading) {
                      _scrollToBottom();
                    }
                    if (state is ScreeningQuestionState && state.isComplete) {
                      _pollPostProcess(state.sessionId);
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
                        onView: _viewSession,
                      );
                    }
                    if (state is ScreeningErrorState && state.messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text('Failed to start: ${state.message}', style: TextStyle(color: theme.colorScheme.onSurface), textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => context.read<ScreeningBloc>().add(StartScreeningEvent()),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: FilledButton.styleFrom(backgroundColor: _purplePrimary),
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

                    final isComplete = state is ScreeningQuestionState && state.isComplete;
                    final isLoading = state is ScreeningLoading;

                    return Column(
                      children: [
                        Expanded(
                          child: messages.isEmpty
                              ? Center(child: Text('Starting…', style: TextStyle(color: theme.colorScheme.onSurface)))
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  itemCount: messages.length,
                                  itemBuilder: (ctx, i) {
                                    final msg = messages[i];
                                    if (msg.isUser) {
                                      return _UserBubble(text: msg.text, settings: s);
                                    }
                                    return _AssistantCard(text: msg.text, isSummary: msg.isSummary, bg: bg, fg: fg, settings: s);
                                  },
                                ),
                        ),
                        if (isComplete) ...[
                          _PostProcessBanner(
                            phase: _ppPhase ?? _PpPhase.processing,
                            severity: _ppSeverity,
                            total: _ppTotal,
                            fg: theme.colorScheme.onSurface,
                            onRetry: () => _retryPostProcess(state.sessionId),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: FilledButton.icon(
                              onPressed: _reset,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Done'),
                              style: FilledButton.styleFrom(backgroundColor: _purplePrimary),
                            ),
                          ),
                        ],
                        if (!isComplete)
                          _InputBar(
                            controller: _controller,
                            enabled: !isLoading,
                            theme: theme,
                            textStyle: dyslexiaTextStyle(s, theme.colorScheme.onSurface),
                            onSend: _send,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ PERUBAHAN: Tambahkan parameter isDesktop untuk mengatur layout header
  Widget _buildHeader(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.only(
        left: isDesktop ? 32 : 24, 
        right: isDesktop ? 32 : 24, 
        top: isDesktop ? 24 : 48, // Padding atas lebih kecil di desktop karena tidak ada background ungu
        bottom: 16
      ),
      child: Row(
        children: [
          // ✅ Tombol Back dan Judul HANYA untuk Mobile
          if (!isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                fixedSize: const Size(40, 40),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Pre-Screening',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Spacer untuk mendorong tombol refresh ke kanan pada desktop
          if (isDesktop) const Spacer(),

          // Tombol Refresh (tetap ada di kedua versi, tapi dengan elevation di desktop agar terlihat di background putih)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black),
            onPressed: _reset,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              fixedSize: const Size(40, 40),
              elevation: isDesktop ? 2 : 0, 
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET-WIDGET LAINNYA TETAP SAMA (TIDAK DIUBAH) ===

class _IntroView extends StatelessWidget {
  final Color fg;
  final bool loading;
  final List<ScreeningSessionModel> completed;
  final List<ScreeningSessionModel> incomplete;
  final VoidCallback onStart;
  final ValueChanged<ScreeningSessionModel> onContinue;
  final ValueChanged<ScreeningSessionModel> onView;

  const _IntroView({
    required this.fg,
    required this.loading,
    required this.completed,
    required this.incomplete,
    required this.onStart,
    required this.onContinue,
    required this.onView,
  });

  Widget _heading(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(t, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg)),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        Icon(Icons.fact_check_rounded, size: 48, color: fg.withValues(alpha: 0.8)),
        const SizedBox(height: 16),
        Text(
          'A short set of questions about your reading habits. This is an informal check-in, not a diagnosis.',
          style: TextStyle(fontSize: 14, color: fg.withValues(alpha: 0.7), height: 1.4),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start pre-screening'),
          style: FilledButton.styleFrom(backgroundColor: _purplePrimary),
        ),
        if (loading) ...[
          const SizedBox(height: 28),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
        ] else ...[
          if (incomplete.isNotEmpty) ...[
            const SizedBox(height: 28),
            _heading('Continue where you left off'),
            ...incomplete.map((s) => _ContinueCard(session: s, fg: fg, onTap: () => onContinue(s))),
          ],
          const SizedBox(height: 28),
          _heading('Your results'),
          if (completed.isEmpty)
            Text('No results yet — complete a pre-screening to see it here.', style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.5)))
          else
            ...completed.map((s) => _ResultCard(session: s, fg: fg, onTap: () => onView(s))),
        ],
      ],
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final ScreeningSessionModel session;
  final Color fg;
  final VoidCallback onTap;
  const _ContinueCard({required this.session, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = session.updatedAt;
    final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _purpleLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _purplePrimary.withValues(alpha: 0.3)),
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
                const Icon(Icons.play_circle_fill_rounded, color: _purplePrimary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('In progress — ${session.answeredCount}/${session.totalTopics} answered', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                      Text('Last activity $date · tap to continue', style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ScreeningSessionModel session;
  final Color fg;
  final VoidCallback onTap;
  const _ResultCard({required this.session, required this.fg, required this.onTap});

  static const _severityColors = {
    'mild': Color(0xFF2E7D32),
    'moderate': Color(0xFFED6C02),
    'severe': Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) {
    final m = session.result ?? const {};
    final scored = session.status == 'success';
    final severity = (m['ahrq_severity'] as String?) ?? 'pending';
    final total = m['ahrq_total'];
    final color = scored ? (_severityColors[severity] ?? fg) : fg;
    final d = session.updatedAt;
    final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(severity.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (total != null) Text('Score: $total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg)),
                      Text('$date · tap to view conversation', style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: fg.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostProcessBanner extends StatelessWidget {
  final _PpPhase phase;
  final String? severity;
  final Object? total;
  final Color fg;
  final VoidCallback onRetry;

  const _PostProcessBanner({required this.phase, required this.severity, required this.total, required this.fg, required this.onRetry});

  static const _severityColors = {
    'mild': Color(0xFF2E7D32),
    'moderate': Color(0xFFED6C02),
    'severe': Color(0xFFC62828),
  };

  @override
  Widget build(BuildContext context) {
    final (color, child) = switch (phase) {
      _PpPhase.processing => (
          _purplePrimary, 
          Row(children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(_purplePrimary))),
            const SizedBox(width: 12),
            Expanded(child: Text('Analyzing your responses…', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg))),
          ]),
        ),
      _PpPhase.success => () {
          final sev = severity ?? 'unknown';
          final c = _severityColors[sev] ?? const Color(0xFF2E7D32);
          return (
            c,
            Row(children: [
              Icon(Icons.check_circle_rounded, color: c, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Result ready — ${sev.toUpperCase()}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                    if (total != null) Text('Score: $total', style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.6))),
                  ],
                ),
              ),
            ]),
          );
        }(),
      _PpPhase.failed => (
          const Color(0xFFC62828),
          Row(children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text("Couldn't score your responses.", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg))),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ]),
        ),
    };

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: child,
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: _purplePrimary, 
          borderRadius: BorderRadius.circular(18).copyWith(bottomRight: Radius.zero),
        ),
        child: Text(text, style: dyslexiaTextStyle(settings, Colors.white)),
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

  const _AssistantCard({required this.text, required this.isSummary, required this.bg, required this.fg, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18).copyWith(bottomLeft: Radius.zero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isSummary) ...[
                Icon(Icons.check_circle, size: 18, color: Colors.green.shade400),
                const SizedBox(width: 6),
                Text('Screening Complete', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.green.shade400)),
              ],
              const Spacer(),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: text));
                  showAdaptiveFeedback(context, 'Copied to clipboard');
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded, size: 16, color: fg.withValues(alpha: 0.6)),
                ),
              ),
            ],
          ),
          ReaderTextDisplay(text: text, settings: settings, fgColor: fg, bgColor: bg, scrollable: false),
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

  const _InputBar({required this.controller, required this.enabled, required this.theme, required this.textStyle, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final fg = theme.colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                  fillColor: fg.withValues(alpha: 0.06),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: fg.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _purplePrimary, width: 1.5), 
                  ),
                ),
                onSubmitted: enabled ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.send_rounded,
                color: enabled ? _purplePrimary : fg.withValues(alpha: 0.3), 
              ),
              onPressed: enabled ? onSend : null,
            ),
          ],
        ),
      ),
    );
  }
}