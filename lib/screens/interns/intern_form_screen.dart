import 'package:flutter/material.dart';
import 'package:manage_intern/modles/intern_model.dart';
import 'package:manage_intern/providers/intern_provider.dart';
import 'package:provider/provider.dart';

class InternFormScreen extends StatefulWidget {
  const InternFormScreen({super.key});

  @override
  State<InternFormScreen> createState() => _InternFormScreenState();
}

class _InternFormScreenState extends State<InternFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();

  int? _positionId;
  int? _batchId;
  String? _mentorId;
  DateTime? _startDate;
  DateTime? _endDate;

  String? _fullNameServerError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InternProvider>().loadFormMasterData();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  String _toApiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _toDisplayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime? _tryParse(String? s) => s == null ? null : DateTime.tryParse(s);

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _onBatchChanged(int? id, List<InternshipBatchSummaryModel> batches) {
    setState(() => _batchId = id);
    final batch = batches.where((b) => b.id == id).firstOrNull;
    if (batch == null) return;
    final s = _tryParse(batch.startDate);
    final e = _tryParse(batch.endDate);
    setState(() {
      if (s != null) _startDate = s;
      if (e != null) _endDate = e;
    });
  }

  Future<void> _submit() async {
    setState(() => _fullNameServerError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = context.read<InternProvider>();
    final ok = await provider.createIntern(InternCreationRequest(
      fullName: _fullNameController.text,
      positionId: _positionId!,
      mentorId: _mentorId!,
      startDate: _toApiDate(_startDate!),
      endDate: _toApiDate(_endDate!),
      internshipBatchId: _batchId!,
    ));

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm thực tập sinh thành công'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (provider.submitErrorCode == 'INVALID_FULLNAME') {
      setState(() => _fullNameServerError = provider.submitError);
    }
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required bool isStart,
    required FormFieldValidator<DateTime> validator,
  }) {
    return FormField<DateTime>(
      validator: (_) => validator(value),
      builder: (state) => InkWell(
        onTap: () async {
          await _pickDate(isStart: isStart);
          state.didChange(isStart ? _startDate : _endDate);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today_outlined),
            border: const OutlineInputBorder(),
            errorText: state.errorText,
          ),
          child: Text(value == null ? 'Chọn ngày' : _toDisplayDate(value)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InternProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm Thực Tập Sinh')),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(InternProvider provider) {
    if (provider.isFormDataLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.formDataError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.formDataError!,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: provider.loadFormMasterData,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final submitting = provider.isSubmitting;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.submitError != null &&
                provider.submitErrorCode != 'INVALID_FULLNAME') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(provider.submitError!,
                    style: const TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                if (_fullNameServerError != null) {
                  setState(() => _fullNameServerError = null);
                }
              },
              decoration: InputDecoration(
                labelText: 'Họ và tên',
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
                errorText: _fullNameServerError,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Vui lòng nhập họ tên'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _positionId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Vị trí thực tập',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              items: provider.positions
                  .map((p) =>
                      DropdownMenuItem(value: p.id, child: Text(p.title)))
                  .toList(),
              onChanged: (v) => setState(() => _positionId = v),
              validator: (v) => v == null ? 'Vui lòng chọn vị trí' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _batchId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Đợt thực tập',
                prefixIcon: Icon(Icons.groups_outlined),
                border: OutlineInputBorder(),
              ),
              items: provider.batches
                  .map(
                      (b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                  .toList(),
              onChanged: (v) => _onBatchChanged(v, provider.batches),
              validator: (v) => v == null ? 'Vui lòng chọn đợt thực tập' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _mentorId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Người hướng dẫn (Mentor)',
                prefixIcon: Icon(Icons.supervisor_account_outlined),
                border: OutlineInputBorder(),
              ),
              items: provider.mentors
                  .map((m) => DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.fullName}',
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _mentorId = v),
              validator: (v) => v == null ? 'Vui lòng chọn mentor' : null,
            ),
            const SizedBox(height: 16),
            _dateField(
              label: 'Ngày bắt đầu',
              value: _startDate,
              isStart: true,
              validator: (v) => v == null ? 'Vui lòng chọn ngày bắt đầu' : null,
            ),
            const SizedBox(height: 16),
            _dateField(
              label: 'Ngày kết thúc',
              value: _endDate,
              isStart: false,
              validator: (v) {
                if (v == null) return 'Vui lòng chọn ngày kết thúc';
                if (_startDate != null && v.isBefore(_startDate!)) {
                  return 'Ngày kết thúc phải sau ngày bắt đầu';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: submitting ? null : _submit,
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(submitting ? 'Đang lưu...' : 'Tạo mới'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
