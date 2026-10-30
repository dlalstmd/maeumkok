/// 초대코드 규칙(서버 functions/index.js와 동일하게 유지)
const kInviteCodeLength = 6;
const kInviteCodeTtl = Duration(hours: 24);

final _codeRe = RegExp(r'^[0-9]{6}$');

String normalizeInviteCode(String input) => input.replaceAll(RegExp(r'\s'), '');

bool isValidInviteCode(String input) =>
    _codeRe.hasMatch(normalizeInviteCode(input));
