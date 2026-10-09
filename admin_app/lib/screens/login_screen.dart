import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/auth_state.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _invite = TextEditingController();
  bool _register = false, _busy = false, _hide = true;

  @override
  void dispose() {
    for (final c in [_email, _password, _name, _invite]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    try {
      if (_register) {
        await auth.register(_email.text, _password.text, _name.text, _invite.text);
      } else {
        await auth.login(_email.text, _password.text);
      }
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Icon(Icons.cake_rounded, size: 56, color: orange),
                  const SizedBox(height: 8),
                  Text('Bakery Studio', textAlign: TextAlign.center, style: script(size: 44)),
                  Text(_register ? 'Create your owner account' : 'Welcome back',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 28),
                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      decoration: deco('Bakery name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your bakery name' : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                    controller: _email,
                    decoration: deco('Email'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _hide,
                    decoration: deco('Password',
                        hint: _register ? 'At least 10 characters' : null,
                        suffix: IconButton(
                          icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _hide = !_hide),
                        )),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your password';
                      if (_register && v.length < 10) return 'Use at least 10 characters';
                      return null;
                    },
                  ),
                  if (_register) ...[
                    const SizedBox(height: 14),
                    TextFormField(controller: _invite, decoration: deco('Invite code (if required)')),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : Text(_register ? 'Create account' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => setState(() => _register = !_register),
                    child: Text(_register ? 'I already have an account' : 'First time? Create the owner account'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
