// 서식 HTML 의 "내용 지문(signature)" — 엔진이 달라도 같아야 하는 것만 뽑는다.
//
// 왜 문자열 비교가 아니라 지문인가
//   편집 엔진을 TipTap 으로 바꾸면 공백·속성 순서·불필요한 래퍼 같은 **겉모습**은
//   달라질 수밖에 없다. 그건 문제가 아니다. 진짜 문제는 ProseMirror 가 스키마에
//   없는 걸 조용히 버려서 **내용이 사라지는** 것이다.
//   그래서 "사라지면 안 되는 것"만 추려 비교한다:
//     - 양식 필드(위젯) 하나하나와 그 설정값
//     - 표의 구조(행·열·병합)
//     - 사람이 읽는 글자
//     - 문서 블록 구성(제목/결재선/본문)
//
//   겉모습까지 똑같기를 요구하면 테스트가 매번 깨져서 아무도 안 보게 된다.
//   반대로 너무 느슨하면 데이터가 사라져도 통과한다. 그 사이를 잡는 게 이 파일이다.

/** 위젯에서 반드시 보존돼야 하는 속성들. */
const WIDGET_ATTRS = [
  'data-eap-type',
  'data-eap-label',
  'data-eap-required',
  'data-eap-options',
  'data-eap-auto',
  'data-eap-sum-group',
  'data-eap-show-field',
  'data-eap-show-value',
  'data-eap-cols',
];

/** 눈에 보이는 글자만 남긴다 — 공백 차이는 무시. */
function normText(s) {
  return String(s || '')
    .replace(/ /g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function widgetSignature(el) {
  const out = { tag: el.tagName.toLowerCase() };
  for (const a of WIDGET_ATTRS) {
    if (el.hasAttribute(a)) out[a] = el.getAttribute(a);
  }
  // 선택지(드롭다운/체크박스/라디오)는 화면에 그려진 것도 확인한다.
  const opts = [...el.querySelectorAll('option, .eap-w-check-lbl')]
    .map((o) => normText(o.textContent))
    .filter(Boolean);
  if (opts.length) out.renderedOptions = opts;
  return out;
}

function tableSignature(table) {
  const rows = [...table.rows];
  return {
    rows: rows.length,
    cells: rows.map((tr) =>
      [...tr.cells].map((td) => ({
        tag: td.tagName.toLowerCase(),
        rowSpan: td.rowSpan || 1,
        colSpan: td.colSpan || 1,
        text: normText(td.textContent),
      })),
    ),
  };
}

/**
 * HTML 문자열 → 내용 지문.
 * @param {string} html
 * @param {Document} document  jsdom 또는 브라우저의 document
 */
export function signature(html, document) {
  const root = document.createElement('div');
  root.innerHTML = html || '';

  // 위젯 안의 표(결재선)는 위젯 지문에 이미 들어가므로 표 목록에서 뺀다 —
  // 그러지 않으면 같은 내용을 두 번 세어 비교가 과민해진다.
  const allTables = [...root.querySelectorAll('table')];
  const widgets = [...root.querySelectorAll('[data-eap-type]')];

  return {
    // 위젯: 순서까지 의미가 있다(양식의 항목 순서).
    widgets: widgets.map(widgetSignature),
    // 표: 결재선 표 포함 — 행/열/병합이 깨지면 양식이 무너진다.
    tables: allTables.map(tableSignature),
    // 문서 블록 구성.
    blocks: [...root.children].map((el) => ({
      tag: el.tagName.toLowerCase(),
      cls: (el.className || '').split(/\s+/).filter(Boolean).sort().join(' '),
    })),
    // 사람이 읽는 글자 전체.
    text: normText(root.textContent),
  };
}

/**
 * 두 지문을 비교해 "무엇이 사라졌는지" 사람이 읽을 수 있게 돌려준다.
 * 같으면 빈 배열.
 */
export function diffSignature(before, after) {
  const problems = [];

  if (before.widgets.length !== after.widgets.length) {
    const lost = before.widgets
      .map((w) => w['data-eap-type'])
      .filter((t, i) => (after.widgets[i] || {})['data-eap-type'] !== t);
    problems.push(
      `위젯 개수가 ${before.widgets.length} → ${after.widgets.length} 로 바뀜` +
        (lost.length ? ` (틀어진 타입: ${lost.join(', ')})` : ''),
    );
  } else {
    before.widgets.forEach((w, i) => {
      const a = after.widgets[i] || {};
      for (const k of Object.keys(w)) {
        if (JSON.stringify(w[k]) !== JSON.stringify(a[k])) {
          problems.push(
            `위젯 #${i}(${w['data-eap-type']}) 의 ${k} 이(가) ` +
              `${JSON.stringify(w[k])} → ${JSON.stringify(a[k])}`,
          );
        }
      }
    });
  }

  if (before.tables.length !== after.tables.length) {
    problems.push(`표 개수가 ${before.tables.length} → ${after.tables.length} 로 바뀜`);
  } else {
    before.tables.forEach((t, i) => {
      const a = after.tables[i];
      if (JSON.stringify(t) !== JSON.stringify(a)) {
        problems.push(
          `표 #${i} 구조가 달라짐 (행 ${t.rows}→${a.rows}, ` +
            `셀 ${JSON.stringify(t.cells).length}→${JSON.stringify(a.cells).length}자)`,
        );
      }
    });
  }

  if (before.text !== after.text) {
    problems.push(`글자가 달라짐:\n    이전: ${before.text}\n    이후: ${after.text}`);
  }

  const b = JSON.stringify(before.blocks);
  const a = JSON.stringify(after.blocks);
  if (b !== a) problems.push(`문서 블록 구성이 달라짐:\n    이전: ${b}\n    이후: ${a}`);

  return problems;
}
