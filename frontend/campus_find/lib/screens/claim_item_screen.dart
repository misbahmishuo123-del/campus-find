import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/claim_provider.dart';

/// Screen 12: submit a claim on an item.
class ClaimItemScreen extends StatefulWidget {
  final Item item;
  const ClaimItemScreen({super.key, required this.item});

  @override
  State<ClaimItemScreen> createState() => _ClaimItemScreenState();
}

class _ClaimItemScreenState extends State<ClaimItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _answer = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reason.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final provider = context.read<ClaimProvider>();
    final ok = await provider.submitClaim(
      itemId: widget.item.id,
      reason: _reason.text.trim(),
      verificationAnswer: _answer.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.hourglass_top, size: 40),
          title: const Text('Claim submitted'),
          content: const Text(
            'Your claim has been submitted and is pending review. University security will verify ownership and notify you of the decision. A match alone does not confirm ownership.',
          ),
          actions: [
            FilledButton(
                onPressed: () {
                  Navigator.of(context)
                    ..pop() // dialog
                    ..pop(); // back to item details
                },
                child: const Text('Done')),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Could not submit claim'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.item.verificationQuestion;
    return Scaffold(
      appBar: AppBar(title: const Text('Claim Item')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.item.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text('${widget.item.type.toUpperCase()} • ${widget.item.location}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _reason,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Why is this yours? *',
                  hintText:
                      'Describe identifying details, contents, or circumstances...',
                ),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Please explain your claim (min 10 characters)'
                    : null,
              ),
              const SizedBox(height: 16),
              if (question != null && question.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF283593).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.help_outline,
                          color: Color(0xFF283593)),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Verification: $question',
                          style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _answer,
                decoration: InputDecoration(
                  labelText: question != null && question.isNotEmpty
                      ? 'Your answer *'
                      : 'Verification answer (optional)',
                  hintText: 'Used by staff to confirm ownership',
                ),
                validator: (v) {
                  if (question != null &&
                      question.isNotEmpty &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Please answer the verification question';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Submit claim'),
              ),
              const SizedBox(height: 12),
              Text(
                'Submitting a claim does not transfer ownership. Only authorized university staff can approve it after verification.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
