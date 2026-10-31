import 'package:flutter/material.dart';

import '../services/couple_service.dart';

/// 커플 연결: 코드 만들기(A) / 코드 입력(B) / 수락(A)
class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key, required this.uid, required this.couples});
  final String uid;
  final CoupleService couples;

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final _input = TextEditingController();
  String? _myCode;
  String? _message;
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await f();
    } catch (e) {
      setState(
        () => _message = e is CoupleException ? e.message : '문제가 생겼어요: $e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _myCode;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          '연인과 연결하기',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '한 명이 코드를 만들고, 다른 한 명이 입력한 뒤 만든 사람이 수락하면 연결돼요. 코드는 24시간 유효해요.',
        ),
        const SizedBox(height: 24),
        if (code == null)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                    final c = await widget.couples.createInviteCode(widget.uid);
                    setState(() => _myCode = c);
                  }),
            child: const Text('내 초대코드 만들기'),
          )
        else
          StreamBuilder(
            stream: widget.couples.watchInvite(code),
            builder: (context, snap) {
              final d = snap.data?.data();
              final status = d?['status'];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SelectableText(
                        code,
                        style: const TextStyle(
                          fontSize: 40,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (status == 'claimed') ...[
                        const Text('상대가 코드를 입력했어요. 수락할까요?'),
                        const SizedBox(height: 8),
                        // 테마의 버튼 minimumSize가 Size.fromHeight(무한 너비)라
                        // Row 안에서는 Expanded로 너비를 제한해야 렌더링된다.
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _busy
                                    ? null
                                    : () => _run(
                                        () => widget.couples.confirmInviteCode(
                                          widget.uid,
                                          code,
                                        ),
                                      ),
                                child: const Text('수락'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => _run(() async {
                                        await widget.couples.cancelInvite(code);
                                        setState(() => _myCode = null);
                                      }),
                                child: const Text('거절'),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        const Text('이 코드를 상대에게 보내 주세요. 입력을 기다리는 중…'),
                    ],
                  ),
                ),
              );
            },
          ),
        const Divider(height: 48),
        TextField(
          controller: _input,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: '상대의 초대코드 입력',
            border: OutlineInputBorder(),
          ),
        ),
        FilledButton.tonal(
          onPressed: _busy
              ? null
              : () => _run(() async {
                  await widget.couples.claimInviteCode(widget.uid, _input.text);
                  setState(() => _message = '요청을 보냈어요. 상대가 수락하면 연결돼요.');
                }),
          child: const Text('연결 요청'),
        ),
        if (_message != null) ...[
          const SizedBox(height: 16),
          Text(_message!, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
