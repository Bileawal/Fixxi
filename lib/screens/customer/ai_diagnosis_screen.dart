import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/diagnosis_result.dart';
import '../../models/service_request.dart';
import '../../providers/app_state.dart';
import '../../services/ai_diagnosis_engine.dart';
import '../../services/ai_learning_service.dart';
import '../../services/diagnosis_i18n.dart';
import '../../services/nlp_language.dart';
import '../../services/voice_input_service.dart';
import 'create_request_screen.dart';
import 'select_technician_screen.dart';

/// ─── Flow ────────────────────────────────────────────────────────────────────
/// 1. User types/speaks → AI analyzes
/// 2a. LOW RISK  → Show checks + safety. Ask "Problem solved?"
///        → YES  → Done ✓
///        → NO   → Show cost estimation + Contact Technician button
/// 2b. HIGH RISK → Show safety + checks immediately + Contact Technician button
///        (Cost estimation shown after user taps "Show Cost Estimate" button)
class AIDiagnosisScreen extends StatefulWidget {
  const AIDiagnosisScreen({super.key});

  @override
  State<AIDiagnosisScreen> createState() => _AIDiagnosisScreenState();
}

class _AIDiagnosisScreenState extends State<AIDiagnosisScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _engine = AiDiagnosisEngine.shared;
  final _learning = AiLearningService();
  final _voice = VoiceInputService();

  bool _engineReady = false;
  String? _engineError;
  bool _analyzing = false;
  bool _listening = false;
  bool _voiceConsumed = false;
  String _voiceText = '';
  ReplyLang _lang = ReplyLang.english;

  String? _userMessage;
  DiagnosisResult? _result;

  AiCopy get _copy => AiCopy(_result?.replyLang ?? _lang);

  /// Cost sirf tab jab user "Nahi" dabaye (simple checks se masla nahi hua).
  bool _askedIfSolved = false;
  bool _problemSolved = false;
  bool _showCostEstimate = false;

  @override
  void initState() {
    super.initState();
    _textCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _setupVoice();
    _bootEngine();
  }

  void _setupVoice() {
    _voice.onPartial = (t) {
      if (!mounted || _voiceConsumed) return;
      _textCtrl.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: t.length),
      );
      setState(() => _voiceText = t);
    };
    _voice.onFinal = (t) {
      if (!mounted) return;
      if (_voiceConsumed) return;
      _voiceConsumed = true;
      setState(() {
        _voiceText = t;
        _textCtrl.text = t;
        _listening = false;
      });
      _analyze(t);
    };
    _voice.onError = (msg) {
      if (!mounted) return;
      setState(() => _listening = false);
      _snack(msg);
    };
    _voice.onListeningChanged = (v) {
      if (mounted) setState(() => _listening = v);
    };
    _voice.initialize();
  }

  Future<void> _bootEngine() async {
    try {
      await _engine.initialize();
      if (mounted) setState(() => _engineReady = true);
      // Firebase learning is optional — do not block first diagnosis on it.
      _learning.getLearnedPatterns();
    } catch (e) {
      if (mounted) setState(() => _engineError = 'Dataset load nahi hua: $e');
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    _voice.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _voice.stopListening();
      return;
    }
    setState(() {
      _voiceText = '';
      _voiceConsumed = false;
    });
    final started = await _voice.startListening();
    if (!started && mounted) {
      _snack(_voice.initError ??
          'Voice input is not available. Please type your problem.');
    } else if (mounted) {
      _snack(_copy.listeningHint);
    }
  }

  // ── Analyze ────────────────────────────────────────────────────────────────
  Future<void> _analyze([String? override, String? applianceId]) async {
    final typed = _textCtrl.text.trim();
    final text =
        (override ?? (typed.isNotEmpty ? typed : _userMessage) ?? '').trim();
    if (text.isEmpty || _analyzing) return;
    if (!_engineReady) {
      _snack(_engineError ?? 'AI is still loading, please wait…');
      return;
    }

    final lang = NlpLanguage.detect(text);
    setState(() {
      _lang = lang;
      _analyzing = true;
      _userMessage = text;
      _result = null;
      _askedIfSolved = false;
      _problemSolved = false;
      _showCostEstimate = false;
      if (applianceId == null) _textCtrl.clear();
    });
    _scrollDown();

    try {
      final result = await _engine.analyze(
        text,
        forcedApplianceId: applianceId,
        learningService: _learning,
      );
      if (!mounted) return;
      setState(() {
        _lang = result.replyLang;
        _result = result;
        _analyzing = false;
        _askedIfSolved = !result.needsApplianceChoice &&
            result.riskLevel != RiskLevel.unknown;
      });
      _scrollDown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      _snack('Analysis failed: $e');
    }
  }

  // ── Low-risk answer ────────────────────────────────────────────────────────
  void _onSolvedAnswer(bool yes) {
    if (yes) {
      setState(() {
        _problemSolved = true;
        _askedIfSolved = false;
      });
    } else {
      setState(() {
        _showCostEstimate = true;
        _askedIfSolved = false;
      });
      _scrollDown();
    }
  }

  // ── Book technician ────────────────────────────────────────────────────────
  Future<void> _bookTechnician() async {
    if (_result == null) return;

    final choice = await showModalBottomSheet<_BookingChoice>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BookingSheet(
        appliance: _result!.applianceName,
        lang: _result!.replyLang,
      ),
    );

    if (choice == null || !mounted || _result == null) return;

    final body = {
      'category': _result!.category,
      'description': '${_result!.applianceName}: ${_result!.rawInput}',
      'type': choice == _BookingChoice.urgent
          ? RequestType.urgent.name
          : RequestType.scheduled.name,
      'address': context.read<AppState>().currentUser?.address ?? '',
    };

    if (choice == _BookingChoice.urgent) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              SelectTechnicianScreen(requestBody: body, isUrgent: true),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateRequestScreen(
            initialCategory: _result!.category,
            initialDescription:
                '${_result!.applianceName}: ${_result!.rawInput}',
            initialType: RequestType.scheduled,
          ),
        ),
      );
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _userMessage = null;
      _analyzing = false;
      _askedIfSolved = false;
      _problemSolved = false;
      _showCostEstimate = false;
      _textCtrl.clear();
    });
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final showInput = _result == null && !_analyzing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnostic Engine'),
        actions: [
          if (_result != null || _userMessage != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Naya masla',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_engineError != null)
            MaterialBanner(
              content: Text(_engineError!),
              backgroundColor: Colors.red.shade50,
              actions: [
                TextButton(onPressed: _bootEngine, child: const Text('Retry'))
              ],
            ),
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                _introCard(),
                if (_userMessage != null) _userBubble(_userMessage!),
                if (_analyzing) _loadingBubble(),
                if (_result != null) ...[
                  if (_result!.needsApplianceChoice) ..._buildChooseAppliance(),
                  if (!_result!.needsApplianceChoice && _result!.isLowRisk)
                    ..._buildLowRiskFlow(),
                  if (!_result!.needsApplianceChoice && _result!.isHighRisk)
                    ..._buildHighRiskFlow(),
                ],
                if (_problemSolved) _solvedCard(),
              ],
            ),
          ),
          if (showInput ||
              _problemSolved ||
              (_result?.needsApplianceChoice ?? false))
            _inputBar(),
        ],
      ),
    );
  }

  // ── LOW RISK FLOW ──────────────────────────────────────────────────────────
  List<Widget> _buildLowRiskFlow() {
    final r = _result!;
    final c = _copy;
    return [
      _riskBadge(
        r,
        Colors.green.shade700,
        '🟢 LOW RISK — ${r.applianceName}${r.symptomLabel == null ? '' : ' • ${r.symptomLabel}'}',
      ),
      _section(c.simpleChecks, Icons.build_outlined, r.diagnosticSteps,
          numbered: true, color: Colors.blue.shade700),
      _section(c.safety, Icons.health_and_safety_outlined, r.safetyPrecautions,
          color: Colors.orange.shade700),
      if (_askedIfSolved && !_problemSolved && !_showCostEstimate)
        _solvedQuestion(),
      if (_showCostEstimate) ...[
        const SizedBox(height: 8),
        _aiBubble(c.lowChecksFailed),
        _costEstimationSection(r),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: FilledButton.icon(
            onPressed: _bookTechnician,
            icon: const Icon(Icons.engineering),
            label: Text(c.contactTech),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF1E3A8A),
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildHighRiskFlow() {
    final r = _result!;
    final c = _copy;
    return [
      _riskBadge(
        r,
        Colors.red.shade700,
        '🔴 HIGH RISK — ${r.applianceName}${r.symptomLabel == null ? '' : ' • ${r.symptomLabel}'}',
      ),
      _aiBubble(c.highWarn('')),
      _section(c.immediateSafety, Icons.health_and_safety_outlined,
          r.safetyPrecautions,
          color: Colors.red.shade700),
      _section(c.diagnosticSteps, Icons.checklist_outlined, r.diagnosticSteps,
          numbered: true, color: Colors.orange.shade800),
      if (_askedIfSolved && !_problemSolved && !_showCostEstimate)
        _solvedQuestion(highRisk: true),
      if (_showCostEstimate) ...[
        const SizedBox(height: 8),
        _aiBubble(c.highCosts(r.applianceName)),
        _costEstimationSection(r),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: FilledButton.icon(
            onPressed: _bookTechnician,
            icon: const Icon(Icons.engineering),
            label: Text(c.contactTech),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF1E3A8A),
            ),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildChooseAppliance() {
    final r = _result!;
    final c = _copy;
    return [
      if (r.isHighRisk)
        _riskBadge(r, Colors.red.shade700, c.highPick),
      _aiBubble(r.summary),
      if (r.safetyPrecautions.isNotEmpty)
        _section(c.immediateSafety, Icons.health_and_safety_outlined,
            r.safetyPrecautions,
            color: Colors.red.shade700),
      const SizedBox(height: 4),
      Text(c.pickItem,
          style:
              TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _engine.applianceCatalog.map((opt) {
          return ActionChip(
            label: Text(opt.label, style: const TextStyle(fontSize: 12)),
            onPressed: _analyzing ? null : () => _analyze(_userMessage, opt.id),
          );
        }).toList(),
      ),
    ];
  }

  // ── COST ESTIMATION ────────────────────────────────────────────────────────
  Widget _costEstimationSection(DiagnosisResult r) {
    final c = _copy;
    if (r.possibleIssues.isEmpty) {
      final fee = r.visitFeeLabel ?? 'Rs 300–500 per visit';
      return _aiBubble(c.noCost(r.applianceName, fee));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: r.possibleIssues.map((issue) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.ifIssue(issue.title),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  c.estCost(issue.estimatedCostMin, issue.estimatedCostMax),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEA580C),
                    fontSize: 15,
                  ),
                ),
                if (issue.partsCost != null || issue.laborCost != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [issue.partsCost, issue.laborCost]
                        .whereType<String>()
                        .join('  •  '),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
                if (issue.causes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      issue.causes.first,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[700], height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── WIDGETS ────────────────────────────────────────────────────────────────
  Widget _introCard() {
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        'Describe your problem',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
        decoration: BoxDecoration(
          color: const Color(0xFFEA580C),
          borderRadius:
              BorderRadius.circular(16).copyWith(bottomRight: Radius.zero),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _aiBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius:
              BorderRadius.circular(16).copyWith(bottomLeft: Radius.zero),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.black87, fontSize: 13, height: 1.4)),
      ),
    );
  }

  Widget _loadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF1E3A8A))),
              const SizedBox(width: 10),
              Text(_copy.analyzing,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _riskBadge(DiagnosisResult r, Color color, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          ),
          Chip(
            label: Text('${(r.confidence * 100).round()}% match'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            backgroundColor: color.withOpacity(0.12),
            labelStyle: TextStyle(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<String> items,
      {bool numbered = false, Color? color}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: color ?? const Color(0xFFEA580C)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14))),
            ]),
            const SizedBox(height: 10),
            ...items.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(numbered ? '${e.key + 1}. ' : '• ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color ?? const Color(0xFFEA580C))),
                      Expanded(
                          child: Text(e.value,
                              style:
                                  const TextStyle(fontSize: 13, height: 1.4))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _solvedQuestion({bool highRisk = false}) {
    final c = _copy;
    return Card(
      color: highRisk ? Colors.red.shade50 : Colors.blue.shade50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              highRisk ? c.safetyQ : c.solvedQ,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _onSolvedAnswer(false),
                    icon: const Icon(Icons.close, size: 18),
                    label: Text(highRisk ? c.needTech : c.no),
                    style:
                        OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _onSolvedAnswer(true),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(highRisk ? c.yesControl : c.yes),
                    style:
                        FilledButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _solvedCard() {
    final c = _copy;
    return Card(
      color: Colors.green.shade50,
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.celebration, color: Colors.green, size: 40),
            const SizedBox(height: 8),
            Text(c.solvedTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(c.solvedSub, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    final c = _copy;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textCtrl,
                enabled: !_analyzing,
                decoration: InputDecoration(
                  hintText: _result != null ? c.hintMore : c.hintEmpty,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: _analyze,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _listening ? Icons.mic : Icons.mic_none,
                color: _listening ? Colors.red : Colors.grey[700],
              ),
              onPressed: _toggleVoice,
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: (_analyzing || _textCtrl.text.trim().isEmpty)
                  ? null
                  : _analyze,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                backgroundColor: const Color(0xFFEA580C),
              ),
              child: _analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Booking Sheet ─────────────────────────────────────────────────────────────
enum _BookingChoice { urgent, scheduled }

class _BookingSheet extends StatelessWidget {
  const _BookingSheet({required this.appliance, required this.lang});
  final String appliance;
  final ReplyLang lang;

  @override
  Widget build(BuildContext context) {
    final c = AiCopy(lang);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(c.bookingTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(c.bookingSub(appliance),
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _BookingChoice.urgent),
              icon: const Icon(Icons.flash_on),
              label: Text(c.urgent),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, _BookingChoice.scheduled),
              icon: const Icon(Icons.calendar_month),
              label: Text(c.schedule),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
