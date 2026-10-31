import {test, before, after} from 'node:test';
import assert from 'node:assert';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, setDoc, updateDoc, writeBatch, serverTimestamp, getDoc} from 'firebase/firestore';

let env;
const C = 'c1';
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-mk',
    firestore: {rules: readFileSync('../../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080}});
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), `couples/${C}`), {members: ['a', 'b']});
  });
});
after(() => env.cleanup());

const base = (id) => ({id, label: '야근 중', glyphType: 'icon', icon: 'lucide:laptop', emoji: null,
  category: 'body', vibrationName: 'buzz', animationKey: 'rush', reactions: ['고마워', '나도!'],
  createdBy: 'a', createdAt: serverTimestamp(), updatedAt: serverTimestamp(), deleted: false});

async function create(db, id, n, data = base(id)) {
  const b = writeBatch(db);
  b.set(doc(db, `couples/${C}/counters/customEmotions`), {n});
  b.set(doc(db, `couples/${C}/customEmotions/${id}`), data);
  return b.commit();
}

test('custom emotion rules', async () => {
  const a = env.authenticatedContext('a').firestore();
  const x = env.authenticatedContext('x').firestore();
  await assertSucceeds(create(a, 'custom_aaaaaaaa1', 1));
  await assertFails(create(x, 'custom_aaaaaaaa2', 2));               // 비회원
  await assertFails(create(a, 'custom_aaaaaaaa3', 1));               // 카운터 미증가
  await assertFails(create(a, 'custom_aaaaaaaa4', 2, {...base('custom_aaaaaaaa4'), label: '일곱글자이름임'})); // 7자
  await assertFails(create(a, 'custom_aaaaaaaa5', 2, {...base('custom_aaaaaaaa5'), reactions: ['a', 'b', 'c', 'd']}));
  await assertFails(create(a, 'custom_aaaaaaaa6', 2, {...base('custom_aaaaaaaa6'), reactions: ['열세글자가넘는추천반응문구야']}));
  const b = env.authenticatedContext('b').firestore();
  await assertSucceeds(updateDoc(doc(b, `couples/${C}/customEmotions/custom_aaaaaaaa1`), {label: '야근', updatedAt: serverTimestamp()}));
  await assertFails(updateDoc(doc(b, `couples/${C}/customEmotions/custom_aaaaaaaa1`), {deleted: true}));  // 카운터 감소 없이 삭제
  const bt = writeBatch(b);
  bt.set(doc(b, `couples/${C}/counters/customEmotions`), {n: 0});
  bt.update(doc(b, `couples/${C}/customEmotions/custom_aaaaaaaa1`), {deleted: true, updatedAt: serverTimestamp()});
  await assertSucceeds(bt.commit());
  await assertFails(updateDoc(doc(b, `couples/${C}/customEmotions/custom_aaaaaaaa1`), {label: '부활'}));
  // 30개 제한
  await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), `couples/${C}/counters/customEmotions`), {n: 30}));
  await assertFails(create(a, 'custom_aaaaaaaa7', 31));
});

test('prefs rules', async () => {
  const a = env.authenticatedContext('a').firestore();
  const b = env.authenticatedContext('b').firestore();
  await assertSucceeds(setDoc(doc(a, 'users/a/prefs/emotionFavorites'), {order: ['happy'], updatedAt: serverTimestamp()}));
  await assertFails(setDoc(doc(a, 'users/a/prefs/emotionFavorites'), {order: Array(25).fill('happy')}));
  await assertFails(getDoc(doc(b, 'users/a/prefs/emotionFavorites')));
  await assertSucceeds(setDoc(doc(a, 'users/a/prefs/recentEmotions'), {items: [{emotionId: 'happy', sentAt: new Date()}]}));
  await assertFails(setDoc(doc(a, 'users/a/prefs/recentEmotions'), {items: Array(13).fill({emotionId: 'x'})}));
});

test('emotion with snapshot', async () => {
  const a = env.authenticatedContext('a').firestore();
  await assertSucceeds(setDoc(doc(a, `couples/${C}/emotions/e1`), {senderUid: 'a', emotionId: 'custom_aaaaaaaa1',
    count: 1, snapshot: {label: '야근', icon: 'lucide:laptop', animationKey: 'rush', vibrationName: 'buzz', category: 'body', custom: true},
    createdAt: serverTimestamp()}));
});
