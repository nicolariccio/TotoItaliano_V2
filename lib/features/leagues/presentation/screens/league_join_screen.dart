import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../providers/league_providers.dart';

class LeagueJoinScreen extends ConsumerStatefulWidget {
  const LeagueJoinScreen({super.key});

  @override
  ConsumerState<LeagueJoinScreen> createState() => _LeagueJoinScreenState();
}

class _LeagueJoinScreenState extends ConsumerState<LeagueJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isJoining = true);
    try {
      final league = await ref
          .read(leagueRepositoryProvider)
          .joinLeagueByInviteCode(_codeController.text.trim());
      if (!mounted) return;
      context.pushReplacement(RoutePaths.leagueDetailPath(league.id));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      showFailureSnackBar(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entra in lega')),
      body: TotoFormScaffoldBody(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TotoScreenHeader(
                icon: Icons.qr_code_rounded,
                title: 'Entra in una lega',
                subtitle:
                    'Inserisci il codice invito condiviso da chi ha creato la lega.',
              ),
              const SizedBox(height: TotoSpace.xxl),
              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _isJoining ? null : _submit(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(letterSpacing: 1.2),
                decoration: const InputDecoration(
                    labelText: 'Codice invito', hintText: 'TOTO-8K4P2'),
                validator: Validators.inviteCode,
              ),
              const SizedBox(height: TotoSpace.xxl),
              FilledButton(
                onPressed: _isJoining ? null : _submit,
                child: _isJoining
                    ? const TotoButtonSpinner()
                    : const Text('Entra'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
