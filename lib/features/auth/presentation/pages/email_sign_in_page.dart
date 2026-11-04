import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/round_back_button.dart';
import '../cubit/email_sign_in_cubit.dart';
import '../cubit/session_cubit.dart';

class EmailSignInPage extends StatelessWidget {
  const EmailSignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmailSignInCubit(sendCode: sl(), verifyCode: sl()),
      child: const _EmailSignInView(),
    );
  }
}

class _EmailSignInView extends StatefulWidget {
  const _EmailSignInView();

  @override
  State<_EmailSignInView> createState() => _EmailSignInViewState();
}

class _EmailSignInViewState extends State<_EmailSignInView> {
  final _email = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return BlocConsumer<EmailSignInCubit, EmailSignInState>(
      listenWhen: (a, b) => a.user != b.user && b.user != null,
      listener: (context, state) => context.read<SessionCubit>().signedIn(state.user!),
      builder: (context, state) {
        final codeStep = state.step == EmailStep.enterCode;
        final cubit = context.read<EmailSignInCubit>();

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: RoundBackButton(onPressed: codeStep ? cubit.changeEmail : null),
                ),
                const SizedBox(height: 28),
                Text(codeStep ? 'Check your inbox' : 'Sign in with email', style: text.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  codeStep
                      ? 'We sent a 6 digit code to ${state.email}.'
                      : 'No password needed. We email you a short code.',
                  style: text.bodyLarge?.copyWith(color: c.muted),
                ),
                const SizedBox(height: 24),
                if (!codeStep)
                  TextField(
                    controller: _email,
                    autofocus: true,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(hintText: 'you@example.com'),
                    onSubmitted: cubit.sendCode,
                  )
                else
                  TextField(
                    controller: _code,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    style: text.headlineMedium?.copyWith(letterSpacing: 8),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: '000000', counterText: ''),
                    onSubmitted: cubit.verify,
                  ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(state.error!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
                  ),
                const SizedBox(height: 24),
                PillButton(
                  label: codeStep ? 'Sign in' : 'Send code',
                  icon: codeStep ? Icons.login_rounded : Icons.send_rounded,
                  loading: state.busy,
                  onPressed: () => codeStep ? cubit.verify(_code.text) : cubit.sendCode(_email.text),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
