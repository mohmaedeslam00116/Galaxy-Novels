import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/platform/app_system_settings.dart';
import '../application/reader_speech_controller.dart';
import '../domain/reader_speech_models.dart';

class ReaderSpeechMiniPlayer extends StatelessWidget {
  const ReaderSpeechMiniPlayer({
    required this.controller,
    required this.onExpand,
    super.key,
  });

  final ReaderSpeechController controller;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final state = controller.value;
        final chapter = state.chapter;
        if (chapter == null || state.status == ReaderSpeechStatus.idle) {
          return const SizedBox.shrink();
        }
        final isPlaying = state.status == ReaderSpeechStatus.playing;
        return Material(
          key: const ValueKey('reader-speech-mini-player'),
          elevation: 12,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: SafeArea(
            top: false,
            child: InkWell(
              onTap: onExpand,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.record_voice_over_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.chapterTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            _speechStatusLabel(state),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'الفقرة السابقة',
                      onPressed: controller.skipPreviousBlock,
                      icon: const Icon(Icons.skip_previous_rounded),
                    ),
                    IconButton.filled(
                      tooltip: isPlaying
                          ? 'إيقاف القراءة الصوتية مؤقتًا'
                          : 'تشغيل القراءة الصوتية',
                      onPressed: isPlaying ? controller.pause : controller.play,
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                    IconButton(
                      tooltip: 'الفقرة التالية',
                      onPressed: controller.skipNextBlock,
                      icon: const Icon(Icons.skip_next_rounded),
                    ),
                    IconButton(
                      tooltip: 'إيقاف القراءة الصوتية',
                      onPressed: controller.stop,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ReaderSpeechPanel extends StatefulWidget {
  const ReaderSpeechPanel({
    required this.controller,
    this.onManageVoices,
    super.key,
  });

  final ReaderSpeechController controller;
  final Future<bool> Function()? onManageVoices;

  @override
  State<ReaderSpeechPanel> createState() => _ReaderSpeechPanelState();
}

class _ReaderSpeechPanelState extends State<ReaderSpeechPanel> {
  String? _selectedEngine;
  double? _draftRate;

  ReaderSpeechController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final preferences = _controller.preferences;
        final voices = sortedArabicVoices(_controller.availableVoices);
        final engines = voices.map((voice) => voice.engineId).toSet().toList()
          ..sort();
        final selectedEngine = _effectiveEngine(engines, preferences);
        final engineVoices = voices
            .where((voice) => voice.engineId == selectedEngine)
            .toList();
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'القراءة الصوتية',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _PlaybackControls(controller: _controller),
                if (_controller.value.noticeMessage case final notice?) ...[
                  const SizedBox(height: 10),
                  Material(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        notice,
                        key: const ValueKey('reader-speech-voice-notice'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (engines.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    key: const ValueKey('reader-speech-engine-select'),
                    initialValue: selectedEngine,
                    decoration: const InputDecoration(
                      labelText: 'محرك الصوت',
                      prefixIcon: Icon(Icons.memory_rounded),
                    ),
                    items: [
                      for (final engine in engines)
                        DropdownMenuItem(value: engine, child: Text(engine)),
                    ],
                    onChanged: (value) => setState(() {
                      _selectedEngine = value;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _VoiceSelector(
                    voices: engineVoices,
                    preferences: preferences,
                    onSelected: _selectVoice,
                    onPreview: _controller.previewVoice,
                  ),
                ] else
                  const Text(
                    'اضغط تشغيل لاكتشاف الأصوات العربية المثبتة، أو نزّل صوتًا عربيًا من إعدادات الجهاز.',
                  ),
                const SizedBox(height: 18),
                Text(
                  'سرعة القراءة: ${(_draftRate ?? preferences.rate).toStringAsFixed(1)}×',
                ),
                Slider(
                  key: const ValueKey('reader-speech-rate-slider'),
                  value: _draftRate ?? preferences.rate,
                  min: ReaderSpeechPreferences.minRate,
                  max: ReaderSpeechPreferences.maxRate,
                  divisions: 15,
                  label:
                      '${(_draftRate ?? preferences.rate).toStringAsFixed(1)}×',
                  onChanged: (value) => setState(() => _draftRate = value),
                  onChangeEnd: (value) {
                    _draftRate = null;
                    unawaited(
                      _controller.updatePreferences(
                        preferences.copyWith(rate: value),
                      ),
                    );
                  },
                ),
                SwitchListTile(
                  key: const ValueKey('reader-speech-auto-next-toggle'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الانتقال تلقائيًا للفصل التالي'),
                  subtitle: const Text('متابعة الاستماع دون فتح إعلان بيني'),
                  value: preferences.autoNextChapter,
                  onChanged: (value) => unawaited(
                    _controller.updatePreferences(
                      preferences.copyWith(autoNextChapter: value),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ReaderSpeechSleepTimer>(
                  key: const ValueKey('reader-speech-sleep-timer'),
                  initialValue: _controller.sleepTimer,
                  decoration: const InputDecoration(
                    labelText: 'مؤقت النوم',
                    prefixIcon: Icon(Icons.bedtime_outlined),
                  ),
                  items: [
                    for (final timer in ReaderSpeechSleepTimer.values)
                      DropdownMenuItem(
                        value: timer,
                        child: Text(_sleepTimerLabel(timer)),
                      ),
                  ],
                  onChanged: (timer) {
                    if (timer != null) {
                      unawaited(_controller.setSleepTimer(timer));
                    }
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('reader-speech-manage-voices'),
                  onPressed: _manageVoices,
                  icon: const Icon(Icons.settings_voice_rounded),
                  label: const Text('إدارة أصوات الجهاز'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _effectiveEngine(
    List<String> engines,
    ReaderSpeechPreferences preferences,
  ) {
    if (engines.isEmpty) return null;
    if (_selectedEngine != null && engines.contains(_selectedEngine)) {
      return _selectedEngine;
    }
    if (preferences.engineId != null &&
        engines.contains(preferences.engineId)) {
      return preferences.engineId;
    }
    return engines.first;
  }

  Future<void> _selectVoice(ReaderSpeechVoice voice) async {
    var preferences = _controller.preferences;
    if (voice.networkRequired &&
        !preferences.approvedNetworkVoiceIds.contains(voice.id)) {
      final approved = await _confirmNetworkVoice();
      if (!approved || !mounted) return;
      preferences = preferences.approveNetworkVoice(voice.id);
    }
    await _controller.updatePreferences(
      preferences.copyWith(
        engineId: voice.engineId,
        voiceName: voice.name,
        voiceLocale: voice.locale,
      ),
    );
  }

  Future<bool> _confirmNetworkVoice() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('هذا الصوت يحتاج الإنترنت'),
            content: const Text(
              'قد يرسل محرك الصوت الخارجي نص القراءة لمعالجته خارج جهازك، وقد يستهلك بيانات الهاتف.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('أوافق وأستخدم الصوت'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _manageVoices() async {
    final opened =
        await (widget.onManageVoices?.call() ??
            const AppSystemSettings().openTextToSpeechSettings());
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر فتح إعدادات الأصوات على هذا الجهاز'),
        ),
      );
    }
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({required this.controller});

  final ReaderSpeechController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.value;
    final isPlaying = state.status == ReaderSpeechStatus.playing;
    final isLoading = state.status == ReaderSpeechStatus.loading;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'الفقرة السابقة',
              onPressed: controller.skipPreviousBlock,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: isPlaying
                  ? 'إيقاف القراءة الصوتية مؤقتًا'
                  : 'تشغيل القراءة الصوتية',
              onPressed: isLoading
                  ? null
                  : (isPlaying ? controller.pause : controller.play),
              icon: isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'الفقرة التالية',
              onPressed: controller.skipNextBlock,
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
        if (state.errorMessage case final message?) ...[
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}

class _VoiceSelector extends StatelessWidget {
  const _VoiceSelector({
    required this.voices,
    required this.preferences,
    required this.onSelected,
    required this.onPreview,
  });

  final List<ReaderSpeechVoice> voices;
  final ReaderSpeechPreferences preferences;
  final ValueChanged<ReaderSpeechVoice> onSelected;
  final ValueChanged<ReaderSpeechVoice> onPreview;

  @override
  Widget build(BuildContext context) {
    if (voices.isEmpty) return const SizedBox.shrink();
    final selected = voices.where((voice) {
      return voice.name == preferences.voiceName &&
          voice.locale == preferences.voiceLocale;
    }).firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: const ValueKey('reader-speech-voice-select'),
            initialValue: selected?.id,
            decoration: const InputDecoration(labelText: 'الصوت العربي'),
            hint: const Text('اختر صوتًا'),
            items: [
              for (final voice in voices)
                DropdownMenuItem(
                  value: voice.id,
                  child: Text(
                    '${voice.name} · ${_qualityLabel(voice.quality)} · ${voice.networkRequired ? 'Online' : 'Offline'}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (voiceId) {
              final voice = voices
                  .where((item) => item.id == voiceId)
                  .firstOrNull;
              if (voice != null) onSelected(voice);
            },
          ),
        ),
        IconButton(
          tooltip: 'تجربة الصوت',
          onPressed: selected == null ? null : () => onPreview(selected),
          icon: const Icon(Icons.volume_up_outlined),
        ),
      ],
    );
  }
}

String _speechStatusLabel(ReaderSpeechState state) {
  return switch (state.status) {
    ReaderSpeechStatus.idle => 'متوقف',
    ReaderSpeechStatus.loading => 'جارٍ تجهيز الصوت…',
    ReaderSpeechStatus.playing => 'الفقرة ${state.blockIndex + 1}',
    ReaderSpeechStatus.paused => 'متوقف مؤقتًا',
    ReaderSpeechStatus.error => state.errorMessage ?? 'تعذر تشغيل الصوت',
  };
}

String _qualityLabel(int quality) {
  if (quality >= 500) return 'ممتازة';
  if (quality >= 400) return 'عالية';
  if (quality >= 300) return 'عادية';
  return 'أساسية';
}

String _sleepTimerLabel(ReaderSpeechSleepTimer timer) {
  return switch (timer) {
    ReaderSpeechSleepTimer.off => 'بدون مؤقت',
    ReaderSpeechSleepTimer.minutes15 => '15 دقيقة',
    ReaderSpeechSleepTimer.minutes30 => '30 دقيقة',
    ReaderSpeechSleepTimer.minutes60 => '60 دقيقة',
    ReaderSpeechSleepTimer.endOfChapter => 'نهاية الفصل',
  };
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
