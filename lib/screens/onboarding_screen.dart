import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../avatar/avatar_view.dart';
import '../core/emotions.dart';
import '../core/theme.dart';

const kOnboardingSeenKey = 'onboarding_v3_seen';

Future<bool> onboardingSeen() async =>
    (await SharedPreferences.getInstance()).getBool(kOnboardingSeenKey) ??
    false;

Future<void> markOnboardingSeen() async =>
    (await SharedPreferences.getInstance()).setBool(kOnboardingSeenKey, true);

/// 온보딩 4장 (shots/v3_onboarding_01~04)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _base = {
    'shadow': 'shadow_default',
    'body': 'body_white',
    'blush': 'blush_round',
    'eyes': 'eyes_dot',
    'mouth': 'mouth_smile',
  };

  Future<void> _finish() async {
    await markOnboardingSeen();
    widget.onDone();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Page(
        art: Stack(
          clipBehavior: Clip.none,
          children: [
            LiveAvatar(
              selection: {
                ..._base,
                'eyes': 'eyes_happy_u',
                'mouth': 'mouth_w_mouth',
              },
              size: 230,
            ),
            const Positioned(
              right: 18,
              top: 6,
              child: Icon(Icons.favorite, color: MkColors.accent, size: 30),
            ),
          ],
        ),
        title: '말하지 않아도\n마음이 콕, 전해져요',
        body: '둘만의 아바타로 오늘의 기분을\n가볍게 주고받는 커플 앱',
      ),
      _Page(
        art: const _SendDemo(base: _base),
        title: '지금 기분을 고르고\n콕 누르면 끝',
        body: '${kEmotions.length}가지 감정 중 하나를 고르면\n아바타가 대신 표현해줘요',
      ),
      _Page(
        art: const _ReactionDemo(base: _base),
        title: '도착한 마음엔\n한 번에 반응해요',
        body: '추천 반응을 누르면 진동과 함께\n상대 아바타가 바로 답해요',
      ),
      _Page(
        art: const _ConnectDemo(base: _base),
        title: '코드 하나로\n둘만의 공간을 연결해요',
        body: '연결 코드는 24시간 동안 유효해요',
      ),
    ];
    final last = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: last
                    ? null
                    : TextButton(
                        key: const Key('obSkip'),
                        onPressed: _finish,
                        child: const Text(
                          '건너뛰기',
                          style: TextStyle(color: MkColors.textSub),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? MkColors.accent
                          : const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  key: const Key('obNext'),
                  style: FilledButton.styleFrom(
                    backgroundColor: MkColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: last
                      ? _finish
                      : () => _pc.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        ),
                  child: Text(
                    last ? '연결 시작하기' : '다음',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.art, required this.title, required this.body});
  final Widget art;
  final String title, body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      children: [
        Expanded(
          child: Center(
            child: FittedBox(fit: BoxFit.scaleDown, child: art),
          ),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 15,
            color: MkColors.textSub,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
      ],
    ),
  );
}

class _SendDemo extends StatelessWidget {
  const _SendDemo({required this.base});
  final Map<String, String> base;
  @override
  Widget build(BuildContext context) {
    const items = [
      (LucideIcons.smile, '행복해', false),
      (LucideIcons.moon, '졸려', true),
      (LucideIcons.utensils, '배고파', false),
      (LucideIcons.handHeart, '안아줘', false),
    ];
    return Column(
      children: [
        LiveAvatar(selection: base, size: 160),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final (icon, label, sel) in items)
              Container(
                width: 76,
                height: 80,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: sel ? MkColors.accentSoft : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? MkColors.accent : MkColors.border,
                    width: sel ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: sel ? MkColors.accent : MkColors.charcoal,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: sel ? MkColors.accent : MkColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: 240,
          height: 44,
          decoration: BoxDecoration(
            color: MkColors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.send, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                '졸려 보내기',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReactionDemo extends StatelessWidget {
  const _ReactionDemo({required this.base});
  final Map<String, String> base;
  @override
  Widget build(BuildContext context) => Container(
    width: 290,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: MkColors.border),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.moon, size: 14, color: MkColors.charcoal),
              SizedBox(width: 6),
              Text('지우가 졸려요', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            LiveAvatar(
              selection: {
                ...base,
                'body': 'body_peach',
                'eyes': 'eyes_sleepy',
                'mouth': 'mouth_flat',
              },
              size: 140,
            ),
            const Positioned(
              right: 14,
              top: 6,
              child: Text(
                'zz',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MkColors.border),
          ),
          child: const Text(
            '토닥토닥',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: MkColors.accent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '얼른 자~ 잘자',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _ConnectDemo extends StatelessWidget {
  const _ConnectDemo({required this.base});
  final Map<String, String> base;
  @override
  Widget build(BuildContext context) {
    Widget step(int n, String t, {bool accent = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: accent ? MkColors.accent : const Color(0xFF111111),
            child: Text(
              '$n',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(t, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LiveAvatar(selection: {...base, 'eyes': 'eyes_dot'}, size: 100),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(LucideIcons.link, color: MkColors.accent),
            ),
            LiveAvatar(selection: {...base, 'body': 'body_cream'}, size: 100),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final c in 'K7P2QX'.split(''))
              Container(
                width: 46,
                height: 58,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: MkColors.border),
                ),
                child: Text(
                  c,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MkColors.border),
          ),
          child: Column(
            children: [
              step(1, '내 코드를 상대에게 보내요'),
              step(2, '상대가 코드를 입력하거나 QR 스캔'),
              step(3, '서로 확인하면 연결 완료', accent: true),
            ],
          ),
        ),
      ],
    );
  }
}
