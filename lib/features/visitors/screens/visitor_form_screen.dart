import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_failure.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/step_indicator.dart';
import '../data/visitor.dart';
import '../state/visitor_providers.dart';

class VisitorFormScreen extends ConsumerStatefulWidget {
  const VisitorFormScreen({super.key, this.visitorId});

  final String? visitorId;

  bool get isEditing => visitorId != null;

  @override
  ConsumerState<VisitorFormScreen> createState() => _VisitorFormScreenState();
}

class _VisitorFormScreenState extends ConsumerState<VisitorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _purposeController = TextEditingController();

  String? _visitorType;
  String? _project;
  bool _isSaving = false;

  Visitor? _original;

  @override
  void initState() {
    super.initState();
    final id = widget.visitorId;
    if (id == null) return;

    final existing = ref.read(visitorByIdProvider(id));
    if (existing == null) return;

    _original = existing;
    _nameController.text = existing.name;
    _mobileController.text = existing.mobile;
    _emailController.text = existing.email ?? '';
    _purposeController.text = existing.purpose;
    _visitorType = VisitorOptions.types.contains(existing.visitorType)
        ? existing.visitorType
        : null;
    _project = VisitorOptions.projects.contains(existing.project)
        ? existing.project
        : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      AppFeedback.error(context, 'Please correct the highlighted fields');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(visitorListProvider.notifier);

      if (widget.isEditing) {
        final original = _original!;
        final updated = original.copyWith(
          name: _nameController.text,
          mobile: _mobileController.text,
          email: () => _emailController.text,
          visitorType: _visitorType,
          project: _project,
          purpose: _purposeController.text,
        );
        await notifier.edit(updated);

        if (!mounted) return;
        AppFeedback.success(context, 'Visitor details updated');
        context.pop();
      } else {
        final result = await notifier.register(
          Visitor.draft(
            name: _nameController.text,
            mobile: _mobileController.text,
            email: _emailController.text,
            visitorType: _visitorType!,
            project: _project!,
            purpose: _purposeController.text,
          ),
        );

        if (!mounted) return;
        final created = result.visitor;
        final delivery = result.delivery;

        if (delivery == null) {
          AppFeedback.success(context, '${created.name} registered successfully');
        } else if (delivery.sent) {
          AppFeedback.success(
            context,
            '${created.name} registered. Pass link emailed.',
          );
        } else {
          AppFeedback.info(
            context,
            '${created.name} registered, but the pass email was not sent. '
            'Share the link from their details instead.',
          );
        }

        context.pushReplacement('/visitors/${created.id}');
      }
    } on ApiFailure catch (failure) {
      if (mounted) AppFeedback.error(context, failure.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing && _original == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Visitor')),
        body: const EmptyStateView(
          icon: Icons.person_off_outlined,
          title: 'Visitor not found',
          message:
              'This record is no longer in the list. It may have been deleted.',
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              ScreenHeader(
                title: widget.isEditing ? 'Edit Visitor' : 'Register Visitor',
                subtitle: widget.isEditing
                    ? 'Update this visitor\'s information.'
                    : 'Add visitor information to create a secure entry pass.',
                compactTitle: true,
                leading: SquareIconButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                ),
              ),
              if (!widget.isEditing)
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.md,
                  ),
                  child: StepIndicator(
                    steps: ['Visitor details', 'Pass issued'],
                    currentIndex: 0,
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    AppSpacing.lg,
                  ),
                  children: [
                    SectionCard(
                      title: 'Personal details',
                      subtitle: "Enter the visitor's basic information.",
                      icon: Icons.person_outline_rounded,
                      children: [
                        CustomTextField(
                          label: 'Visitor Name',
                          hint: 'e.g. Rahul Sharma',
                          controller: _nameController,
                          isRequired: true,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (value) => Validators.requiredField(
                            value,
                            label: 'Visitor name',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          label: 'Mobile Number',
                          hint: '10 digit mobile number',
                          controller: _mobileController,
                          isRequired: true,
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          textCapitalization: TextCapitalization.none,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: Validators.mobile,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          label: 'Email',
                          hint: 'Optional — their pass link is sent here',
                          controller: _emailController,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textCapitalization: TextCapitalization.none,
                          validator: Validators.optionalEmail,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SectionCard(
                      title: 'Visit details',
                      subtitle: 'Provide visit information.',
                      icon: Icons.apartment_rounded,
                      children: [
                        CustomDropdownField<String>(
                          label: 'Visitor Type',
                          hint: 'Select visitor type',
                          isRequired: true,
                          prefixIcon: Icons.badge_outlined,
                          value: _visitorType,
                          items: VisitorOptions.types,
                          onChanged: (value) =>
                              setState(() => _visitorType = value),
                          validator: (value) => Validators.requiredChoice(
                            value,
                            label: 'a visitor type',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomDropdownField<String>(
                          label: 'Project',
                          hint: 'Select project',
                          isRequired: true,
                          prefixIcon: Icons.apartment_outlined,
                          value: _project,
                          items: VisitorOptions.projects,
                          onChanged: (value) => setState(() => _project = value),
                          validator: (value) => Validators.requiredChoice(
                            value,
                            label: 'a project',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          label: 'Purpose of Visit',
                          hint: 'e.g. Site visit',
                          controller: _purposeController,
                          isRequired: true,
                          prefixIcon: Icons.notes_rounded,
                          maxLines: 3,
                          maxLength: 200,
                          showCounter: true,
                          textInputAction: TextInputAction.done,
                          validator: (value) => Validators.requiredField(
                            value,
                            label: 'Purpose of visit',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: StickyFooter(
        children: [
          CustomButton(
            label: widget.isEditing ? 'Save changes' : 'Register visitor',
            icon: widget.isEditing
                ? Icons.check_rounded
                : Icons.person_add_alt_1_rounded,
            isLoading: _isSaving,
            onPressed: _save,
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          CustomButton(
            label: 'Cancel',
            variant: CustomButtonVariant.secondary,
            onPressed: _isSaving ? null : () => context.pop(),
          ),
        ],
      ),
    );
  }
}
