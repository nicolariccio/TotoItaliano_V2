import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/utils/validators.dart';
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Inserisci il codice invito condiviso da chi ha creato la lega.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                      labelText: 'Codice invito', hintText: 'TOTO-8K4P2'),
                  validator: Validators.inviteCode,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isJoining ? null : _submit,
                  child: _isJoining
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Entra'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
