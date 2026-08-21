// 기존(레거시) 양식 편집기를 jsdom 으로 그대로 돌려서, 위젯 종류별 "정답 HTML" 을 뽑는다.
//
// 왜 필요한가
//   편집 엔진을 TipTap 으로 갈아끼울 때 가장 큰 위험은 ProseMirror 가 스키마에 없는
//   내용을 **경고 없이 버리는** 것이다. 그래서 교체 전에 "지금 편집기가 만들어 내는
//   HTML" 을 종류별로 고정해 두고, 새 엔진이 같은 결과를 내는지 기계적으로 비교한다.
//
//   브라우저에서 손으로 뽑아 붙여넣지 않고 스크립트로 만드는 이유는, 레거시 편집기가
//   고쳐질 때마다 `npm run fixtures` 한 번으로 기준을 다시 만들 수 있어야 하기 때문이다.
//
// 사용: npm run fixtures

import { JSDOM } from 'jsdom';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const WEB = path.resolve(HERE, '..', '..', 'web');
const OUT = path.resolve(HERE, '..', 'test', 'fixtures');

// eap_html_editor.html 의 <script> 순서와 같아야 한다.
const SCRIPTS = [
  'eap_doc_tables.js',
  'eap_daou_import.js',
  'eap_form_runtime.js',
  'eap_form_editor_widgets.js',
  'eap_html_editor.js',
];

// 팔레트 항목의 순서와 타입 — eap_form_editor_widgets.js 의 PALETTE 와 같아야 한다.
// (개수가 어긋나면 아래에서 즉시 실패시켜, 위젯이 추가/삭제된 걸 놓치지 않게 한다.)
const PALETTE_TYPES = [
  // 기본 항목
  'doc_header', 'title_block', 'richtext_block', 'approval_line',
  'text', 'multiline', 'number', 'amount', 'date',
  'checkbox', 'radio', 'select', 'time', 'period', 'user', 'dept',
  // 자동 항목
  'auto_drafter', 'auto_dept', 'auto_email', 'auto_position',
  'auto_empno', 'auto_contact', 'auto_date', 'auto_complete_date', 'auto_docno',
  // 고급 항목
  'approval_agree', 'approval_receive', 'sum_display',
];

function readWeb(name) {
  return fs.readFileSync(path.join(WEB, name), 'utf8');
}

/** 편집기 페이지를 jsdom 에 띄우고 스크립트를 순서대로 실행한다. */
export function bootLegacyEditor() {
  // <script src> 는 jsdom 이 상대경로를 못 찾으므로 걷어내고 직접 실행한다.
  const html = readWeb('eap_html_editor.html').replace(
    /<script\s+src="[^"]*"><\/script>/g,
    '',
  );

  const dom = new JSDOM(html, {
    url: 'https://on.yeokjeon.com/eap_html_editor.html?mode=form',
    runScripts: 'dangerously',
    pretendToBeVisual: true,
  });
  const { window } = dom;

  // jsdom 에 없는 브라우저 API 를 최소한으로 채운다.
  // execCommand 는 위젯 삽입 경로에서 쓰이지 않으므로 no-op 으로 충분하다.
  window.document.execCommand = () => true;
  window.document.queryCommandState = () => false;
  window.document.queryCommandValue = () => '';
  window.alert = () => {};
  window.confirm = () => true;
  window.prompt = () => null;
  // jsdom 은 innerText 를 구현하지 않는다(레이아웃이 없어서).
  // 편집기는 "본문이 비었는가" 판정에만 쓰므로 textContent 로 대신한다.
  // 주의: 진짜 innerText 는 공백을 접고 display:none 을 제외하므로 완전히 같지는 않다.
  //       비었는지 여부만 보는 용도라 이 차이가 결과를 바꾸지 않는다.
  if (!Object.getOwnPropertyDescriptor(window.HTMLElement.prototype, 'innerText')) {
    Object.defineProperty(window.HTMLElement.prototype, 'innerText', {
      configurable: true,
      get() {
        return this.textContent;
      },
      set(v) {
        this.textContent = v;
      },
    });
  }
  if (!window.matchMedia) {
    window.matchMedia = () => ({
      matches: false,
      addListener() {},
      removeListener() {},
      addEventListener() {},
      removeEventListener() {},
    });
  }

  const errors = [];
  window.addEventListener('error', (e) => errors.push(String(e.message)));

  for (const name of SCRIPTS) {
    const code = readWeb(name);
    const el = window.document.createElement('script');
    el.textContent = code;
    try {
      window.document.body.appendChild(el);
    } catch (e) {
      errors.push(`${name}: ${e.message}`);
    }
  }

  return { dom, window, errors };
}

/**
 * 저장 시 실제로 쓰이는 직렬화(eap_html_editor.js 의 currentHtml)와 같은 절차.
 * 편집기 UI 찌꺼기(선택 표시 클래스, 삭제 버튼)를 걷어낸 "저장본" 을 만든다.
 */
export function serialize(window) {
  const editor = window.editor;
  const clone = editor.cloneNode(true);
  clone
    .querySelectorAll('.eap-img-on, .eap-cell-on, .eap-cell-sel, .eap-on')
    .forEach((el) => {
      for (const k of ['eap-img-on', 'eap-cell-on', 'eap-cell-sel', 'eap-on']) {
        el.classList.remove(k);
      }
      if (!el.className) el.removeAttribute('class');
    });
  clone.querySelectorAll('.eap-w-del, .eap-h-del').forEach((el) => el.remove());
  const hasExcel = clone.querySelector('table.eap-excel-import');
  if (window.eapSanitizeFormHtml) {
    window.eapSanitizeFormHtml(clone, hasExcel ? { preserveTableLayout: true } : {});
  }
  if (window.eapFixDocTables) window.eapFixDocTables(clone);
  return clone.innerHTML;
}

/** 저장본을 편집기에 다시 불러오는 절차(eap_html_editor.js 의 loadEditorHtml). */
export function load(window, html) {
  const editor = window.editor;
  editor.innerHTML = html || '';
  if (window.eapMigrateDaouHtml) window.eapMigrateDaouHtml(editor);
  if (window.eapSanitizeFormHtml) window.eapSanitizeFormHtml(editor);
  if (window.eapPrepareImportedHtmlForEdit) {
    window.eapPrepareImportedHtmlForEdit(editor, { designMode: true });
  }
  if (window.migrateLegacyFormFields) window.migrateLegacyFormFields();
}

/** 위젯 id(w1, w2...)는 삽입 순서에 따라 달라지므로 비교 전에 지운다. */
export function normalizeIds(html) {
  return html.replace(/data-eap-id="w\d+"/g, 'data-eap-id="wN"');
}

function main() {
  const { window, errors } = bootLegacyEditor();
  if (!window.editor) {
    console.error('[FAIL] 레거시 편집기 부팅 실패 — window.editor 가 없다.');
    for (const e of errors) console.error('  ' + e);
    process.exit(1);
  }

  const buttons = [...window.document.querySelectorAll('.palItem')];
  if (buttons.length === 0) {
    console.error('[FAIL] 팔레트 항목이 없다. 편집기 초기화가 끝나지 않았다.');
    process.exit(1);
  }

  fs.mkdirSync(OUT, { recursive: true });
  const index = [];

  if (buttons.length !== PALETTE_TYPES.length) {
    console.error(
      `[FAIL] 팔레트 항목 수가 바뀌었다: 화면 ${buttons.length}개 vs 이 파일의 목록 ${PALETTE_TYPES.length}개.\n` +
        '       eap_form_editor_widgets.js 의 PALETTE 를 보고 PALETTE_TYPES 를 맞춰 주세요.',
    );
    process.exit(1);
  }

  buttons.forEach((btn, i) => {
    const label = btn.textContent.trim();
    // 팔레트에는 결재선 계열처럼 결과 HTML 의 data-eap-type 이 겹치는 항목이 있어서
    // (제목+결재선 / 결재선 → 둘 다 approval_line) DOM 에서 추론하면 파일이 덮어써진다.
    // 그래서 팔레트 정의 순서를 그대로 파일 이름의 기준으로 쓴다.
    const type = PALETTE_TYPES[i];
    window.editor.innerHTML = '';
    btn.click();
    const html = normalizeIds(serialize(window));
    const file = `widget-${String(i).padStart(2, '0')}-${type}.html`;
    fs.writeFileSync(path.join(OUT, file), html, 'utf8');
    index.push({ label, type, file, chars: html.length });
  });

  fs.writeFileSync(
    path.join(OUT, 'index.json'),
    JSON.stringify(index, null, 2),
    'utf8',
  );

  console.log(`[OK] 위젯 고정 데이터 ${index.length}건 생성 -> ${OUT}`);
  for (const r of index) {
    console.log(`  ${String(r.chars).padStart(5)}  ${r.type.padEnd(20)} ${r.label}`);
  }
  if (errors.length) {
    console.log('\n[참고] 부팅 중 무시한 오류:');
    for (const e of errors) console.log('  ' + e);
  }
}

// Windows 경로(C:\...)는 file:// 조합이 어긋나므로 pathToFileURL 로 정확히 비교한다.
if (import.meta.url === pathToFileURL(process.argv[1]).href) main();
