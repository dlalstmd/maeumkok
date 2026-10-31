import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const privacyUrl = 'https://maeumkok.web.app/privacy.html';
const deleteInfoUrl = 'https://maeumkok.web.app/delete-account.html';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.email,
    required this.onSignOut,
    required this.onDeleteAccount,
    this.touchHaptics = true,
    this.onTouchHaptics,
    this.extraTiles = const [],
  });
  final String? email;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onDeleteAccount;

  /// 아바타 터치 진동(users/{uid}.prefs.touchHaptics)
  final bool touchHaptics;
  final Future<void> Function(bool on)? onTouchHaptics;

  /// 배경 등 추가 항목
  final List<Widget> extraTiles;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _touchHaptics = widget.touchHaptics;
  bool _busy = false;

  Future<void> _signOut() async {
    Navigator.of(context).popUntil((r) => r.isFirst);
    await widget.onSignOut();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('계정을 삭제할까요?'),
        content: const Text(
          '계정과 함께 감정·리액션 기록, 아바타, 헤더 설정이 모두 삭제되고 커플 연결도 해제돼요. 되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('취소'),
          ),
          TextButton(
            key: const Key('confirmDelete'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.onDeleteAccount();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제에 실패했어요. 잠시 후 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                if (widget.email != null)
                  ListTile(
                    title: const Text('계정'),
                    subtitle: Text(widget.email!),
                  ),
                ...widget.extraTiles,
                if (widget.onTouchHaptics != null)
                  SwitchListTile(
                    key: const Key('touchHaptics'),
                    title: const Text('아바타 터치 진동'),
                    subtitle: const Text('아바타를 만지면 가볍게 진동해요'),
                    value: _touchHaptics,
                    onChanged: (v) {
                      setState(() => _touchHaptics = v);
                      widget.onTouchHaptics!(v);
                    },
                  ),
                ListTile(
                  title: const Text('개인정보처리방침'),
                  onTap: () => launchUrl(
                    Uri.parse(privacyUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                ListTile(title: const Text('로그아웃'), onTap: _signOut),
                ListTile(
                  key: const Key('deleteAccount'),
                  title: const Text(
                    '계정 삭제',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: _delete,
                ),
              ],
            ),
    );
  }
}
