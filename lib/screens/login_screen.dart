import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.auth});
  final AuthService auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;
  String? _error;
  int _logoTaps = 0;
  bool _showEmail = false;
  final _email = TextEditingController();
  final _pw = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  void _onLogoTap() {
    if (++_logoTaps >= 5) setState(() => _showEmail = true);
  }

  Future<void> _signInEmail() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.signInWithEmail(_email.text, _pw.text);
    } catch (e) {
      setState(() => _error = '로그인에 실패했어요. 이메일과 비밀번호를 확인해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn({bool apple = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      apple
          ? await widget.auth.signInWithApple()
          : await widget.auth.signInWithGoogle();
    } catch (e) {
      setState(() => _error = '로그인에 실패했어요. 다시 시도해 주세요.\n$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  key: const Key('logo'),
                  onTap: _onLogoTap,
                  child: const Text(
                    '마음콕',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('우리 둘만의 마음 전하기'),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: _busy ? null : _signIn,
                  icon: const Icon(Icons.login),
                  label: Text(_busy ? '로그인 중…' : 'Google로 시작하기'),
                ),
                if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    onPressed: _busy ? null : () => _signIn(apple: true),
                    icon: const Icon(Icons.apple),
                    label: const Text('Apple로 시작하기'),
                  ),
                ],
                if (_showEmail) ...[
                  const SizedBox(height: 24),
                  const Text('심사용 이메일 로그인'),
                  TextField(
                    key: const Key('reviewEmail'),
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '이메일'),
                  ),
                  TextField(
                    key: const Key('reviewPassword'),
                    controller: _pw,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    key: const Key('reviewLogin'),
                    onPressed: _busy ? null : _signInEmail,
                    child: const Text('이메일로 로그인'),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
