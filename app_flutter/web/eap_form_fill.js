// 전자결재 양식 기안 입력 — Phase 3 (검증·합계·조건·피커)
(function () {
  var page = document.getElementById('page');
  var ctx = {};
  var pickTargetId = null;

  function esc(s) {
    return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function autoValue(type) {
    if (type === 'auto_drafter') return ctx.drafter || '';
    if (type === 'auto_dept') return ctx.dept || '';
    if (type === 'auto_email') return ctx.email || '';
    if (type === 'auto_position') return ctx.position || '';
    if (type === 'auto_empno') return ctx.empno || '';
    if (type === 'auto_contact') return ctx.contact || '';
    if (type === 'auto_date') return ctx.date || '';
    if (type === 'auto_complete_date') return ctx.completeDate || '';
    if (type === 'auto_docno') return ctx.docNo || '(결재 후 채번)';
    return '';
  }

  function buildHmSelects(hId, mId, reqAttr) {
    var h = '<select class="eap-h" data-eap-id="' + esc(hId) + '"' + reqAttr + '>';
    for (var i = 0; i < 24; i++) {
      var v = (i < 10 ? '0' : '') + i;
      h += '<option value="' + v + '">' + v + '</option>';
    }
    h += '</select><span class="eap-u">시</span>';
    h += '<select class="eap-m" data-eap-id="' + esc(mId) + '"' + reqAttr + '>';
    for (var j = 0; j < 60; j++) {
      var mv = (j < 10 ? '0' : '') + j;
      h += '<option value="' + mv + '">' + mv + '</option>';
    }
    h += '</select><span class="eap-u">분</span>';
    return h;
  }

  function widgetInTableCell(row) {
    return !!(row.closest && row.closest('td, th'));
  }

  function cellInputClass(row) {
    return widgetInTableCell(row) ? ' class="eap-in-cell"' : '';
  }

  function isPercentWidth(w) {
    return !!(w && String(w).indexOf('%') >= 0);
  }

  function widgetWidthStyle(row) {
    var w = row.getAttribute('data-eap-width') || '';
    if (!w && widgetInTableCell(row) && row.getAttribute('data-eap-inline') !== '0') w = '10em';
    if (!w) return '';
    if (isPercentWidth(w) && widgetInTableCell(row)) return '';
    return ' style="width:' + esc(w) + ';max-width:100%"';
  }

  function widgetFillControls(row) {
    return row.querySelectorAll(
      'input.eap-in-cell, textarea.eap-in-cell, select.eap-in-cell, '
      + 'input.eap-w-text-inp, input.eap-w-amt-inp, input.eap-w-date, '
      + '.eap-w-face select, .eap-w-checks input'
    );
  }

  /** 셀·문단 안에 위젯 밖 텍스트가 있으면 — "할맥 [입력] 점 폐점" 같은 인라인 흐름 */
  function widgetInInlineTextFlow(widget) {
    if (!widget) return false;
    var cell = widget.closest('td, th');
    var host = cell || widget.parentElement;
    if (!host) return false;

    function hasSiblingText(parent, skipEl) {
      for (var i = 0; i < parent.childNodes.length; i++) {
        var n = parent.childNodes[i];
        if (n === skipEl || (skipEl && skipEl.contains && skipEl.contains(n))) continue;
        if (n.nodeType === 3 && String(n.textContent || '').replace(/\u00a0/g, ' ').trim()) return true;
        if (n.nodeType !== 1) continue;
        var tag = (n.tagName || '').toUpperCase();
        if (tag === 'BR') continue;
        if (tag === 'P' || tag === 'DIV' || tag === 'SPAN') {
          if (n.contains(widget)) {
            if (hasSiblingText(n, widget)) return true;
            continue;
          }
        }
        if (String(n.textContent || '').replace(/\u00a0/g, ' ').trim()) return true;
      }
      return false;
    }

    return hasSiblingText(host, widget);
  }

  function activateWidgetFace(row) {
    var id = row.getAttribute('data-eap-id') || '';
    var type = row.getAttribute('data-eap-type') || '';
    row.querySelectorAll('.eap-w-del').forEach(function (el) { el.remove(); });

    if (type.indexOf('auto_') === 0) {
      row.querySelectorAll('.eap-w-face input').forEach(function (inp) {
        inp.readOnly = true;
        inp.value = autoValue(type);
        if (id) inp.setAttribute('data-eap-id', id);
      });
      return;
    }

    if (type === 'checkbox' || type === 'radio') {
      var checks = row.querySelector('.eap-w-checks');
      if (checks && id) checks.setAttribute('data-eap-id', id);
      row.querySelectorAll('.eap-w-check-item').forEach(function (item) {
        var inp = item.querySelector('input');
        var lbl = item.querySelector('.eap-w-check-lbl');
        if (!inp) return;
        inp.removeAttribute('disabled');
        if (lbl && lbl.textContent) inp.value = lbl.textContent.trim();
        if (type === 'radio' && id) inp.name = 'r_' + id;
      });
      return;
    }

    if (type === 'select') {
      var sel = row.querySelector('.eap-w-face select, select.eap-w-select-el');
      if (sel) {
        sel.removeAttribute('disabled');
        if (id) sel.setAttribute('data-eap-id', id);
        sel.classList.add('eap-trigger');
      }
      return;
    }

    row.querySelectorAll('.eap-w-face input, .eap-w-face textarea').forEach(function (inp) {
      inp.removeAttribute('disabled');
      if (id) inp.setAttribute('data-eap-id', id);
      if (type === 'number') inp.classList.add('eap-number');
      if (type === 'amount') inp.classList.add('eap-amount', 'eap-sum-src');
    });
  }

  /** 미리보기와 동일 DOM(eap-w-face) 유지 — buildInput 치환은 레거시·복합 타입만 */
  function activateWidgetRow(row) {
    if (row.classList.contains('eap-approval-line')) return;
    var type = row.getAttribute('data-eap-type') || '';
    var useBuildInput = type === 'user' || type === 'dept' || type === 'sum_display'
      || type === 'period' || type === 'time' || type === 'multiline' || type === 'richtext';
    var val = fieldContainer(row);

    if (!val && row.classList.contains('eap-widget')) {
      if (!useBuildInput && row.querySelector('.eap-w-face-wrap')) {
        activateWidgetFace(row);
      } else {
        row.innerHTML = buildInput(row);
      }
      applyFillWidgetLayout(row);
      return;
    }

    if (val) {
      if (!useBuildInput && row.querySelector('.eap-w-face-wrap')) {
        activateWidgetFace(row);
      } else {
        val.innerHTML = buildInput(row);
      }
    }
    if (row.classList.contains('eap-widget')) applyFillWidgetLayout(row);
  }

  function applyFillWidgetLayout(row) {
    if (!row || !row.classList.contains('eap-widget')) return;
    var w = row.getAttribute('data-eap-width') || '';
    var type = row.getAttribute('data-eap-type') || '';
    var cell = row.closest('td, th');
    var merged = false;
    if (cell) {
      var cs = parseInt(cell.getAttribute('colspan') || '1', 10) || 1;
      var rs = parseInt(cell.getAttribute('rowspan') || '1', 10) || 1;
      merged = cs > 1 || rs > 1;
    }
    var isChecks = type === 'checkbox' || type === 'radio';
    var inlineFlow = widgetInInlineTextFlow(row);
    var soleInCell = cell && !inlineFlow && !merged && !isChecks;

    var inputs = widgetFillControls(row);
    var checks = row.querySelector('.eap-checks, .eap-w-checks');
    var faceWrap = row.querySelector('.eap-w-face-wrap');

    row.style.minWidth = '';
    row.style.minHeight = '';

    if (isChecks && (merged || (w && isPercentWidth(w)))) {
      row.removeAttribute('data-eap-inline');
      row.style.display = 'block';
      row.style.width = w || '100%';
      row.style.maxWidth = '100%';
      row.style.margin = '0';
      if (checks) {
        checks.style.width = w || '100%';
        checks.style.maxWidth = '100%';
      }
      return;
    }

    if (soleInCell || (!inlineFlow && w && isPercentWidth(w) && cell)) {
      row.removeAttribute('data-eap-inline');
      row.style.display = 'block';
      row.style.width = w || '100%';
      row.style.maxWidth = '100%';
      row.style.margin = '0';
      row.style.verticalAlign = '';
      if (faceWrap) {
        faceWrap.style.display = 'block';
        faceWrap.style.width = '100%';
        faceWrap.style.maxWidth = '100%';
      }
      inputs.forEach(function (inp) {
        inp.style.width = '100%';
        inp.style.maxWidth = '100%';
        inp.style.boxSizing = 'border-box';
      });
      return;
    }

    if (inlineFlow || row.getAttribute('data-eap-inline') === '1'
      || (cell && !merged && !isChecks && row.getAttribute('data-eap-inline') !== '0')) {
      row.setAttribute('data-eap-inline', '1');
      row.style.display = 'inline-block';
      row.style.verticalAlign = 'baseline';
      row.style.margin = '0 2px';
      row.style.boxSizing = 'border-box';
      row.style.maxWidth = '100%';
      var effW = w || '10em';
      row.style.width = effW;
      if (faceWrap) {
        faceWrap.style.display = 'block';
        faceWrap.style.width = '100%';
        faceWrap.style.maxWidth = '100%';
        faceWrap.style.boxSizing = 'border-box';
      }
      var face = row.querySelector('.eap-w-face');
      if (face) {
        face.style.width = '100%';
        face.style.maxWidth = '100%';
        face.style.boxSizing = 'border-box';
      }
      inputs.forEach(function (inp) {
        inp.style.width = '100%';
        inp.style.maxWidth = '100%';
        inp.style.boxSizing = 'border-box';
        inp.style.display = 'block';
      });
      return;
    }

    row.style.display = '';
    row.style.width = w || '';
    row.style.maxWidth = w ? '100%' : '';
    row.style.margin = '';
    inputs.forEach(function (inp) {
      if (w) {
        inp.style.width = '100%';
        inp.style.maxWidth = '100%';
      } else {
        inp.style.width = '';
        inp.style.maxWidth = '';
      }
      inp.style.boxSizing = 'border-box';
    });
  }

  function checksWrapStyle(row) {
    var parts = [];
    var scale = parseFloat(row.getAttribute('data-eap-check-scale') || '100');
    if (scale > 0 && scale !== 100) {
      parts.push('--eap-check-scale:' + (scale / 100));
    }
    var w = row.getAttribute('data-eap-width') || '';
    var cell = row.closest('td, th');
    if (cell) {
      var cs = parseInt(cell.getAttribute('colspan') || '1', 10) || 1;
      if (cs > 1 && !w) w = '100%';
    }
    if (w) parts.push('width:' + w, 'max-width:100%');
    return parts.length ? ' style="' + parts.join(';') + '"' : '';
  }

  function buildInput(row) {
    var type = row.getAttribute('data-eap-type') || 'text';
    var id = row.getAttribute('data-eap-id') || '';
    var ph = row.getAttribute('data-eap-placeholder') || '';
    var req = row.getAttribute('data-eap-required') === '1';
    var sumG = row.getAttribute('data-eap-sum-group') || '';
    var opts = (row.getAttribute('data-eap-options') || '').replace(/\\n/g, '\n').split('\n').filter(Boolean);
    var reqAttr = req ? ' data-eap-required="1"' : '';
    var sumAttr = sumG ? ' data-eap-sum-group="' + esc(sumG) + '"' : '';
    var inCell = widgetInTableCell(row);
    var cellCls = cellInputClass(row);
    var widthStyle = widgetWidthStyle(row);
    var cellAmtCls = inCell ? ' class="eap-amount eap-sum-src eap-in-cell"' : ' class="eap-amount eap-sum-src"';
    var cellNumCls = inCell ? ' class="eap-number eap-sum-src eap-in-cell"' : ' class="eap-number eap-sum-src"';
    var cellNumOnlyCls = inCell ? ' class="eap-number eap-in-cell"' : ' class="eap-number"';

    if (type.indexOf('auto_') === 0) {
      return '<input type="text"' + cellCls + ' data-eap-id="' + esc(id) + '" readonly value="' + esc(autoValue(type)) + '"/>';
    }
    if (type === 'user' || type === 'dept') {
      return '<div class="eap-picker-row">'
        + '<input type="text" data-eap-id="' + esc(id) + '" data-eap-pick="' + type + '" placeholder="' + esc(ph) + '" readonly' + reqAttr + '/>'
        + '<button type="button" class="eap-pick-btn" data-pick="' + type + '" data-target="' + esc(id) + '">선택</button></div>';
    }
    if (type === 'multiline' || type === 'richtext') {
      return '<textarea' + cellCls + widthStyle + ' data-eap-id="' + esc(id) + '" placeholder="' + esc(ph) + '"' + reqAttr + '></textarea>';
    }
    if (type === 'number') {
      var numCls = sumG ? cellNumCls : cellNumOnlyCls;
      return '<input type="number"' + numCls + widthStyle + ' data-eap-id="' + esc(id) + '" placeholder="' + esc(ph) + '"' + reqAttr + sumAttr + '/>';
    }
    if (type === 'amount') {
      return '<input type="number"' + cellAmtCls + widthStyle + ' data-eap-id="' + esc(id) + '" placeholder="' + esc(ph) + '" step="1"' + reqAttr + sumAttr + '/>';
    }
    if (type === 'sum_display') {
      var sg = sumG || row.getAttribute('data-eap-sum-group') || '';
      return '<span class="eap-sum-display" data-sum-group="' + esc(sg) + '">0</span>';
    }
    if (type === 'date') {
      return '<input type="date"' + cellCls + widthStyle + ' data-eap-id="' + esc(id) + '"' + reqAttr + '/>';
    }
    if (type === 'time') {
      return '<span class="eap-time">' + buildHmSelects(id + '_h', id + '_m', reqAttr) + '</span>';
    }
    if (type === 'period') {
      return '<div class="eap-period eap-period-dt">'
        + buildHmSelects(id + '_from_h', id + '_from_m', reqAttr)
        + '<input type="date" data-eap-id="' + esc(id) + '_from_d"' + reqAttr + '/>'
        + '<span class="eap-w-tilde">~</span>'
        + buildHmSelects(id + '_to_h', id + '_to_m', reqAttr)
        + '<input type="date" data-eap-id="' + esc(id) + '_to_d"' + reqAttr + '/>'
        + '</div>';
    }
    if (type === 'select') {
      var defaultVal = row.getAttribute('data-eap-default') || '';
      var selCls = inCell ? ' class="eap-trigger eap-in-cell"' : ' class="eap-trigger"';
      var h = '<select data-eap-id="' + esc(id) + '"' + selCls + widthStyle + reqAttr;
      var dsl = row.getAttribute('data-eap-dsl') || '';
      if (dsl) h += ' data-eap-dsl="' + esc(dsl) + '"';
      h += '>';
      if (!defaultVal) h += '<option value="">선택</option>';
      opts.forEach(function (o) {
        var selected = (defaultVal && o === defaultVal) ? ' selected' : '';
        h += '<option value="' + esc(o) + '"' + selected + '>' + esc(o) + '</option>';
      });
      return h + '</select>';
    }
    if (type === 'radio') {
      var wrapStyle = checksWrapStyle(row);
      var r = '<div class="eap-checks eap-trigger" data-eap-id="' + esc(id) + '"' + wrapStyle + '>';
      opts.forEach(function (o) {
        r += '<label class="eap-check-item"><input type="radio" name="r_' + esc(id) + '" value="' + esc(o) + '"/><span class="eap-check-lbl">' + esc(o) + '</span></label>';
      });
      return r + '</div>';
    }
    if (type === 'checkbox') {
      var wrapStyle2 = checksWrapStyle(row);
      var c = '<div class="eap-checks" data-eap-id="' + esc(id) + '"' + wrapStyle2 + '>';
      opts.forEach(function (o) {
        c += '<label class="eap-check-item"><input type="checkbox" value="' + esc(o) + '"/><span class="eap-check-lbl">' + esc(o) + '</span></label>';
      });
      return c + '</div>';
    }
    return '<input type="text"' + cellCls + widthStyle + ' data-eap-id="' + esc(id) + '" placeholder="' + esc(ph) + '"' + reqAttr + '/>';
  }

  function fieldContainer(row) {
    return row.classList.contains('eap-grid-field') ? row : row.querySelector('.eap-val');
  }

  function fieldValueById(id) {
    var row = page.querySelector('.eap-field[data-eap-id="' + id + '"], .eap-grid-field[data-eap-id="' + id + '"], .eap-widget[data-eap-id="' + id + '"]');
    if (!row) return '';
    var type = row.getAttribute('data-eap-type') || '';
    var val = fieldContainer(row);
    if (!val) {
      if (row.classList.contains('eap-widget')) val = row;
      else return '';
    }
    if (type === 'period') return readValue(val.querySelector('.eap-period, .eap-period-dt, .eap-w-period') || val);
    if (type === 'time') return readValue(val.querySelector('.eap-time, .eap-w-time') || val);
    if (['radio', 'checkbox'].indexOf(type) >= 0) return readValue(val.querySelector('.eap-checks, .eap-w-checks') || val);
    var inp = val.querySelector('input,select,textarea');
    return readValue(inp);
  }

  function applyConditionalVisibility() {
    page.querySelectorAll('.eap-field, .eap-widget[data-eap-type]').forEach(function (row) {
      var sf = row.getAttribute('data-eap-show-field');
      var sv = row.getAttribute('data-eap-show-value');
      if (!sf) {
        row.style.display = '';
        return;
      }
      var cur = fieldValueById(sf);
      row.style.display = (cur === sv) ? '' : 'none';
    });
  }

  function recalcSumGroups() {
    var groups = {};
    page.querySelectorAll('input.eap-amount[data-eap-sum-group], input.eap-number[data-eap-sum-group]').forEach(function (inp) {
      var g = inp.getAttribute('data-eap-sum-group');
      if (!g) return;
      if (!groups[g]) groups[g] = 0;
      groups[g] += parseFloat(inp.value) || 0;
    });
    Object.keys(groups).forEach(function (g) {
      page.querySelectorAll('.eap-sum-display[data-sum-group="' + g + '"]').forEach(function (el) {
        el.textContent = groups[g].toLocaleString('ko-KR');
      });
    });
  }

  function activateTemplate(html) {
    page.innerHTML = html || '';
    var isNative = window.eapIsNativeEditorHtml
      ? window.eapIsNativeEditorHtml(page)
      : !!page.querySelector('.eap-widget[data-eap-type], .eap-doc-header, table.eap-form-table');
    if (window.eapMigrateDaouHtml) window.eapMigrateDaouHtml(page);
    // 다우/Word 붙여넣기 HTML 만 import 후처리를 한 번 더 — 네이티브 양식은 건너뛴다.
    if (!isNative && window.eapPrepareImportedHtmlForEdit) {
      window.eapPrepareImportedHtmlForEdit(page);
    }
    if (window.eapSanitizeFormHtml) window.eapSanitizeFormHtml(page, { preserveTableLayout: true });
    if (window.eapInitFormFillLayout) window.eapInitFormFillLayout({ root: page });
    else if (window.eapPrepareFormFillTables) window.eapPrepareFormFillTables(page);
    page.querySelectorAll('.eap-field, .eap-grid-field, .eap-widget[data-eap-type]').forEach(function (row) {
      activateWidgetRow(row);
    });
    page.querySelectorAll('.eap-richtext').forEach(function (rt) {
      rt.contentEditable = 'true';
    });
    page.addEventListener('input', function (e) {
      if (e.target.classList.contains('eap-amount') || e.target.classList.contains('eap-number')) recalcSumGroups();
      if (e.target.classList.contains('eap-trigger') || e.target.closest('.eap-trigger')) {
        applyConditionalVisibility();
      }
    });
    page.addEventListener('change', function () {
      recalcSumGroups();
      applyConditionalVisibility();
    });
    page.addEventListener('click', function (e) {
      var btn = e.target.closest('.eap-pick-btn');
      if (!btn) return;
      pickTargetId = btn.getAttribute('data-target');
      var pick = btn.getAttribute('data-pick');
      parent.postMessage(JSON.stringify({ type: 'eapPickField', pick: pick, fieldId: pickTargetId }), '*');
    });
    applyConditionalVisibility();
    recalcSumGroups();
    if (window.eapPrepareFormFillTables) window.eapPrepareFormFillTables(page);
    else if (window.eapFixDocTables) window.eapFixDocTables(page);
    delete page._eapMileageCalcBound;
    if (window.eapRunFormRuntime) window.eapRunFormRuntime(page);
  }

  window.eapFillBuildInput = buildInput;
  window.eapFillApplyWidgetLayout = applyFillWidgetLayout;
  window.eapFillActivateWidgetRow = activateWidgetRow;

  function readValue(el) {
    if (!el) return '';
    if (el.classList.contains('eap-time') || el.classList.contains('eap-w-time')) {
      var th = el.querySelector('.eap-h, .eap-w-h');
      var tm = el.querySelector('.eap-m, .eap-w-m');
      return (th ? th.value : '00') + ':' + (tm ? tm.value : '00');
    }
    if (el.tagName === 'TEXTAREA' || (el.tagName === 'INPUT' && el.type !== 'radio' && el.type !== 'checkbox')) {
      return el.value.trim();
    }
    if (el.classList.contains('eap-checks') || el.classList.contains('eap-w-checks')) {
      if (el.querySelector('input[type=radio]')) {
        var chk = el.querySelector('input[type=radio]:checked');
        return chk ? chk.value : '';
      }
      return Array.prototype.map.call(el.querySelectorAll('input[type=checkbox]:checked'), function (c) {
        return c.value;
      }).join(', ');
    }
    if (el.classList.contains('eap-period-dt')) {
      function part(prefix) {
        var h = el.querySelector('[data-eap-id$="' + prefix + '_h"]');
        var m = el.querySelector('[data-eap-id$="' + prefix + '_m"]');
        var d = el.querySelector('[data-eap-id$="' + prefix + '_d"]');
        var ds = d ? d.value : '';
        var ts = (h && m) ? (h.value + ':' + m.value) : '';
        if (ds && ts) return ds + ' ' + ts;
        return ds || ts;
      }
      return part('_from') + ' ~ ' + part('_to');
    }
    if (el.classList.contains('eap-period')) {
      var a = el.querySelector('input[data-eap-id$=_from]');
      var b = el.querySelector('input[data-eap-id$=_to]');
      return (a ? a.value : '') + ' ~ ' + (b ? b.value : '');
    }
    if (el.tagName === 'SELECT') {
      var opt = el.options[el.selectedIndex];
      if (window.eapIsPlaceholderSelectOption && window.eapIsPlaceholderSelectOption(opt)) return '';
      return (opt ? (opt.textContent || opt.value || '') : el.value || '').trim();
    }
    return el.innerText.trim();
  }

  function readControlText(el) {
    if (!el) return '';
    if (window.eapReadControlValue) return window.eapReadControlValue(el);
    return readValue(el);
  }

  function validateRequired() {
    var errors = [];
    page.querySelectorAll('.eap-field, .eap-grid-field, .eap-widget[data-eap-type]').forEach(function (row) {
      if (row.style.display === 'none') return;
      if (row.getAttribute('data-eap-required') !== '1') return;
      var label = row.getAttribute('data-eap-label') || '항목';
      var type = row.getAttribute('data-eap-type') || '';
      if (type.indexOf('auto_') === 0 || type === 'sum_display') return;
      var val = fieldContainer(row);
      if (!val && row.classList.contains('eap-widget')) val = row;
      // 값 컨테이너(.eap-val)가 없는 항목이 있다 — 다우/Word 에서 가져온 예전 서식이
      // 대표적이다. 예전에는 그대로 val.querySelector(...) 를 불러 TypeError 가 났고,
      // 그 예외가 message 핸들러 안에서 터지는 바람에 **검증 결과 자체가 회신되지
      // 않았다.** Dart 쪽은 3초 뒤 타임아웃으로 "통과"로 처리했으므로,
      // **필수 항목을 비워 둔 채 상신이 그냥 됐다.**
      // 입력칸이 없는 항목은 검사 대상이 아니므로 건너뛴다.
      if (!val) return;
      var text = '';
      if (type === 'sum_display') text = readValue(val.querySelector('.eap-sum-display') || val);
      else if (type === 'period') text = readValue(val.querySelector('.eap-period, .eap-period-dt, .eap-w-period') || val);
      else if (type === 'time') text = readValue(val.querySelector('.eap-time, .eap-w-time') || val);
      else if (['radio', 'checkbox'].indexOf(type) >= 0) text = readValue(val.querySelector('.eap-checks, .eap-w-checks') || val);
      else {
        var inp = val.querySelector('input,select,textarea');
        text = readValue(inp);
      }
      if (!text || text === ' ~ ' || text === '00:00 ~ 00:00') errors.push(label);
    });
    return errors;
  }

  function exportWidgetText(row) {
    var type = row.getAttribute('data-eap-type') || '';
    var val = fieldContainer(row);
    if (!val && row.classList.contains('eap-widget')) val = row;
    if (!val) return '';
    var text = '';
    if (type === 'sum_display') text = readControlText(val.querySelector('.eap-sum-display') || val);
    else if (type === 'period') text = readControlText(val.querySelector('.eap-period, .eap-period-dt, .eap-w-period') || val);
    else if (type === 'time') text = readControlText(val.querySelector('.eap-time, .eap-w-time') || val);
    else if (['radio', 'checkbox'].indexOf(type) >= 0) text = readControlText(val.querySelector('.eap-checks, .eap-w-checks') || val);
    else {
      var inp = val.querySelector('input,select,textarea');
      text = readControlText(inp);
    }
    if (type.indexOf('auto_') === 0) text = autoValue(type);
    return text;
  }

  function findExportCloneRow(clone, id, liveRow) {
    if (id) {
      return clone.querySelector(
        '.eap-field[data-eap-id="' + id + '"], .eap-grid-field[data-eap-id="' + id + '"], .eap-widget[data-eap-id="' + id + '"]'
      );
    }
    return liveRow;
  }

  function exportHtml() {
    if (window.eapFormRuntimeRecalc) window.eapFormRuntimeRecalc(page);
    if (window.eapSyncSelectState) window.eapSyncSelectState(page);
    var clone = page.cloneNode(true);
    page.querySelectorAll('.eap-field, .eap-grid-field, .eap-widget[data-eap-type]').forEach(function (liveRow) {
      var id = liveRow.getAttribute('data-eap-id') || '';
      var cloneRow = findExportCloneRow(clone, id, liveRow);
      if (!cloneRow) return;
      var text = exportWidgetText(liveRow);
      if (cloneRow.classList.contains('eap-widget')) {
        cloneRow.innerHTML = '<span>' + esc(text || ' ') + '</span>';
        return;
      }
      var val = fieldContainer(cloneRow);
      if (val) val.innerHTML = '<span>' + esc(text || ' ') + '</span>';
    });
    clone.querySelectorAll('.eap-richtext').forEach(function (rt) {
      rt.removeAttribute('contenteditable');
    });
    clone.querySelectorAll('.eap-pick-btn').forEach(function (b) { b.remove(); });
    if (window.eapFlattenFormControls) window.eapFlattenFormControls(clone);
    if (window.eapFixDocTables) window.eapFixDocTables(clone);
    return clone.innerHTML;
  }

  function wheelDeltaY(e) {
    var dy = e.deltaY;
    if (e.deltaMode === 1) dy *= 16;
    else if (e.deltaMode === 2) dy *= (document.getElementById('stage').clientHeight || 400);
    return dy;
  }

  document.addEventListener('wheel', function (e) {
    var stage = document.getElementById('stage');
    var dy = wheelDeltaY(e);
    if (!dy) return;
    e.preventDefault();
    var maxScroll = Math.max(0, stage.scrollHeight - stage.clientHeight);
    var before = stage.scrollTop;
    if (maxScroll > 0) stage.scrollTop = Math.max(0, Math.min(maxScroll, before + dy));
    // iframe 내부 스크롤만 사용 — 부모 Flutter 스크롤로 넘기지 않음
  }, { passive: false });

  window.addEventListener('message', function (e) {
    var d = e.data;
    if (typeof d === 'string') { try { d = JSON.parse(d); } catch (err) { return; } }
    d = d || {};
    if (d.type === 'eapSetContext') {
      ctx = d.context || {};
      page.querySelectorAll('.eap-field input[readonly], .eap-grid-field input[readonly], .eap-widget[data-eap-auto="1"] input[readonly]').forEach(function (inp) {
        var row = inp.closest('.eap-field, .eap-grid-field, .eap-widget');
        if (row && (row.getAttribute('data-eap-type') || '').indexOf('auto_') === 0) {
          inp.value = autoValue(row.getAttribute('data-eap-type'));
        }
      });
    }
    if (d.type === 'eapSetHtml') activateTemplate(d.html || '');
    if (d.type === 'eapPickResult') {
      var inp = page.querySelector('[data-eap-id="' + d.fieldId + '"]');
      if (inp) inp.value = d.value || '';
    }
    if (d.type === 'eapGetHtml') {
      parent.postMessage(JSON.stringify({ type: 'eapHtml', id: d.id, html: exportHtml() }), '*');
    }
    if (d.type === 'eapValidate') {
      // 검증 도중 무슨 일이 나더라도 **반드시 회신한다.**
      // 회신이 없으면 Dart 쪽이 타임아웃으로 처리하는데, 검증에서의 무응답을
      // "통과"로 보면 필수 항목이 빈 문서가 그대로 상신된다. 실패로 회신한다.
      var errors;
      try {
        errors = validateRequired();
      } catch (err) {
        errors = ['본문 검증 중 오류가 발생했습니다'];
      }
      parent.postMessage(JSON.stringify({
        type: 'eapValidateResult',
        id: d.id,
        ok: errors.length === 0,
        errors: errors
      }), '*');
    }
  });
})();
