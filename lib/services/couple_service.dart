import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/invite_code.dart';

class CoupleException implements Exception {
  CoupleException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 초대코드 흐름: A 생성(pending) → B 입력(claimed) → A 수락(confirmed, 커플 생성).
class CoupleService {
  CoupleService({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  final _rand = Random.secure();

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection('users').doc(uid);
  DocumentReference<Map<String, dynamic>> inviteRef(String code) =>
      _db.collection('inviteCodes').doc(code);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) =>
      userRef(uid).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchCouple(String id) =>
      _db.collection('couples').doc(id).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchInvite(String code) =>
      inviteRef(code).snapshots();

  String _randomCode() =>
      List.generate(kInviteCodeLength, (_) => _rand.nextInt(10)).join();

  Future<String> createInviteCode(String myUid) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _randomCode();
      try {
        await _db.runTransaction((tx) async {
          final ref = inviteRef(code);
          final snap = await tx.get(ref);
          if (snap.exists) {
            final d = snap.data()!;
            final expired = (d['expiresAt'] as Timestamp).toDate().isBefore(
              DateTime.now(),
            );
            if (!expired && d['status'] != 'cancelled') {
              throw StateError('taken');
            }
          }
          tx.set(ref, {
            'ownerUid': myUid,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(DateTime.now().add(kInviteCodeTtl)),
          });
        });
        return code;
      } on StateError {
        continue;
      }
    }
    throw CoupleException('코드를 만들지 못했어요. 다시 시도해 주세요.');
  }

  /// B: 코드 입력
  Future<void> claimInviteCode(String myUid, String input) async {
    final code = normalizeInviteCode(input);
    if (!isValidInviteCode(code)) throw CoupleException('6자리 숫자 코드를 입력해 주세요.');
    await _db.runTransaction((tx) async {
      final snap = await tx.get(inviteRef(code));
      if (!snap.exists) throw CoupleException('없는 코드예요.');
      final d = snap.data()!;
      if (d['ownerUid'] == myUid) {
        throw CoupleException('내가 만든 코드예요. 상대에게 보내 주세요.');
      }
      if ((d['expiresAt'] as Timestamp).toDate().isBefore(DateTime.now())) {
        throw CoupleException('만료된 코드예요.');
      }
      if (d['status'] != 'pending') throw CoupleException('이미 사용된 코드예요.');
      tx.update(inviteRef(code), {
        'status': 'claimed',
        'claimedBy': myUid,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// A: 상대가 입력한 코드 수락 → 커플 생성
  Future<String> confirmInviteCode(String myUid, String code) async {
    return _db.runTransaction((tx) async {
      final snap = await tx.get(inviteRef(code));
      final d = snap.data();
      if (d == null || d['ownerUid'] != myUid || d['status'] != 'claimed') {
        throw CoupleException('수락할 수 있는 요청이 없어요.');
      }
      final partnerUid = d['claimedBy'] as String;
      final me = await tx.get(userRef(myUid));
      // 상대 문서는 아직 읽을 권한이 없으므로 규칙(hasNoCouple)이 서버에서 검증한다.
      if (me.data()?['coupleId'] != null) {
        throw CoupleException('이미 커플로 연결된 계정이 있어요.');
      }
      final coupleRef = _db.collection('couples').doc();
      tx.set(coupleRef, {
        'members': [myUid, partnerUid],
        'inviteCode': code,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(inviteRef(code), {
        'status': 'confirmed',
        'coupleId': coupleRef.id,
      });
      tx.update(userRef(myUid), {'coupleId': coupleRef.id});
      tx.update(userRef(partnerUid), {'coupleId': coupleRef.id});
      return coupleRef.id;
    });
  }

  Future<void> cancelInvite(String code) =>
      inviteRef(code).update({'status': 'cancelled'});
}
