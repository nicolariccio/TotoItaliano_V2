import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(loginControllerProvider.notifier).submit(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(loginControllerProvider);
    final bool isLoading = state.isLoading;

    ref.listen(loginControllerProvider, (previous, next) {
      if (next.hasError) showFailureSnackBar(context, next.error!);
    });

    return Scaffold(
      body: TotoFormScaffoldBody(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: TotoSpace.x3l),
              const TotoScreenHeader(
                icon: Icons.sports_soccer_rounded,
                title: 'Bentornato',
                subtitle: 'Accedi per continuare a pronosticare.',
              ),
              const SizedBox(height: TotoSpace.x3l),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: Validators.email,
              ),
              const SizedBox(height: TotoSpace.lg),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => isLoading ? null : _submit(),
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostra password'
                        : 'Nascondi password',
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) =>
                    Validators.required(value, field: 'Password'),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(RoutePaths.forgotPassword),
                  child: const Text('Password dimenticata?'),
                ),
              ),
              const SizedBox(height: TotoSpace.sm),
              FilledButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const TotoButtonSpinner()
                    : const Text('Accedi'),
              ),
              const SizedBox(height: TotoSpace.md),
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(loginControllerProvider.notifier)
                        .submitWithGoogle(),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Continua con Google'),
              ),
              const SizedBox(height: TotoSpace.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Non hai un account?',
                      style: Theme.of(context).textTheme.bodyMedium),
                  TextButton(
                    onPressed: () => context.push(RoutePaths.register),
                    child: const Text('Registrati'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
