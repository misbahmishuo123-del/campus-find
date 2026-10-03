import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../providers/item_provider.dart';

/// A single form used for both "Report Lost" and "Report Found" (screens 8 & 9).
class ReportItemScreen extends StatefulWidget {
  final String type; // 'lost' | 'found'
  const ReportItemScreen({super.key, required this.type});

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _color = TextEditingController();
  final _brand = TextEditingController();
  final _location = TextEditingController();
  final _imageUrl = TextEditingController();
  final _verQuestion = TextEditingController();
  final _verAnswer = TextEditingController();

  String _category = 'other';
  DateTime _date = DateTime.now();
  TimeOfDay? _time;
  bool _submitting = false;

  bool get isLost => widget.type == 'lost';

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _color.dispose();
    _brand.dispose();
    _location.dispose();
    _imageUrl.dispose();
    _verQuestion.dispose();
    _verAnswer.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    FocusScope.of(context).unfocus();

    final provider = context.read<ItemProvider>();
    final payload = <String, dynamic>{
      'type': widget.type,
      'title': _title.text.trim(),
      'category': _category,
      'description': _description.text.trim(),
      'color': _color.text.trim(),
      'brand': _brand.text.trim(),
      'location': _location.text.trim(),
      'date': _date.toIso8601String(),
      if (_time != null)
        'time':
            '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
      if (_imageUrl.text.trim().isNotEmpty) 'imageUrl': _imageUrl.text.trim(),
      if (_verAnswer.text.trim().isNotEmpty)
        'verificationAnswer': _verAnswer.text.trim(),
      if (_verQuestion.text.trim().isNotEmpty)
        'verificationQuestion': _verQuestion.text.trim(),
    };

    final id = await provider.createItem(payload);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${isLost ? 'Lost' : 'Found'} item reported successfully.'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Could not submit the item.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = isLost ? const Color(0xFFC62828) : const Color(0xFF00695C);
    return Scaffold(
      appBar: AppBar(
        title: Text(isLost ? 'Report Lost Item' : 'Report Found Item'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(isLost ? Icons.report_gmailerrorred : Icons.check_circle_outline,
                        color: accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isLost
                            ? 'Describe the item you lost so others can help identify it.'
                            : 'Describe the item you found. Add a secret verification question so the real owner can prove ownership.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(
                    labelText: 'Title *', hintText: 'e.g. Black leather wallet'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Enter a short title'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: AppConfig.itemCategories
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c[0].toUpperCase() + c.substring(1))))
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? 'other'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Distinctive details, contents, condition...'),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please add more detail (min 10 characters)'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _color,
                      decoration: const InputDecoration(labelText: 'Color'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _brand,
                      decoration: const InputDecoration(labelText: 'Brand'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                    labelText: 'Location *',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'e.g. Main Library, 2nd floor'),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Where was it ${isLost ? 'lost' : 'found'}?'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.event),
                      label: Text(DateFormat('MMM d, y').format(_date)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.schedule),
                      label: Text(_time == null
                          ? 'Time'
                          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Image URL (optional)',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user_outlined,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Hidden verification',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Optional. The answer is stored hashed on the server and is never shown publicly. A claimant must answer it to help staff verify ownership.',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _verQuestion,
                      decoration: const InputDecoration(
                        labelText: 'Verification question',
                        hintText: 'e.g. What is inside the front pocket?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _verAnswer,
                      decoration: const InputDecoration(
                        labelText: 'Secret answer',
                        hintText: 'Only you and security will use this',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: accent),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Text(isLost ? 'Submit Lost Report' : 'Submit Found Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
