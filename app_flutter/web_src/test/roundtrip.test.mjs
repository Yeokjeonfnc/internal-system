// 안전망 — 양식 HTML 이 편집기를 거쳐도 내용이 사라지지 않는지 검사한다.
//
// 이 테스트는 두 가지를 본다.
//   1) 안정성  : 불러오기→저장을 두 번 해도 결과가 더 이상 변하지 않는가.
//                (한 번 저장할 때마다 조금씩 달라지면 서식이 서서히 망가진다)
//   2) 보존성  : 불러오기→저장을 거친 뒤에도 위젯·표·글자가 그대로인가.
//
// 지금은 **레거시 편집기**를 대상으로 돌려 "현재 기준선" 을 고정한다.
// TipTap 엔진이 붙으면 같은 검사를 새 엔진에도 돌려서, 기준선을 그대로
// 지키는지 비교하게 된다. 그래서 엔진은 어댑터로 갈아끼울 수 있게 해 뒀다.
//
// 실행: npm test

import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { bootLegacyEditor, serialize, load, normalizeIds } from '../tools/make-fixtures.mjs';
import { signature, diffSignature } from './signature.mjs';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const FIXTURES = path.join(HERE, 'fixtures');

function fixtureFiles() {
  if (!fs.existsSync(FIXTURES)) return [];
  return fs
    .readdirSync(FIXTURES)
    .filter((f) => f.endsWith('.html'))
    .sort();
}

/** 레거시(현재) 편집기 어댑터. TipTap 어댑터도 같은 모양으로 만들면 된다. */
function legacyEngine() {
  const { window, errors } = bootLegacyEditor();
  assert.ok(window.editor, `편집기 부팅 실패: ${errors.join(' / ')}`);
  return {
    name: 'legacy',
    document: window.document,
    /** 저장본 HTML 을 넣었다가 다시 저장본으로 꺼낸다. */
    roundtrip(html) {
      load(window, html);
      return serialize(window);
    },
  };
}

const files = fixtureFiles();

test('고정 데이터가 존재한다', () => {
  assert.ok(
    files.length >= 28,
    `고정 데이터가 ${files.length}건뿐이다. 먼저 \`npm run fixtures\` 를 실행하세요.`,
  );
});

test('레거시 편집기: 왕복해도 내용이 사라지지 않는다', async (t) => {
  const engine = legacyEngine();

  for (const file of files) {
    await t.test(file, () => {
      const original = fs.readFileSync(path.join(FIXTURES, file), 'utf8');

      const once = normalizeIds(engine.roundtrip(original));
      const twice = normalizeIds(engine.roundtrip(once));

      // 1) 안정성 — 두 번째 왕복부터는 더 이상 변하면 안 된다.
      assert.equal(
        once,
        twice,
        `왕복할 때마다 HTML 이 계속 달라진다(저장을 반복하면 서식이 망가진다).\n` +
          `  1회차 ${once.length}자 / 2회차 ${twice.length}자`,
      );

      // 2) 보존성 — 원본 대비 위젯·표·글자가 그대로여야 한다.
      const problems = diffSignature(
        signature(original, engine.document),
        signature(once, engine.document),
      );
      assert.deepEqual(
        problems,
        [],
        `왕복 후 내용이 달라졌다:\n  - ${problems.join('\n  - ')}`,
      );
    });
  }
});

test('레거시 편집기: 운영에 저장된 실제 서식도 보존된다', async (t) => {
  const engine = legacyEngine();
  const live = files.filter((f) => f.startsWith('live-'));

  assert.ok(live.length > 0, '운영 서식 고정 데이터(live-*.html)가 없다.');

  for (const file of live) {
    await t.test(file, () => {
      const original = fs.readFileSync(path.join(FIXTURES, file), 'utf8');
      const once = engine.roundtrip(original);
      const problems = diffSignature(
        signature(original, engine.document),
        signature(once, engine.document),
      );
      assert.deepEqual(problems, [], `내용이 달라졌다:\n  - ${problems.join('\n  - ')}`);
    });
  }
});
