import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../providers/league_providers.dart';

class LeagueCreateScreen extends ConsumerStatefulWidget {
  const LeagueCreateScreen({super.key});

  @override
  ConsumerState<LeagueCreateScreen> createState() => _LeagueCreateScreenState();
}

class _LeagueCreateScreenState extends ConsumerState<LeagueCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final leagueId = await ref.read(leagueRepositoryProvider).createLeague(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );
      if (!mounted) return;
      context.pushReplacement(RoutePaths.leagueDetailPath(leagueId));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showFailureSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crea lega')),
      body: TotoFormScaffoldBody(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TotoScreenHeader(
                icon: Icons.shield_rounded,
                title: 'Nuova lega',
                subtitle:
                    'Crea una lega privata e invita gli amici con il codice.',
              ),
              const SizedBox(height: TotoSpace.xxl),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nome lega'),
                validator: (v) => Validators.required(v, field: 'Nome'),
              ),
              const SizedBox(height: TotoSpace.lg),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    const InputDecoration(labelText: 'Descrizione (opzionale)'),
                minLines: 3,
                maxLines: 4,
              ),
              const SizedBox(height: TotoSpace.xxl),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const TotoButtonSpinner()
                    : const Text('Crea lega'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
