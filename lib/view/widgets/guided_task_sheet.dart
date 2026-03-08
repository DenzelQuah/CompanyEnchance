import 'package:companyenchancer/model/app_theme.dart';
import 'package:flutter/material.dart';


// ─── Local Constants (Copied from main file to ensure independence) ───────────
const _kOrangeBg     = Color(0x1AFF9800);
const _kOrangeBorder = Color(0x66FF9800);
const _kGray50       = Color(0xFFF9FAFB);
const _kGray100      = Color(0xFFF3F4F6);
const _kGray200      = Color(0xFFE5E7EB);
const _kBorderFaint  = Color(0x99E5E7EB);

class GuidedTaskSheet extends StatefulWidget {
  final int stepIndex;
  final int totalSteps;
  final String stepText;
  final String location;
  final List<String> microTasks;
  final VoidCallback onSosPressed;
  final VoidCallback onConfirmedDone;

  const GuidedTaskSheet({
    super.key,
    required this.stepIndex,
    required this.totalSteps,
    required this.stepText,
    required this.location,
    required this.microTasks,
    required this.onSosPressed,
    required this.onConfirmedDone,
  });

  @override
  State<GuidedTaskSheet> createState() => _GuidedTaskSheetState();
}

class _GuidedTaskSheetState extends State<GuidedTaskSheet> {
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List.filled(widget.microTasks.length, false);
  }

  bool get _allChecked => _checked.every((c) => c);
  int get _doneCount => _checked.where((c) => c).length;

  @override
  Widget build(BuildContext context) {
    final stepNum = widget.stepIndex + 1;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(color: _kGray200,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.bluePale,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Step $stepNum of ${widget.totalSteps}',
                      style: const TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w700, color: AppTheme.blue)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: _kGray100,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.close_rounded, size: 16,
                        color: AppTheme.textMuted),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('YOUR TASK',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                          color: Colors.white54, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(widget.stepText, style: const TextStyle(fontSize: 14,
                      fontWeight: FontWeight.w700, color: Colors.white, height: 1.4)),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Text('$_doneCount/${widget.microTasks.length} actions done',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted)),
                const Spacer(),
                Text(_allChecked ? '✅ Ready to mark done!' : 'Check each action below',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: _allChecked ? AppTheme.green : AppTheme.textMuted)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _checked.isEmpty ? 0 : _doneCount / _checked.length,
                  minHeight: 6,
                  backgroundColor: _kGray200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      _allChecked ? AppTheme.green : AppTheme.blue),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          const Divider(height: 16),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              itemCount: widget.microTasks.length + 2, // +header +sos
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text('DO THESE ACTIONS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 1, color: AppTheme.textMuted)),
                  );
                }
                if (i == widget.microTasks.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    child: GestureDetector(
                      onTap: widget.onSosPressed,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _kOrangeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _kOrangeBorder),
                        ),
                        child: Row(children: [
                          const Text('🆘', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Stuck? Get AI Guidance',
                                  style: TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange)),
                              Text(
                                'Nexus AI will walk you through each action '
                                'step-by-step for ${widget.location}.',
                                style: const TextStyle(fontSize: 11,
                                    color: AppTheme.textMuted, height: 1.4),
                              ),
                            ],
                          )),
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.orange, size: 20),
                        ]),
                      ),
                    ),
                  );
                }
                final taskIdx  = i - 1;
                final task     = widget.microTasks[taskIdx];
                final done     = _checked[taskIdx];
                final unlocked = taskIdx == 0 || _checked[taskIdx - 1];
                return GestureDetector(
                  onTap: unlocked ? () => setState(() => _checked[taskIdx] = !done) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: done ? AppTheme.greenPale
                          : unlocked ? Colors.white : _kGray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: done ? AppTheme.green
                            : unlocked ? AppTheme.blue : AppTheme.border,
                        width: done || unlocked ? 1.5 : 1,
                      ),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: done ? AppTheme.green
                              : unlocked ? Colors.white : _kGray200,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done ? AppTheme.green
                                : unlocked ? AppTheme.blue : AppTheme.border,
                            width: 1.5,
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                            : !unlocked
                                ? const Icon(Icons.lock_rounded, color: AppTheme.textMuted, size: 13)
                                : Center(child: Text('${taskIdx + 1}',
                                    style: const TextStyle(fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.blue))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(task, style: TextStyle(
                        fontSize: 13, height: 1.45,
                        fontWeight: unlocked && !done ? FontWeight.w600 : FontWeight.w500,
                        color: done ? AppTheme.green
                            : unlocked ? AppTheme.textPrimary : AppTheme.textMuted,
                        decoration: done ? TextDecoration.lineThrough : null,
                        decorationColor: AppTheme.green,
                      ))),
                    ]),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: _kBorderFaint)),
            ),
            child: Column(children: [
              if (!_allChecked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${widget.microTasks.length - _doneCount} action'
                    '${widget.microTasks.length - _doneCount == 1 ? '' : 's'} '
                    'remaining — complete them to mark this step done.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12,
                        color: AppTheme.textMuted, height: 1.4),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allChecked ? widget.onConfirmedDone : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.green,
                    disabledBackgroundColor: _kGray200,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: _allChecked ? 3 : 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _allChecked
                        ? '✅  Mark Step $stepNum as Done'
                        : 'Complete all actions above first',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: _allChecked ? Colors.white : AppTheme.textMuted),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}