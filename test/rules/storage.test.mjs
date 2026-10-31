import {test, before, after} from 'node:test';
import {readFileSync} from 'node:fs';
import {initializeTestEnvironment, assertSucceeds, assertFails} from '@firebase/rules-unit-testing';
import {doc, setDoc} from 'firebase/firestore';
import {ref, uploadBytes, getBytes} from 'firebase/storage';

let env;
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-mk',
    firestore: {rules: readFileSync('../../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080},
    storage: {rules: readFileSync('../../storage.rules', 'utf8'), host: '127.0.0.1', port: 9199}});
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'couples/s1'), {members: ['a', 'b']});
  });
});
after(() => env.cleanup());

const jpg = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
const meta = {contentType: 'image/jpeg'};

test('storage background rules', async () => {
  const a = env.authenticatedContext('a').storage();
  const b = env.authenticatedContext('b').storage();
  const x = env.authenticatedContext('x').storage();
  await assertSucceeds(uploadBytes(ref(a, 'users/a/backgrounds/p.jpg'), jpg, meta));
  await assertSucceeds(getBytes(ref(a, 'users/a/backgrounds/p.jpg')));
  await assertFails(getBytes(ref(b, 'users/a/backgrounds/p.jpg')));            // 상대도 개인 사진 불가
  await assertFails(uploadBytes(ref(b, 'users/a/backgrounds/q.jpg'), jpg, meta));
  await assertFails(uploadBytes(ref(a, 'users/a/backgrounds/t.txt'), jpg, {contentType: 'text/plain'}));
  await assertSucceeds(uploadBytes(ref(a, 'couples/s1/backgrounds/p.jpg'), jpg, meta));
  await assertSucceeds(getBytes(ref(b, 'couples/s1/backgrounds/p.jpg')));
  await assertFails(getBytes(ref(x, 'couples/s1/backgrounds/p.jpg')));         // 비회원
  await assertFails(uploadBytes(ref(a, 'other/p.jpg'), jpg, meta));
});
