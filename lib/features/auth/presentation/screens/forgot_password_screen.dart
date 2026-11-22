import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/toto_theme.dart';
import '../../../../core/utils/error_snackbar.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/toto_widgets.dart';
import '../controllers/forgot_password_controller.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_emailController.text.trim());
    if (!mounted) return;
    if (!ref.read(forgotPasswordControllerProvider).hasError) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordControllerProvider);
    final bool isLoading = state.isLoading;

    ref.listen(forgotPasswordControllerProvider, (previous, next) {
      if (next.hasError) showFailureSnackBar(context, next.error!);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Password dimenticata')),
      body: TotoFormScaffoldBody(
        child: AnimatedSwitcher(
          duration: TotoMotion.base,
          child: _sent
              ? Column(
                  key: const ValueKey('sent'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: TotoSpace.x3l),
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: context.c.successContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.c.successBorder),
                        ),
                        child: Icon(Icons.mark_email_read_rounded,
                            size: 40, color: context.c.success),
                      ),
                    ),
                    const SizedBox(height: TotoSpace.xxl),
                    Text('Controlla la tua email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: TotoSpace.sm),
                    Text(
                      'Ti abbiamo inviato un\'email con le istruzioni per reimpostare la password.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    key: const ValueKey('form'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TotoScreenHeader(
                        icon: Icons.lock_reset_rounded,
                        title: 'Reimposta password',
                        subtitle:
                            'Inserisci la tua email: ti invieremo un link per reimpostare la password.',
                      ),
                      const SizedBox(height: TotoSpace.xxl),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: Validators.email,
                      ),
                      const SizedBox(height: TotoSpace.xxl),
                      FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const TotoButtonSpinner()
                            : const Text('Invia'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
