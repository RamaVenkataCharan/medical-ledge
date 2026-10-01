import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key, this.customerId});
  final String? customerId;

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool _isLoadingExisting = false;
  String? _error;

  bool get _isEdit => widget.customerId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _loadExisting();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _villageCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoadingExisting = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;
      final res = await _supabase
          .from('customers')
          .select('name, phone, village, address, notes')
          .eq('id', widget.customerId!)
          .eq('owner_id', uid)
          .single();
      _nameCtrl.text = res['name'] as String? ?? '';
      _phoneCtrl.text = res['phone'] as String? ?? '';
      _villageCtrl.text = res['village'] as String? ?? '';
      _addressCtrl.text = res['address'] as String? ?? '';
      _notesCtrl.text = res['notes'] as String? ?? '';
    } catch (e) {
      setState(() => _error = 'Failed to load customer data.');
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      setState(() { _isLoading = false; _error = 'Not logged in.'; });
      return;
    }

    final data = {
      'owner_id': uid,
      'name': _nameCtrl.text.trim(),
      'phone': PhoneValidator.clean(_phoneCtrl.text.trim()),
      'village': _villageCtrl.text.trim().isEmpty ? null : _villageCtrl.text.trim(),
      'address': _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await _supabase
            .from('customers')
            .update(data)
            .eq('id', widget.customerId!)
            .eq('owner_id', uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer updated successfully')),
          );
          context.pop();
        }
      } else {
        await _supabase.from('customers').insert(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${_nameCtrl.text.trim()} added!')),
          );
          context.pop();
        }
      }
    } on PostgrestException catch (e) {
      String msg = 'Failed to save customer.';
      if (e.code == '23505') {
        msg = 'A customer with this phone number already exists.';
      }
      setState(() => _error = msg);
    } catch (_) {
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Customer' : 'Add Customer'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
      ),
      body: _isLoadingExisting
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar preview
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primaryTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: AppColors.primary, size: 36),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error banner
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.danger, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_error!,
                                  style: AppTextStyles.bodySmall
                                      .copyWith(color: AppColors.danger)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    _SectionLabel('Customer Info'),
                    const SizedBox(height: 12),

                    // Name
                    _FieldLabel('Full Name *'),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Ramesh Kumar',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: Validators.name,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    _FieldLabel('Mobile Number *'),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        hintText: '9876543210',
                        prefixIcon: Icon(Icons.phone_outlined),
                        prefixText: '+91 ',
                      ),
                      validator: PhoneValidator.validate,
                    ),
                    const SizedBox(height: 16),

                    // Village
                    _FieldLabel('Village / Area'),
                    TextFormField(
                      controller: _villageCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Kondapur',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    _FieldLabel('Full Address'),
                    TextFormField(
                      controller: _addressCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Street, area, city…',
                        prefixIcon: Icon(Icons.home_outlined),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    _FieldLabel('Notes'),
                    TextFormField(
                      controller: _notesCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Any additional notes about this customer…',
                        prefixIcon: Icon(Icons.notes_rounded),
                        alignLabelWithHint: true,
                      ),
                    ),

                    const SizedBox(height: 32),

                    PrimaryButton(
                      label: _isEdit ? 'Save Changes' : 'Add Customer',
                      icon: _isEdit ? Icons.save_rounded : Icons.person_add_rounded,
                      onPressed: _save,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(label, style: AppTextStyles.labelLarge),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.border),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: AppTextStyles.labelSmall),
        ),
        Expanded(
          child: Divider(color: AppColors.border),
        ),
      ],
    );
  }
}
