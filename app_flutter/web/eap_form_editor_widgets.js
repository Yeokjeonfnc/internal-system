// 다우오피스형 양식 위젯 — 팔레트·속성·표 셀 삽입
// 참고: https://helpdesk.daouoffice.co.kr/hc/ko/articles/43736473671449
(function (global) {
  var editor = global.editor;
  if (!editor) return;

  var widgetUid = global.widgetUid || 0;
  var selectedWidget = null;
  var dragType = null;
  var dragWidget = null;

  var WIDGET_LABEL = {
    text: '텍스트', multiline: '멀티텍스트', number: '숫자', amount: '통화',
    date: '날짜', period: '기간', time: '시간', select: '드롭다운',
    radio: '단일선택', checkbox: '복수선택', user: '사용자선택', dept: '부서선택',
    richtext: '편집기', sum_display: '자동합계',
    auto_drafter: '기안자', auto_dept: '기안부서', auto_email: '기안자 이메일',
    auto_position: '직위', auto_empno: '사번', auto_contact: '연락처',
    auto_date: '기안일', auto_complete_date: '완료일', auto_docno: '문서번호',
    approval_line: '결재선', approval_agree: '합의 결재선', approval_receive: '수신 결재선'
  };

  var PLACEHOLDER = {
    text: '입력하세요', multiline: '여러 줄 입력', number: '0', amount: '0',
    date: 'YYYY-MM-DD', period: '시작 ~ 종료', time: 'HH:MM',
    select: '선택하세요', radio: '옵션1', checkbox: '옵션1',
    user: '사용자 선택', dept: '부서 선택', richtext: '본문 입력',
    sum_display: '0',
    auto_drafter: '{기안자}', auto_dept: '{기안부서}', auto_email: '{이메일}',
    auto_position: '{직위}', auto_empno: '{사번}', auto_contact: '{연락처}',
    auto_date: '{기안일}', auto_complete_date: '{완료일}', auto_docno: '{문서번호}'
  };

  // 다우오피스 양식편집기 컴포넌트 구성
  var PALETTE = [
    { title: '기본 항목', items: [
      { type: 'doc_header', label: '제목+결재선' },
      { type: 'title_block', label: '제목' },
      { type: 'richtext_block', label: '본문 내용' },
      { type: 'approval_line', label: '결재선' },
      { type: 'text', label: '텍스트' },
      { type: 'multiline', label: '멀티텍스트' },
      { type: 'number', label: '숫자' },
      { type: 'amount', label: '통화' },
      { type: 'date', label: '날짜' },
      { type: 'checkbox', label: '체크박스' },
      { type: 'radio', label: '단일선택' },
      { type: 'select', label: '드롭다운' },
      { type: 'time', label: '시간' },
      { type: 'period', label: '기간' },
      { type: 'user', label: '사용자선택' },
      { type: 'dept', label: '부서선택' }
    ]},
    { title: '자동 항목', items: [
      { type: 'auto_drafter', label: '기안자' },
      { type: 'auto_dept', label: '기안부서' },
      { type: 'auto_email', label: '기안자 이메일' },
      { type: 'auto_position', label: '직위' },
      { type: 'auto_empno', label: '사번' },
      { type: 'auto_contact', label: '연락처' },
      { type: 'auto_date', label: '기안일' },
      { type: 'auto_complete_date', label: '완료일' },
      { type: 'auto_docno', label: '문서번호' }
    ]},
    { title: '고급 항목', items: [
      { type: 'approval_agree', label: '합의 결재선' },
      { type: 'approval_receive', label: '수신 결재선' },
      { type: 'sum_display', label: '자동합계' }
    ]}
  ];

  function nextWid() { return 'w' + (++widgetUid); }
  function escHtml(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }
  function escAttr(s) { return escHtml(s).replace(/"/g, '&quot;'); }
  function isAuto(t) { return t && t.indexOf('auto_') === 0; }
  function isApprovalType(t) {
    return t === 'approval_line' || t === 'approval_agree' || t === 'approval_receive';
  }
  function parseOptions(el) {
    return (el.getAttribute('data-eap-options') || '').replace(/\\n/g, '\n').split('\n').filter(Boolean);
  }

  function widgetInTableCell(el) {
    return !!(el && el.closest && el.closest('td, th'));
  }

  function defaultInlineWidth(el) {
    return widgetInTableCell(el) ? '10em' : '';
  }

  function isPercentWidth(w) {
    return !!(w && String(w).indexOf('%') >= 0);
  }

  function faceWidthAttr(el, fallback) {
    var w = el && el.getAttribute('data-eap-width');
    if (!w && fallback) w = fallback;
    if (!w) return '';
    // 셀 안 % 너비는 applyWidgetLayout에서 shell에 적용 (input에 %만 주면 잘림)
    if (isPercentWidth(w) && widgetInTableCell(el)) return '';
    return ' style="width:' + escAttr(w) + ';max-width:100%"';
  }

  function widgetInMergedCell(el) {
    var cell = el && el.closest('td, th');
    if (!cell) return false;
    var table = cell.closest('table');
    if (!table || cell.closest('table') !== table) return false;
    var sp = cellSpanForWidget(cell);
    return sp.cs > 1 || sp.rs > 1;
  }

  function cellSpanForWidget(cell) {
    return {
      cs: Math.max(1, parseInt(cell.getAttribute('colspan') || '1', 10) || 1),
      rs: Math.max(1, parseInt(cell.getAttribute('rowspan') || '1', 10) || 1)
    };
  }

  function syncFaceChecksLayout(widget, w, inline) {
    var face = widget.querySelector('.eap-w-checks');
    if (!face) return;
    var merged = widgetInMergedCell(widget);
    var scale = parseFloat(widget.getAttribute('data-eap-check-scale') || '100');
    if (!(scale > 0)) scale = 100;
    face.style.setProperty('--eap-check-scale', String(scale / 100));
    if (merged || (w && w.indexOf('%') >= 0)) {
      widget.removeAttribute('data-eap-inline');
      widget.style.display = 'block';
      widget.style.width = w || '100%';
      widget.style.maxWidth = '100%';
      widget.style.margin = '0';
      var wrap = widget.querySelector('.eap-w-face-wrap');
      if (wrap) {
        wrap.style.display = 'block';
        wrap.style.width = '100%';
        wrap.style.maxWidth = '100%';
      }
      face.style.display = 'flex';
      face.style.flexWrap = 'wrap';
      face.style.alignItems = 'center';
      face.style.alignContent = 'center';
      face.style.gap = '8px 16px';
      face.style.width = w || '100%';
      face.style.maxWidth = '100%';
      var align = widget.getAttribute('data-eap-check-align') || 'start';
      face.style.justifyContent = align === 'center' ? 'center' : (align === 'end' ? 'flex-end' : 'flex-start');
    } else if (inline) {
      widget.style.display = 'inline-block';
      face.style.display = '';
      if (w) {
        face.style.width = w;
        face.style.maxWidth = '100%';
      } else {
        face.style.width = '';
        face.style.maxWidth = '';
      }
    } else {
      face.style.display = '';
      face.style.width = w || '';
      face.style.maxWidth = w ? '100%' : '';
    }
  }

  function syncFaceInputWidth(widget, w, inline) {
    var faceInputs = widget.querySelectorAll('.eap-w-text-inp, .eap-w-amt-inp');
    var effW = w || (inline ? defaultInlineWidth(widget) : '');
    var isPct = isPercentWidth(effW);
    var wrap = widget.querySelector('.eap-w-face-wrap');
    if (wrap) {
      if (inline && isPct) {
        wrap.style.display = 'inline-block';
        wrap.style.width = '100%';
        wrap.style.maxWidth = '100%';
      } else if (inline) {
        wrap.style.width = '';
        wrap.style.maxWidth = '';
      }
    }
    faceInputs.forEach(function (inp) {
      if (inline) {
        if (isPct) {
          inp.style.width = '100%';
          inp.style.maxWidth = '100%';
        } else if (effW) {
          inp.style.width = effW;
          inp.style.maxWidth = '100%';
        } else {
          inp.style.width = '';
          inp.style.maxWidth = '';
        }
      } else if (w) {
        inp.style.width = '100%';
        inp.style.maxWidth = '';
      } else {
        inp.style.width = '';
        inp.style.maxWidth = '';
      }
    });
  }

  function applyWidgetLayout(widget) {
    if (!widget || !widget.classList.contains('eap-widget')) return;
    var w = widget.getAttribute('data-eap-width') || '';
    var type = widget.getAttribute('data-eap-type') || '';
    var merged = widgetInMergedCell(widget);
    var isChecks = type === 'checkbox' || type === 'radio';
    var inline = widget.getAttribute('data-eap-inline') === '1'
      || (widgetInTableCell(widget) && !merged && !isChecks);
    if (isChecks && merged) widget.removeAttribute('data-eap-inline');
    if (inline) {
      widget.setAttribute('data-eap-inline', '1');
      widget.style.display = 'inline-block';
      // em/px → input에만. % → 셀 기준 shell에 적용 후 input 100%
      if (isPercentWidth(w)) {
        widget.style.width = w;
        widget.style.maxWidth = '100%';
        widget.style.minWidth = '0';
      } else {
        widget.style.width = 'auto';
        widget.style.maxWidth = '100%';
        widget.style.minWidth = '';
      }
      widget.style.verticalAlign = 'baseline';
      widget.style.margin = '0 2px';
    } else {
      widget.style.display = '';
      widget.style.width = w || '';
      widget.style.maxWidth = '';
      widget.style.verticalAlign = '';
      widget.style.margin = '';
    }
    syncFaceInputWidth(widget, w, inline);
    syncFaceChecksLayout(widget, w, inline);
  }

  function insertNodeAtPoint(node, x, y) {
    if (!node) return false;
    var range = null;
    if (document.caretRangeFromPoint) {
      range = document.caretRangeFromPoint(x, y);
    } else if (document.caretPositionFromPoint) {
      var pos = document.caretPositionFromPoint(x, y);
      if (pos) {
        range = document.createRange();
        range.setStart(pos.offsetNode, pos.offset);
        range.collapse(true);
      }
    }
    if (!range) return false;
    var host = range.commonAncestorContainer;
    if (host.nodeType === 3) host = host.parentNode;
    if (!host || !editor.contains(host)) return false;
    if (host.closest && host.closest('.eap-widget, .eap-widget-block, .eap-approval-line')) return false;
    range.insertNode(node);
    if (node.parentNode && node.parentNode.normalize) node.parentNode.normalize();
    return true;
  }

  function hourSelectHtml() {
    var h = '<select class="eap-w-h" disabled>';
    for (var i = 0; i < 24; i++) {
      var v = (i < 10 ? '0' : '') + i;
      h += '<option value="' + v + '">' + v + '</option>';
    }
    return h + '</select><span class="eap-w-unit">시</span>';
  }

  function minuteSelectHtml() {
    var h = '<select class="eap-w-m" disabled>';
    for (var i = 0; i < 60; i++) {
      var v = (i < 10 ? '0' : '') + i;
      h += '<option value="' + v + '">' + v + '</option>';
    }
    return h + '</select><span class="eap-w-unit">분</span>';
  }

  function faceHtmlForType(type, opts, ph, el) {
    if (type === 'select') {
      var items = opts.length ? opts : ['옵션1', '옵션2', '옵션3'];
      var h = '<span class="eap-w-face eap-w-select"><select disabled class="eap-w-select-el">';
      h += '<option>' + escHtml(ph || '선택하세요') + '</option>';
      items.forEach(function (o) { h += '<option>' + escHtml(o) + '</option>'; });
      return h + '</select></span>';
    }
    if (type === 'checkbox') {
      var ck = opts.length ? opts : ['옵션1'];
      var c = '<span class="eap-w-face eap-w-checks">';
      ck.forEach(function (o) {
        c += '<label class="eap-w-check-item"><input type="checkbox" disabled/><span class="eap-w-check-lbl">' + escHtml(o) + '</span></label>';
      });
      return c + '</span>';
    }
    if (type === 'radio') {
      var rd = opts.length ? opts : ['옵션1'];
      var r = '<span class="eap-w-face eap-w-checks">';
      rd.forEach(function (o) {
        r += '<label class="eap-w-check-item"><input type="radio" disabled/><span class="eap-w-check-lbl">' + escHtml(o) + '</span></label>';
      });
      return r + '</span>';
    }
    if (type === 'time') {
      return '<span class="eap-w-face eap-w-time">' + hourSelectHtml() + minuteSelectHtml() + '</span>';
    }
    if (type === 'period') {
      return '<span class="eap-w-face eap-w-period">'
        + hourSelectHtml() + minuteSelectHtml()
        + '<input type="date" class="eap-w-date" disabled/>'
        + '<span class="eap-w-tilde">~</span>'
        + hourSelectHtml() + minuteSelectHtml()
        + '<input type="date" class="eap-w-date" disabled/>'
        + '</span>';
    }
    if (type === 'date') {
      return '<span class="eap-w-face eap-w-date-only">'
        + '<span class="eap-w-date-wrap">'
        + '<span class="eap-w-date-icon" aria-hidden="true"></span>'
        + '<input type="date" class="eap-w-date" disabled/></span></span>';
    }
    if (type === 'amount') {
      return '<span class="eap-w-face eap-w-amount"><span class="eap-w-currency">₩</span>'
        + '<input type="text" disabled class="eap-w-amt-inp"' + faceWidthAttr(el, defaultInlineWidth(el))
        + ' value="' + escHtml(ph || '0') + '"/></span>';
    }
    if (type === 'number') {
      return '<span class="eap-w-face eap-w-text"><input type="text" disabled class="eap-w-text-inp"'
        + faceWidthAttr(el, defaultInlineWidth(el))
        + ' value="' + escHtml(ph || '0') + '"/></span>';
    }
    if (type === 'text' || type === 'user' || type === 'dept') {
      return '<span class="eap-w-face eap-w-text"><input type="text" disabled class="eap-w-text-inp"'
        + faceWidthAttr(el, defaultInlineWidth(el))
        + ' placeholder="' + escHtml(ph || '입력') + '"/></span>';
    }
    if (type === 'sum_display') {
      var g = el ? (el.getAttribute('data-eap-sum-group') || '') : '';
      return '<span class="eap-w-face eap-w-sum">Σ ' + escHtml(g || '합계') + ' = <strong>0</strong></span>';
    }
    return '<span class="eap-w-ph">' + escHtml(ph) + '</span>';
  }

  function renderWidgetFace(el) {
    if (!el || !el.classList.contains('eap-widget')) return;
    var type = el.getAttribute('data-eap-type') || '';
    var ph = el.getAttribute('data-eap-placeholder') || PLACEHOLDER[type] || '입력';
    var opts = parseOptions(el);
    var del = el.querySelector('.eap-w-del');
    var wrap = el.querySelector('.eap-w-face-wrap');
    if (!wrap) {
      wrap = document.createElement('span');
      wrap.className = 'eap-w-face-wrap';
      var oldPh = el.querySelector('.eap-w-ph');
      if (oldPh) oldPh.remove();
      if (del) el.insertBefore(wrap, del.nextSibling);
      else el.appendChild(wrap);
    }
    wrap.innerHTML = faceHtmlForType(type, opts, ph, el);
    applyWidgetLayout(el);
  }

  /** 제목이 비었거나 기본 문구('양식 제목') 그대로면 "실제 제목이 없다"고 본다. */
  function isPlaceholderTitle(titleEl) {
    if (!titleEl) return true;
    var t = String(titleEl.textContent || '').replace(/\u00a0/g, ' ').trim();
    return t === '' || t === '양식 제목';
  }

  function mergeAdjacentHeaders() {
    // 붙어 있는 머리글 블록을 하나로 합친다.
    //
    // 예전 코드에는 두 가지 결함이 있었다.
    //  (1) 첫 분기에서 b 의 **제목을 옮기지 않고** b 를 통째로 지웠다. 그래서
    //      '양식 제목'(빈 껍데기) + '거 래 명 세 서'(진짜 제목+결재선) 순서인 문서를
    //      열면 결재선만 살아남고 **사용자가 지정한 제목이 삭제**됐다.
    //      (운영 서식 2026-0001 이 정확히 이 상태였다.)
    //  (2) headers 가 정적 NodeList 인데 b.remove() 후 i-- 를 해서 이미 떨어져 나간
    //      노드를 다시 검사했다. 머리글이 3개 이상이면 끝까지 합쳐지지 않았다.
    //      → 매 회차 다시 조회한다.
    var guard = 0;
    while (guard++ < 50) {
      var headers = editor.querySelectorAll('.eap-doc-header');
      var merged = false;
      for (var i = 0; i < headers.length - 1; i++) {
        var a = headers[i];
        var b = headers[i + 1];
        if (a.nextElementSibling !== b) continue;
        var aTitle = a.querySelector('.eap-title');
        var aAppr = a.querySelector('.eap-approval-line');
        var bTitle = b.querySelector('.eap-title');
        var bAppr = b.querySelector('.eap-approval-line');
        if (aTitle && !aAppr && bAppr) {
          // a 의 제목이 기본 문구뿐이면 b 의 진짜 제목으로 갈아 끼운다.
          if (bTitle && isPlaceholderTitle(aTitle) && !isPlaceholderTitle(bTitle)) {
            aTitle.innerHTML = bTitle.innerHTML;
          }
          a.appendChild(bAppr);
          b.remove();
          merged = true;
          break;
        } else if (!aTitle && aAppr && bTitle) {
          a.insertBefore(bTitle, a.firstChild);
          b.remove();
          merged = true;
          break;
        }
      }
      if (!merged) break;
    }
  }

  function isTitleLayoutTable(table) {
    if (!table || !table.querySelectorAll) return false;
    if (table.classList.contains('eap-approval-line') || table.classList.contains('eap-product-table')) return false;
    if (table.closest('.eap-approval-line, .eap-product-table')) return false;
    if (table.parentElement && table.parentElement.closest('table')) return false;
    if (table.querySelector('.eap-widget, .eap-widget-block, input, select, textarea')) return false;
    if (table.querySelector('.eap-row-plus, .eap-row-minus, tr.eap-row-tools')) return false;
    var rows = table.querySelectorAll('tr');
    if (rows.length !== 1) return false;
    var cells = rows[0].querySelectorAll('td, th');
    if (cells.length !== 1) return false;
    var cell = cells[0];
    if ((cell.colSpan || 1) > 1 || (cell.rowSpan || 1) > 1) return false;
    var text = (cell.textContent || '').replace(/\s+/g, '').trim();
    if (!text || text.length > 40) return false;
    return true;
  }

  function titleStyleFromCell(cell, table) {
    var style = {};
    var align = (cell.style && cell.style.textAlign) || (table.style && table.style.textAlign) || cell.getAttribute('align') || table.getAttribute('align') || '';
    if (align) style.textAlign = align;
    var fontSize = cell.style && cell.style.fontSize;
    if (fontSize) style.fontSize = fontSize;
    var styled = cell.querySelector('[style*="font-size"], font[size]');
    if (!style.fontSize && styled) {
      if (styled.style && styled.style.fontSize) style.fontSize = styled.style.fontSize;
      else if (styled.getAttribute('size')) {
        var map = { 1: '8pt', 2: '10pt', 3: '12pt', 4: '14pt', 5: '18pt', 6: '24pt', 7: '36pt' };
        style.fontSize = map[styled.getAttribute('size')] || '';
      }
    }
    return style;
  }

  function migrateTitleLayoutTables(root) {
    if (!root || !root.querySelectorAll) return;
    Array.prototype.slice.call(root.querySelectorAll('table')).forEach(function (table) {
      if (!isTitleLayoutTable(table)) return;
      var cell = table.querySelector('td, th');
      if (!cell) return;
      var header = document.createElement('div');
      header.className = 'eap-doc-header';
      header.contentEditable = 'false';
      var title = document.createElement('div');
      title.className = 'eap-title';
      title.contentEditable = 'true';
      title.innerHTML = cell.innerHTML;
      var style = titleStyleFromCell(cell, table);
      if (style.textAlign) title.style.textAlign = style.textAlign;
      if (style.fontSize) title.style.fontSize = style.fontSize;
      header.appendChild(title);
      ensureHeaderChrome(header);
      if (table.parentNode) table.parentNode.replaceChild(header, table);
    });
  }

  function normalizeDocLayout() {
    migrateTitleLayoutTables(editor);
    editor.querySelectorAll('.eap-doc-title').forEach(function (title) {
      title.className = 'eap-title';
    });
    editor.querySelectorAll('.eap-title').forEach(function (title) {
      if (title.closest('.eap-doc-header')) return;
      var header = document.createElement('div');
      header.className = 'eap-doc-header';
      header.contentEditable = 'false';
      title.parentNode.insertBefore(header, title);
      header.appendChild(title);
    });
    editor.querySelectorAll('.eap-approval-line').forEach(function (tbl) {
      var header = tbl.closest('.eap-doc-header');
      if (header) return;
      var prev = tbl.previousElementSibling;
      if (prev && prev.classList.contains('eap-doc-header')) {
        prev.appendChild(tbl);
        return;
      }
      header = document.createElement('div');
      header.className = 'eap-doc-header';
      header.contentEditable = 'false';
      tbl.parentNode.insertBefore(header, tbl);
      header.appendChild(tbl);
    });
    mergeAdjacentHeaders();
    editor.querySelectorAll('.eap-doc-header').forEach(function (header) {
      ensureHeaderChrome(header);
    });
  }

  function bumpUidFrom(id) {
    if (!id) return;
    var n = parseInt(String(id).replace(/\D/g, ''), 10);
    if (!isNaN(n) && n > widgetUid) widgetUid = n;
  }

  function ensureWidgetChrome(el) {
    if (!el || !el.classList.contains('eap-widget')) return;
    el.setAttribute('draggable', 'true');
    el.contentEditable = 'false';
    if (!el.querySelector('.eap-w-del')) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'eap-w-del';
      btn.title = '삭제';
      btn.textContent = '🗑';
      el.insertBefore(btn, el.firstChild);
    }
    if (!el.querySelector('.eap-w-face-wrap')) {
      var wrap = document.createElement('span');
      wrap.className = 'eap-w-face-wrap';
      el.appendChild(wrap);
    }
  }

  function fieldOptsFromEl(el) {
    return {
      id: el.getAttribute('data-eap-id') || nextWid(),
      label: el.getAttribute('data-eap-label') || '',
      placeholder: el.getAttribute('data-eap-placeholder') || '',
      options: (el.getAttribute('data-eap-options') || '').replace(/\\n/g, '\n'),
      required: el.getAttribute('data-eap-required') === '1',
      sumGroup: el.getAttribute('data-eap-sum-group') || '',
      showField: el.getAttribute('data-eap-show-field') || '',
      showValue: el.getAttribute('data-eap-show-value') || ''
    };
  }

  function stripFieldAttrs(el) {
    ['data-eap-id', 'data-eap-type', 'data-eap-label', 'data-eap-required',
      'data-eap-label-width', 'data-eap-options', 'data-eap-placeholder',
      'data-eap-sum-group', 'data-eap-show-field', 'data-eap-show-value', 'data-eap-auto'
    ].forEach(function (a) { el.removeAttribute(a); });
  }

  function migrateLegacyFormFields() {
    editor.querySelectorAll('tr.eap-field[data-eap-type]').forEach(function (row) {
      var type = row.getAttribute('data-eap-type') || 'text';
      var opts = fieldOptsFromEl(row);
      bumpUidFrom(opts.id);
      var val = row.querySelector('td.eap-val, th.eap-val') || row.cells[row.cells.length - 1];
      if (!val) return;
      val.innerHTML = widgetHtml(type, opts);
      val.classList.remove('eap-val');
      if (!val.className) val.removeAttribute('class');
      row.removeAttribute('contenteditable');
      stripFieldAttrs(row);
      row.classList.remove('eap-field');
      if (!row.className) row.removeAttribute('class');
    });
    editor.querySelectorAll('td.eap-grid-field[data-eap-type], th.eap-grid-field[data-eap-type]').forEach(function (td) {
      var type = td.getAttribute('data-eap-type') || 'text';
      var opts = fieldOptsFromEl(td);
      bumpUidFrom(opts.id);
      td.innerHTML = widgetHtml(type, opts);
      stripFieldAttrs(td);
      td.classList.remove('eap-grid-field');
      td.removeAttribute('contenteditable');
      if (!td.className) td.removeAttribute('class');
    });
    editor.querySelectorAll('.eap-del').forEach(function (el) { el.remove(); });
    editor.querySelectorAll('table.eap-form-table, table.eap-product-table, table.eap-compact-table').forEach(function (t) {
      if (!t.classList.contains('eap-approval-line')) t.removeAttribute('contenteditable');
      if (t.querySelector('colgroup')) return;
      var row = t.querySelector('tr');
      if (!row || !row.cells.length) return;
      var n = row.cells.length;
      var lbl = row.querySelector('.eap-lbl');
      var lw = 28;
      if (lbl && lbl.style.width) lw = parseInt(lbl.style.width, 10) || 28;
      var cg = document.createElement('colgroup');
      for (var i = 0; i < n; i++) {
        var col = document.createElement('col');
        col.style.width = n === 2
          ? ((i === 0 ? lw : (100 - lw)) + '%')
          : ((100 / n).toFixed(2) + '%');
        cg.appendChild(col);
      }
      t.insertBefore(cg, t.firstChild);
    });
  }

  function collectFormSchema() {
    var out = [];
    editor.querySelectorAll('.eap-widget[data-eap-type], .eap-field[data-eap-type], .eap-grid-field[data-eap-type]').forEach(function (el) {
      if (el.classList.contains('eap-approval-line') || isApprovalType(el.getAttribute('data-eap-type'))) return;
      bumpUidFrom(el.getAttribute('data-eap-id'));
      out.push({
        id: el.getAttribute('data-eap-id'),
        type: el.getAttribute('data-eap-type'),
        label: el.getAttribute('data-eap-label') || '',
        required: el.getAttribute('data-eap-required') === '1',
        labelWidth: parseInt(el.getAttribute('data-eap-label-width'), 10) || 28,
        options: (el.getAttribute('data-eap-options') || '').replace(/\\n/g, '\n'),
        placeholder: el.getAttribute('data-eap-placeholder') || '',
        sumGroup: el.getAttribute('data-eap-sum-group') || '',
        showField: el.getAttribute('data-eap-show-field') || '',
        showValue: el.getAttribute('data-eap-show-value') || ''
      });
    });
    return out;
  }

  function refreshAllWidgetFaces() {
    normalizeDocLayout();
    editor.querySelectorAll('.eap-doc-header').forEach(ensureHeaderChrome);
    editor.querySelectorAll('.eap-widget[data-eap-type]').forEach(function (el) {
      bumpUidFrom(el.getAttribute('data-eap-id'));
      ensureWidgetChrome(el);
      var wtype = el.getAttribute('data-eap-type') || '';
      var merged = widgetInMergedCell(el);
      var isChecks = wtype === 'checkbox' || wtype === 'radio';
      if (widgetInTableCell(el) && !merged && !isChecks && !el.getAttribute('data-eap-inline')) {
        el.setAttribute('data-eap-inline', '1');
      }
      if (isChecks && merged) el.removeAttribute('data-eap-inline');
      renderWidgetFace(el);
      applyWidgetLayout(el);
    });
  }

  function approvalLineHtml(type, opts) {
    opts = opts || {};
    var cols = opts.cols || 5;
    var id = nextWid();
    var lbl = type === 'approval_agree' ? '합<br>의' : (type === 'approval_receive' ? '수<br>신' : '결<br>재');
    var h = '<table class="eap-widget-block eap-approval-line eap-editable-table" contenteditable="false"'
      + ' data-eap-type="' + type + '" data-eap-id="' + id + '" data-eap-cols="' + cols + '"><tbody><tr>';
    h += '<td class="eap-appr-lbl" rowspan="2">' + lbl + '</td>';
    for (var i = 0; i < cols; i++) h += '<td class="eap-appr-head"></td>';
    h += '</tr><tr>';
    for (var j = 0; j < cols; j++) h += '<td class="eap-appr-sign"></td>';
    h += '</tr></tbody></table>';
    return h;
  }

  function docHeaderHtml(titleText, approvalType) {
    titleText = titleText || '거 &nbsp;래 &nbsp;명 &nbsp;세 &nbsp;서';
    return '<div class="eap-doc-header" contenteditable="false">'
      + '<div class="eap-title-wrap">'
      + '<button type="button" class="eap-h-del" title="제목 삭제">🗑</button>'
      + '<div class="eap-title" contenteditable="true">' + titleText + '</div>'
      + '</div>'
      + approvalLineHtml(approvalType || 'approval_line', { cols: 5 })
      + '</div>';
  }

  function titleBlockHtml(titleText) {
    titleText = titleText || '양식 제목';
    return '<div class="eap-doc-header" contenteditable="false">'
      + '<div class="eap-title-wrap">'
      + '<button type="button" class="eap-h-del" title="제목 삭제">🗑</button>'
      + '<div class="eap-title" contenteditable="true">' + titleText + '</div>'
      + '</div></div>';
  }

  function ensureHeaderChrome(header) {
    if (!header || !header.classList.contains('eap-doc-header')) return;
    var title = header.querySelector('.eap-title');
    if (!title) return;
    var wrap = title.closest('.eap-title-wrap');
    if (!wrap) {
      wrap = document.createElement('div');
      wrap.className = 'eap-title-wrap';
      title.parentNode.insertBefore(wrap, title);
      wrap.appendChild(title);
    }
    if (!wrap.querySelector('.eap-h-del')) {
      var btn = document.createElement('button');
      btn.type = 'button';
      btn.className = 'eap-h-del';
      btn.title = '제목 삭제';
      btn.textContent = '🗑';
      wrap.insertBefore(btn, title);
    }
  }

  function deleteDocHeaderTitle(header) {
    if (!header) return;
    if (header.querySelector('.eap-approval-line')) {
      var wrap = header.querySelector('.eap-title-wrap');
      if (wrap) wrap.remove();
    } else {
      header.remove();
    }
    clearWidgetSelection();
  }
  function findDocHeaderNearCursor() {
    var sel = window.getSelection();
    if (!sel || !sel.rangeCount) return null;
    var n = sel.anchorNode;
    if (n && n.nodeType === 3) n = n.parentElement;
    if (!n || !editor.contains(n)) return null;
    var inHeader = n.closest && n.closest('.eap-doc-header');
    if (inHeader && editor.contains(inHeader)) return inHeader;
    var headers = editor.querySelectorAll('.eap-doc-header');
    for (var i = headers.length - 1; i >= 0; i--) {
      if (!headers[i].querySelector('.eap-approval-line')) return headers[i];
    }
    return null;
  }

  function widgetHtml(type, opts) {
    opts = opts || {};
    if (type === 'doc_header') return docHeaderHtml();
    if (type === 'title_block') return titleBlockHtml();
    if (type === 'richtext_block') {
      return '<div class="eap-doc-body" style="min-height:80px;border:1px dashed #CCC;padding:8px;margin:8px 0"><p>본문 내용을 입력하세요.</p></div>';
    }
    if (isApprovalType(type)) return approvalLineHtml(type, opts);

    var id = opts.id || nextWid();
    var ph = opts.placeholder || PLACEHOLDER[type] || '입력';
    var label = opts.label || WIDGET_LABEL[type] || '항목';
    var auto = isAuto(type) ? ' data-eap-auto="1"' : '';
    var optsAttr = opts.options ? ' data-eap-options="' + escAttr(opts.options) + '"' : '';
    if (type === 'select' && !opts.options) optsAttr = ' data-eap-options="옵션1\\n옵션2\\n옵션3"';
    if ((type === 'checkbox' || type === 'radio') && !opts.options) {
      optsAttr = ' data-eap-options="옵션1\\n옵션2"';
    }
    var req = opts.required ? '1' : '0';
    var sumVal = opts.sumGroup != null && opts.sumGroup !== ''
      ? opts.sumGroup
      : (type === 'sum_display' ? '합계' : '');
    var showF = opts.showField || '';
    var showV = opts.showValue || '';
    var faceOpts = opts.options
      ? opts.options.replace(/\\n/g, '\n').split('\n').filter(Boolean)
      : (type === 'select' ? ['옵션1', '옵션2', '옵션3'] : (type === 'checkbox' || type === 'radio' ? ['옵션1', '옵션2'] : []));
    var face = faceHtmlForType(type, faceOpts, ph, null);
    return '<span class="eap-widget' + (type === 'sum_display' ? ' eap-sum-display' : '') + '" contenteditable="false" draggable="true"'
      + ' data-eap-id="' + id + '" data-eap-type="' + type + '"'
      + ' data-eap-label="' + escAttr(label) + '" data-eap-required="' + req + '"'
      + ' data-eap-sum-group="' + escAttr(sumVal) + '"'
      + ' data-eap-show-field="' + escAttr(showF) + '" data-eap-show-value="' + escAttr(showV) + '"'
      + optsAttr + auto + '>'
      + '<button type="button" class="eap-w-del" title="삭제">🗑</button>'
      + '<span class="eap-w-face-wrap">' + face + '</span></span>';
  }

  function buildPalette() {
    var body = document.getElementById('paletteBody');
    if (!body) return;
    body.innerHTML = '';
    PALETTE.forEach(function (sec) {
      var d = document.createElement('div');
      d.className = 'palSec';
      d.innerHTML = '<h4>' + sec.title + '</h4>';
      sec.items.forEach(function (it) {
        var b = document.createElement('button');
        b.type = 'button';
        b.className = 'palItem';
        b.textContent = it.label;
        b.title = '셀을 선택한 뒤 클릭하거나, 셀로 드래그';
        b.draggable = true;
        b.addEventListener('click', function () { insertWidget(it.type); });
        b.addEventListener('dragstart', function (e) {
          dragType = it.type;
          dragWidget = null;
          e.dataTransfer.setData('text/plain', it.type);
          e.dataTransfer.effectAllowed = 'copy';
        });
        d.appendChild(b);
      });
      body.appendChild(d);
    });
  }

  function selectedCell() {
    return editor.querySelector('td.eap-cell-on, th.eap-cell-on');
  }

  function isInlineFieldType(type) {
    return type !== 'doc_header' && type !== 'title_block' && type !== 'richtext_block' && !isApprovalType(type);
  }

  function insertHtmlInto(target, html) {
    if (!html) return;
    if (target) {
      if (target.innerHTML === '&nbsp;' || target.innerHTML === '\u00a0') target.innerHTML = '';
      target.insertAdjacentHTML('beforeend', html);
      return;
    }
    if (global.insertHtml) global.insertHtml(html);
    else editor.insertAdjacentHTML('beforeend', html);
  }

  function lastInserted(scope) {
    var root = scope || editor;
    var nodes = root.querySelectorAll('.eap-widget, .eap-widget-block, .eap-approval-line, .eap-doc-header');
    return nodes.length ? nodes[nodes.length - 1] : null;
  }

  function insertWidgetAtPoint(type, x, y, cell) {
    if (!type || !cell || !isInlineFieldType(type)) return false;
    var html = widgetHtml(type);
    var holder = document.createElement('span');
    holder.innerHTML = html;
    var widget = holder.firstElementChild;
    if (!widget) return false;
    if (cell.innerHTML === '&nbsp;' || cell.innerHTML === '\u00a0') cell.innerHTML = '';
    if (!insertNodeAtPoint(widget, x, y)) cell.appendChild(widget);
    widget.setAttribute('data-eap-inline', '1');
    if (!widget.getAttribute('data-eap-width')
        && ['text', 'number', 'amount', 'date', 'select', 'time'].indexOf(type) >= 0) {
      widget.setAttribute('data-eap-width', '10em');
    }
    applyWidgetLayout(widget);
    renderWidgetFace(widget);
    selectWidget(widget);
    if (global.focusEditor) global.focusEditor();
    return true;
  }

  function insertWidget(type, intoCell) {
    if (global.isSourceMode && global.isSourceMode()) return;
    var html;
    var selectAfter;
    var cell = (intoCell !== undefined)
      ? intoCell
      : (isInlineFieldType(type) ? selectedCell() : null);

    if (type === 'title_block') {
      var header = findDocHeaderNearCursor();
      if (header && !header.querySelector('.eap-title')) {
        header.insertAdjacentHTML('afterbegin',
          '<div class="eap-title-wrap"><button type="button" class="eap-h-del" title="제목 삭제">🗑</button>'
          + '<div class="eap-title" contenteditable="true">양식 제목</div></div>');
        ensureHeaderChrome(header);
        selectAfter = header;
      } else if (!header) {
        html = widgetHtml(type);
      } else {
        // 이미 제목이 있는 머리글이다. 예전에는 여기서 아무 것도 하지 않아
        // 버튼이 고장난 것처럼 보였고, 그래서 사용자가 대신 「제목+결재선」을
        // 눌러 머리글 중복을 만들었다. 기존 제목을 선택해 바로 고칠 수 있게 한다.
        selectAfter = header;
      }
    } else if (isApprovalType(type)) {
      var tableHtml = approvalLineHtml(type, { cols: 5 });
      var hdr = findDocHeaderNearCursor();
      if (hdr) {
        var existing = hdr.querySelector('.eap-approval-line');
        if (existing) existing.outerHTML = tableHtml;
        else hdr.insertAdjacentHTML('beforeend', tableHtml);
        selectAfter = hdr.querySelector('.eap-approval-line');
      } else {
        html = '<div class="eap-doc-header" contenteditable="false">' + tableHtml + '</div>';
      }
    } else if (type === 'doc_header') {
      // 「제목+결재선」은 **기존 머리글을 재사용**한다.
      //
      // 예전에는 머리글이 이미 있어도 무조건 새 .eap-doc-header 를 통째로 덧붙였다.
      // 「제목」을 눌렀다가(제목만 생김) 결재선을 붙이려고 「제목+결재선」을 누르는
      // 아주 자연스러운 순서만으로 **머리글이 두 개가 되어 그대로 저장**됐고,
      // 그 서식을 다시 열면 병합 과정에서 진짜 제목이 사라졌다.
      var docHdr = findDocHeaderNearCursor();
      if (docHdr) {
        if (!docHdr.querySelector('.eap-title')) {
          docHdr.insertAdjacentHTML('afterbegin',
            '<div class="eap-title-wrap"><button type="button" class="eap-h-del" title="제목 삭제">🗑</button>'
            + '<div class="eap-title" contenteditable="true">양식 제목</div></div>');
        }
        if (!docHdr.querySelector('.eap-approval-line')) {
          docHdr.insertAdjacentHTML('beforeend', approvalLineHtml('approval_line', { cols: 5 }));
        }
        ensureHeaderChrome(docHdr);
        selectAfter = docHdr;
      } else {
        html = widgetHtml(type);
      }
    } else {
      html = widgetHtml(type);
    }

    insertHtmlInto(cell, html);
    if (global.focusEditor) global.focusEditor();

    if (!selectAfter) selectAfter = lastInserted(cell || editor);
    if (selectAfter && selectAfter.classList && selectAfter.classList.contains('eap-widget')) {
      if (cell) {
        selectAfter.setAttribute('data-eap-inline', '1');
        if (!selectAfter.getAttribute('data-eap-width')
            && ['text', 'number', 'amount', 'date', 'select', 'time'].indexOf(type) >= 0) {
          selectAfter.setAttribute('data-eap-width', '10em');
        }
        applyWidgetLayout(selectAfter);
        renderWidgetFace(selectAfter);
      }
    }
    if (selectAfter) {
      if (selectAfter.classList.contains('eap-doc-header')) selectTitleHeader(selectAfter);
      else selectWidget(selectAfter);
    }
    if (selectAfter && isApprovalType(type) && global.prepareEditableTable) {
      global.prepareEditableTable(selectAfter.closest('table') || selectAfter);
    }
  }

  function clearWidgetSelection() {
    editor.querySelectorAll('.eap-widget.eap-on, .eap-widget-block.eap-on, .eap-approval-line.eap-on, .eap-doc-header.eap-on, .eap-doc-body.eap-on, .eap-block.eap-on').forEach(function (el) {
      el.classList.remove('eap-on');
    });
    selectedWidget = null;
    syncInspEmpty(true);
  }

  function selectTitleHeader(header) {
    if (!header) return;
    if (global.clearTableSelectionOnly) global.clearTableSelectionOnly();
    if (global.hideImgBox) global.hideImgBox();
    editor.querySelectorAll('.eap-doc-header.eap-on').forEach(function (el) {
      if (el !== header) el.classList.remove('eap-on');
    });
    editor.querySelectorAll('.eap-widget.eap-on, .eap-widget-block.eap-on, .eap-approval-line.eap-on').forEach(function (el) {
      el.classList.remove('eap-on');
    });
    selectedWidget = header;
    header.classList.add('eap-on');
    syncInspector();
  }

  function syncInspEmpty(empty) {
    var e = document.getElementById('inspEmpty');
    var f = document.getElementById('inspForm');
    var a = document.getElementById('inspApproval');
    var b = document.getElementById('inspBlock');
    var t = document.getElementById('inspTable');
    var del = document.getElementById('inspDel');
    if (!e || !f) return;
    if (empty) {
      e.style.display = 'block';
      f.style.display = 'none';
      if (a) a.style.display = 'none';
      if (b) b.style.display = 'none';
      if (t) t.style.display = 'none';
      if (del) del.style.display = 'none';
      return;
    }
    e.style.display = 'none';
    if (t) t.style.display = 'none';
    if (b) b.style.display = 'none';
    if (del) {
      del.style.display = 'block';
      del.textContent = '🗑 삭제 (Del)';
    }
  }

  function setInspRowVisible(id, show) {
    var el = document.getElementById(id);
    if (!el) return;
    var rowWrap = el.closest('.insp-id-row');
    if (rowWrap) {
      rowWrap.style.display = show ? '' : 'none';
      var label = document.querySelector('label[for="' + id + '"]');
      if (label) label.style.display = show ? '' : 'none';
      var hint = document.getElementById(id + 'Hint');
      if (hint) hint.style.display = show ? '' : 'none';
      return;
    }
    el.style.display = show ? '' : 'none';
    var prev = el.previousElementSibling;
    if (prev && prev.tagName === 'LABEL' && prev.getAttribute('for') === id) {
      prev.style.display = show ? '' : 'none';
    }
    var next = el.nextElementSibling;
    if (next && next.id && /Hint$/i.test(next.id)) {
      next.style.display = show ? '' : 'none';
    }
  }

  function isConditionFieldType(type) {
    return type && type !== 'sum_display' && !isAuto(type);
  }

  function listEditorFields(excludeEl) {
    var out = [];
    editor.querySelectorAll('.eap-widget[data-eap-id][data-eap-type]').forEach(function (el) {
      if (el === excludeEl) return;
      var type = el.getAttribute('data-eap-type') || '';
      if (!isConditionFieldType(type)) return;
      var id = (el.getAttribute('data-eap-id') || '').trim();
      if (!id) return;
      var label = (el.getAttribute('data-eap-label') || WIDGET_LABEL[type] || id).trim();
      out.push({ id: id, label: label || id, type: type });
    });
    out.sort(function (a, b) {
      return a.label.localeCompare(b.label, 'ko');
    });
    return out;
  }

  function fillShowFieldSelect(selectedId) {
    var sel = document.getElementById('inspShowField');
    if (!sel) return;
    var current = selectedId != null ? String(selectedId) : sel.value;
    sel.innerHTML = '<option value="">(없음 — 항상 표시)</option>';
    listEditorFields(selectedWidget).forEach(function (f) {
      var opt = document.createElement('option');
      opt.value = f.id;
      opt.textContent = f.label;
      opt.title = f.id;
      sel.appendChild(opt);
    });
    if (current) {
      var found = false;
      for (var i = 0; i < sel.options.length; i++) {
        if (sel.options[i].value === current) {
          found = true;
          break;
        }
      }
      if (!found) {
        var legacy = document.createElement('option');
        legacy.value = current;
        legacy.textContent = current + ' (저장된 ID)';
        sel.appendChild(legacy);
      }
    }
    sel.value = current || '';
  }

  function syncInspector() {
    if (!selectedWidget) { syncInspEmpty(true); return; }
    if (selectedWidget.classList.contains('eap-doc-header')) {
      var block = document.getElementById('inspBlock');
      var f = document.getElementById('inspForm');
      var a = document.getElementById('inspApproval');
      syncInspEmpty(false);
      if (f) f.style.display = 'none';
      if (a) a.style.display = 'none';
      if (block) {
        block.style.display = 'block';
        document.getElementById('inspBlockLabel').textContent = '문서 제목';
        block.querySelector('p').innerHTML = '제목을 클릭해 글자를 고칩니다. <strong>🗑</strong> 버튼 또는 아래 <strong>제목 삭제</strong>로 블록을 제거하세요. 글자 크기·정렬은 제목을 드래그한 뒤 <strong>상단 툴바</strong>를 쓰세요.';
      }
      var del = document.getElementById('inspDel');
      if (del) del.textContent = '🗑 제목 삭제';
      return;
    }
    var type = selectedWidget.getAttribute('data-eap-type') || '';
    var isApproval = isApprovalType(type);
    var a = document.getElementById('inspApproval');
    var f = document.getElementById('inspForm');
    syncInspEmpty(false);
    if (isApproval && a) {
      f.style.display = 'none';
      a.style.display = 'block';
      document.getElementById('inspApprCols').value = selectedWidget.getAttribute('data-eap-cols') || '5';
      document.getElementById('inspApprTypeLabel').textContent = WIDGET_LABEL[type] || '결재선';
      return;
    }
    if (a) a.style.display = 'none';
    f.style.display = 'block';
    document.getElementById('inspTypeLabel').textContent = WIDGET_LABEL[type] || type;
    document.getElementById('inspLabel').value = selectedWidget.getAttribute('data-eap-label') || '';
    document.getElementById('inspRequired').value = selectedWidget.getAttribute('data-eap-required') || '0';
    document.getElementById('inspOptions').value = (selectedWidget.getAttribute('data-eap-options') || '').replace(/\\n/g, '\n');
    document.getElementById('inspPlaceholder').value = selectedWidget.getAttribute('data-eap-placeholder') || '';
    document.getElementById('inspWidth').value = selectedWidget.getAttribute('data-eap-width') || '';
    var checkScaleEl = document.getElementById('inspCheckScale');
    if (checkScaleEl) {
      checkScaleEl.value = selectedWidget.getAttribute('data-eap-check-scale') || '100';
    }
    document.getElementById('inspSumGroup').value = selectedWidget.getAttribute('data-eap-sum-group') || '';
    var fieldId = selectedWidget.getAttribute('data-eap-id') || '';
    if (!fieldId) {
      fieldId = nextWid();
      selectedWidget.setAttribute('data-eap-id', fieldId);
    }
    var fieldIdEl = document.getElementById('inspFieldId');
    if (fieldIdEl) fieldIdEl.value = fieldId;
    fillShowFieldSelect(selectedWidget.getAttribute('data-eap-show-field') || '');
    document.getElementById('inspShowValue').value = selectedWidget.getAttribute('data-eap-show-value') || '';

    var isChecks = type === 'checkbox' || type === 'radio';
    setInspRowVisible('inspOptions', ['select', 'radio', 'checkbox'].indexOf(type) >= 0);
    setInspRowVisible('inspPlaceholder', !isAuto(type) && type !== 'sum_display');
    setInspRowVisible('inspWidth', !isAuto(type) && type !== 'sum_display');
    setInspRowVisible('inspWidthHint', !isAuto(type) && type !== 'sum_display');
    setInspRowVisible('inspCheckScale', isChecks);
    setInspRowVisible('inspCheckScaleHint', isChecks);
    var widthHint = document.getElementById('inspWidthHint');
    if (widthHint) {
      widthHint.textContent = isChecks
        ? '병합 셀에서는 100%를 권장합니다. 셀 전체 너비를 씁니다.'
        : '표 셀 안에서는 글자 옆에 붙습니다. %는 셀 너비 기준, 비우면 10em.';
    }
    setInspRowVisible('inspRequired', !isAuto(type) && type !== 'sum_display');
    setInspRowVisible('inspSumGroup', type === 'amount' || type === 'number' || type === 'sum_display');
    var showCond = isConditionFieldType(type);
    setInspRowVisible('inspFieldId', showCond);
    setInspRowVisible('inspFieldIdHint', showCond);
    setInspRowVisible('inspShowField', showCond);
    setInspRowVisible('inspShowFieldHint', showCond);
    setInspRowVisible('inspShowValue', showCond);
  }

  function applyInspector() {
    if (!selectedWidget) return;
    var type = selectedWidget.getAttribute('data-eap-type') || '';
    if (isApprovalType(type)) {
      rebuildApprovalCols(parseInt(document.getElementById('inspApprCols').value, 10) || 5, type);
      return;
    }
    var label = document.getElementById('inspLabel').value.trim() || WIDGET_LABEL[type] || '항목';
    selectedWidget.setAttribute('data-eap-label', label);
    selectedWidget.setAttribute('data-eap-required', document.getElementById('inspRequired').value);
    selectedWidget.setAttribute('data-eap-options', document.getElementById('inspOptions').value.trim().replace(/\n/g, '\\n'));
    selectedWidget.setAttribute('data-eap-placeholder', document.getElementById('inspPlaceholder').value.trim() || PLACEHOLDER[type] || '');
    var widthVal = document.getElementById('inspWidth').value.trim();
    if (widthVal) selectedWidget.setAttribute('data-eap-width', widthVal);
    else selectedWidget.removeAttribute('data-eap-width');
    if (type === 'checkbox' || type === 'radio') {
      var scaleVal = parseInt(document.getElementById('inspCheckScale').value, 10);
      if (!(scaleVal > 0)) scaleVal = 100;
      scaleVal = Math.max(80, Math.min(200, scaleVal));
      selectedWidget.setAttribute('data-eap-check-scale', String(scaleVal));
    } else {
      selectedWidget.removeAttribute('data-eap-check-scale');
    }
    selectedWidget.setAttribute('data-eap-sum-group', document.getElementById('inspSumGroup').value.trim());
    selectedWidget.setAttribute('data-eap-show-field', document.getElementById('inspShowField').value.trim());
    selectedWidget.setAttribute('data-eap-show-value', document.getElementById('inspShowValue').value.trim());
    renderWidgetFace(selectedWidget);
    applyWidgetLayout(selectedWidget);
  }

  function rebuildApprovalCols(cols, type) {
    type = type || selectedWidget.getAttribute('data-eap-type') || 'approval_line';
    cols = Math.max(2, Math.min(8, cols));
    selectedWidget.setAttribute('data-eap-cols', String(cols));
    var lbl = type === 'approval_agree' ? '합<br>의' : (type === 'approval_receive' ? '수<br>신' : '결<br>재');
    var tbody = selectedWidget.querySelector('tbody');
    if (!tbody) return;
    tbody.innerHTML = '';
    var r1 = document.createElement('tr');
    var lblTd = document.createElement('td');
    lblTd.className = 'eap-appr-lbl';
    lblTd.rowSpan = 2;
    lblTd.innerHTML = lbl;
    r1.appendChild(lblTd);
    for (var i = 0; i < cols; i++) {
      var th = document.createElement('td');
      th.className = 'eap-appr-head';
      r1.appendChild(th);
    }
    tbody.appendChild(r1);
    var r2 = document.createElement('tr');
    for (var j = 0; j < cols; j++) {
      var td = document.createElement('td');
      td.className = 'eap-appr-sign';
      r2.appendChild(td);
    }
    tbody.appendChild(r2);
  }

  function selectWidget(el) {
    if (global.clearTableSelectionOnly) global.clearTableSelectionOnly();
    if (global.hideImgBox) global.hideImgBox();
    clearWidgetSelection();
    selectedWidget = el;
    el.classList.add('eap-on');
    syncInspector();
  }

  function deleteSelectedWidget() {
    if (!selectedWidget) return;
    if (selectedWidget.classList.contains('eap-doc-header')) {
      deleteDocHeaderTitle(selectedWidget);
      return;
    }
    selectedWidget.remove();
    clearWidgetSelection();
  }

  function setupInspectorEvents() {
    ['inspLabel', 'inspRequired', 'inspOptions', 'inspPlaceholder', 'inspWidth', 'inspSumGroup', 'inspShowField', 'inspShowValue'].forEach(function (id) {
      var el = document.getElementById(id);
      if (!el) return;
      el.addEventListener('input', applyInspector);
      el.addEventListener('change', applyInspector);
    });
    var copyBtn = document.getElementById('inspCopyId');
    if (copyBtn) {
      copyBtn.addEventListener('click', function () {
        var id = (document.getElementById('inspFieldId').value || '').trim();
        if (!id) return;
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(id).catch(function () {});
        }
      });
    }
    var ac = document.getElementById('inspApprCols');
    if (ac) ac.addEventListener('change', applyInspector);
    var del = document.getElementById('inspDel');
    if (del) del.addEventListener('click', deleteSelectedWidget);
  }

  function clearDropHint() {
    editor.querySelectorAll('.eap-drop-cell').forEach(function (el) {
      el.classList.remove('eap-drop-cell');
    });
  }

  function setupWidgetDnD() {
    editor.addEventListener('dragstart', function (e) {
      if (e.target.closest && e.target.closest('.eap-w-del')) {
        e.preventDefault();
        return;
      }
      var w = e.target.closest('.eap-widget');
      if (!w || !editor.contains(w)) return;
      dragWidget = w;
      dragType = null;
      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.setData('text/plain', 'widget');
    });
    editor.addEventListener('dragover', function (e) {
      if (!dragType && !dragWidget) return;
      e.preventDefault();
      e.dataTransfer.dropEffect = dragWidget ? 'move' : 'copy';
      clearDropHint();
      var cell = e.target.closest('td, th');
      if (cell && editor.contains(cell)) cell.classList.add('eap-drop-cell');
    });
    editor.addEventListener('dragleave', function (e) {
      var cell = e.target.closest && e.target.closest('td, th');
      if (cell) cell.classList.remove('eap-drop-cell');
    });
    editor.addEventListener('drop', function (e) {
      e.preventDefault();
      var cell = e.target.closest('td, th');
      clearDropHint();
      if (dragWidget) {
        if (cell && editor.contains(cell) && !dragWidget.contains(cell)) {
          if (!insertNodeAtPoint(dragWidget, e.clientX, e.clientY)) {
            if (cell.innerHTML === '&nbsp;' || cell.innerHTML === '\u00a0') cell.innerHTML = '';
            cell.appendChild(dragWidget);
          }
          dragWidget.setAttribute('data-eap-inline', '1');
          applyWidgetLayout(dragWidget);
          selectWidget(dragWidget);
        }
        dragWidget = null;
        return;
      }
      var type = dragType || e.dataTransfer.getData('text/plain');
      dragType = null;
      if (type && isInlineFieldType(type)) {
        var targetCell = cell && editor.contains(cell) ? cell : null;
        if (targetCell && insertWidgetAtPoint(type, e.clientX, e.clientY, targetCell)) return;
        insertWidget(type, targetCell);
      }
      else if (type) insertWidget(type);
    });
    document.addEventListener('dragend', function () {
      dragType = null;
      dragWidget = null;
      clearDropHint();
    });
  }

  function hookEditorClick() {
    editor.addEventListener('click', function (e) {
      if (e.target.closest('#inspector') || e.target.closest('#palette')) return;
      if (e.target.classList.contains('eap-h-del')) {
        e.preventDefault();
        e.stopPropagation();
        deleteDocHeaderTitle(e.target.closest('.eap-doc-header'));
        return;
      }
      if (e.target.classList.contains('eap-w-del')) {
        e.preventDefault();
        e.stopPropagation();
        var w = e.target.closest('.eap-widget, .eap-widget-block, .eap-approval-line');
        if (w) {
          w.remove();
          clearWidgetSelection();
        }
        return;
      }
      var titleEl = e.target.closest('.eap-title');
      if (titleEl && editor.contains(titleEl)) {
        var hdr = titleEl.closest('.eap-doc-header');
        if (hdr) selectTitleHeader(hdr);
        return;
      }
      var widget = e.target.closest('.eap-widget, .eap-widget-block, .eap-approval-line, .eap-doc-header');
      if (widget && editor.contains(widget)) {
        if (widget.classList.contains('eap-doc-header')) {
          var appr = widget.querySelector('.eap-approval-line');
          if (appr && !e.target.closest('.eap-title-wrap')) {
            e.preventDefault();
            selectWidget(appr);
            return;
          }
          e.preventDefault();
          selectTitleHeader(widget);
          return;
        }
        e.preventDefault();
        selectWidget(widget);
        return;
      }
      if (!e.target.closest('.eap-widget, .eap-widget-block, .eap-approval-line, .eap-doc-header, .eap-doc-body, .eap-block')) {
        clearWidgetSelection();
      }
    }, true);
  }

  global.applyWidgetLayout = applyWidgetLayout;
  global.widgetUid = widgetUid;
  global.clearWidgetSelection = clearWidgetSelection;
  global.selectWidget = selectWidget;
  global.insertWidget = insertWidget;
  global.renderWidgetFace = renderWidgetFace;
  global.refreshAllWidgetFaces = refreshAllWidgetFaces;
  global.normalizeDocLayout = normalizeDocLayout;
  global.deleteDocHeaderTitle = deleteDocHeaderTitle;
  global.selectTitleHeader = selectTitleHeader;
  global.migrateTitleLayoutTables = migrateTitleLayoutTables;
  global.migrateLegacyFormFields = migrateLegacyFormFields;
  global.collectFormSchema = collectFormSchema;

  buildPalette();
  setupInspectorEvents();
  hookEditorClick();
  setupWidgetDnD();
  refreshAllWidgetFaces();
})(window);
