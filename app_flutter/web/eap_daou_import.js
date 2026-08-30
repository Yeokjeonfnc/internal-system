/* 다우오피스 양식 HTML → EAP 필드/스크립트 설정 변환 */
(function (g) {
  var uid = 0;

  function nextId(prefix) {
    uid += 1;
    return (prefix || 'daou') + '_' + uid;
  }

  function bumpUidFrom(id) {
    if (!id) return;
    var n = parseInt(String(id).replace(/\D/g, ''), 10);
    if (!isNaN(n) && n > uid) uid = n;
  }

  function parseDaouDsl(dsl) {
    dsl = String(dsl || '');
    var m = dsl.match(/\{\{([^}]+)\}\}/);
    if (!m) return { type: 'text' };
    var inner = m[1];
    if (inner === 'text') return { type: 'text' };
    if (inner === 'calendar') return { type: 'date' };
    if (inner === 'number') return { type: 'number' };
    if (/^currency/i.test(inner)) return { type: 'amount' };
    if (/^label:/i.test(inner)) {
      var key = inner.slice(6);
      if (key === 'draftDate') return { type: 'auto_date', label: '기안일' };
      if (key === 'draftUser') return { type: 'auto_drafter', label: '기안자' };
      if (key === 'draftDept') return { type: 'auto_dept', label: '기안부서' };
      return { type: 'text', label: key };
    }
    if (/^cSel_/i.test(inner)) {
      var opts = inner.slice(5).split('_').filter(Boolean);
      return { type: 'select', options: opts.join('\\n') };
    }
    if (/^cChk_/i.test(inner)) {
      var chkOpts = inner.slice(5).split('_').filter(Boolean);
      return { type: 'checkbox', options: chkOpts.join('\\n') };
    }
    if (/^text\$/i.test(inner)) {
      return { type: 'text', required: /require/i.test(inner) };
    }
    return { type: 'text' };
  }

  function removeDaouChrome(root) {
    if (!root || !root.querySelectorAll) return;
    root.querySelectorAll('.comp_active, .comp_hover, .ic_prototype, .Active_dot1, .Active_dot2, .Active_dot3, .Active_dot4').forEach(function (el) {
      el.remove();
    });
    root.querySelectorAll('[data-content-protect-cover], [data-component-delete-button]').forEach(function (el) {
      if (el.tagName === 'A') el.remove();
      else el.removeAttribute('data-content-protect-cover');
    });
  }

  function migrateApprovalSign(root) {
    root.querySelectorAll('.sign_type1_inline').forEach(function (sign) {
      var wrap = sign.closest('.comp_wrap') || sign.parentElement;
      var cols = sign.querySelectorAll('.sign_member_wrap').length || 5;
      var table = document.createElement('table');
      table.className = 'eap-widget-block eap-approval-line';
      table.setAttribute('contenteditable', 'false');
      table.setAttribute('data-eap-type', 'approval_line');
      table.setAttribute('data-eap-id', nextId('appr'));
      table.setAttribute('data-eap-cols', String(cols));
      var body = '<tbody><tr><td class="eap-appr-lbl" rowspan="2">결<br>재</td>';
      for (var i = 0; i < cols; i++) body += '<td class="eap-appr-head"></td>';
      body += '</tr><tr>';
      for (var j = 0; j < cols; j++) body += '<td class="eap-appr-sign"></td>';
      body += '</tr></tbody>';
      table.innerHTML = body;
      if (wrap && wrap.classList && wrap.classList.contains('comp_wrap')) {
        wrap.parentNode.replaceChild(table, wrap);
      } else if (sign.parentNode) {
        sign.parentNode.replaceChild(table, sign);
      }
    });
  }

  function migrateCompWraps(root) {
    var wraps = Array.prototype.slice.call(root.querySelectorAll('.comp_wrap[data-dsl], .comp_wrap[data-wrapper]'));
    wraps.forEach(function (wrap) {
      if (!wrap.getAttribute('data-dsl') && wrap.querySelector('.comp_item')) {
        wrap.setAttribute('data-dsl', '{{label:text}}');
      }
      var dsl = wrap.getAttribute('data-dsl') || '';
      var parsed = parseDaouDsl(dsl);
      var cid = wrap.getAttribute('data-cid') || wrap.getAttribute('data-origin') || '';
      bumpUidFrom(cid);

      var sel = wrap.querySelector('select.editor_slt, select');
      if (sel) {
        var opts = [];
        var selected = '';
        sel.querySelectorAll('option').forEach(function (o) {
          var t = (o.textContent || '').trim();
          if (t) opts.push(t);
          if (o.selected || o.hasAttribute('selected')) selected = t;
        });
        if (!selected && sel.selectedIndex >= 0 && sel.options[sel.selectedIndex]) {
          selected = (sel.options[sel.selectedIndex].textContent || '').trim();
        }
        if (opts.length) {
          parsed.type = 'select';
          parsed.options = opts.join('\\n');
          if (selected) parsed.defaultVal = selected;
        }
      } else if (wrap.querySelector('input.ipt_editor_date, input[type=date]')) {
        parsed.type = 'date';
      } else if (wrap.querySelector('input.ipt_editor_currency')) {
        parsed.type = 'amount';
      } else if (wrap.querySelector('input.ipt_editor_num')) {
        parsed.type = 'number';
      } else if (wrap.querySelector('input[type=checkbox]')) {
        var chkOpts = [];
        wrap.querySelectorAll('input[type=checkbox]').forEach(function (cb) {
          var lbl = cb.closest('label');
          var t = lbl ? String(lbl.textContent || '').replace(/\s+/g, ' ').trim() : (cb.value || '').trim();
          if (t) chkOpts.push(t);
        });
        if (chkOpts.length) {
          parsed.type = 'checkbox';
          parsed.options = chkOpts.join('\\n');
        }
      } else if (wrap.querySelector('.comp_item')) {
        var labelText = (wrap.querySelector('.comp_item').textContent || '').trim();
        if (parsed.type === 'auto_date' || parsed.type === 'auto_drafter') {
          parsed.label = labelText || parsed.label;
        } else {
          parsed.type = 'text';
          parsed.label = labelText;
        }
      }

      if (wrap.querySelector('input.ipt_editor') && parsed.type === 'text' && /subject/i.test(dsl)) {
        parsed.required = true;
      }

      var widget = document.createElement('span');
      widget.className = 'eap-widget';
      widget.setAttribute('contenteditable', 'false');
      widget.setAttribute('data-eap-id', cid ? 'daou_' + cid : nextId('w'));
      widget.setAttribute('data-eap-type', parsed.type);
      if (parsed.required) widget.setAttribute('data-eap-required', '1');
      if (parsed.options) widget.setAttribute('data-eap-options', parsed.options);
      if (parsed.defaultVal) widget.setAttribute('data-eap-default', parsed.defaultVal);
      if (dsl) widget.setAttribute('data-eap-dsl', dsl);
      if (wrap.closest && wrap.closest('td, th')) widget.setAttribute('data-eap-inline', '1');
      if (parsed.label) widget.setAttribute('data-eap-label', parsed.label);
      if (parsed.type.indexOf('auto_') === 0) widget.setAttribute('data-eap-auto', '1');

      if (wrap.parentNode) wrap.parentNode.replaceChild(widget, wrap);
    });
  }

  function tagRowTools(root) {
    root.querySelectorAll('tr.viewModeHiddenPart, tr').forEach(function (tr) {
      var plus = tr.querySelector('#plus1, .button#plus1, a#plus1, button#plus1, a.button#plus1');
      var minus = tr.querySelector('#minus1, .button#minus1, a#minus1, button#minus1, a.button#minus1');
      if (!plus || !minus) return;
      tr.classList.add('eap-row-tools');
      var table = tr.closest('table');
      var tableId = table && table.id ? table.id : 'dynamic_table1';
      if (table && !table.id) table.id = tableId;
      plus.classList.add('eap-row-plus');
      minus.classList.add('eap-row-minus');
      plus.setAttribute('data-eap-table', tableId);
      minus.setAttribute('data-eap-table', tableId);
      plus.setAttribute('type', 'button');
      minus.setAttribute('type', 'button');
      var copyRow = table && table.querySelector('tr.copyRow1, tr[class*="copyRow"]');
      if (copyRow) {
        var cls = copyRow.className.match(/copyRow\w+/);
        if (cls) tr.setAttribute('data-eap-copy-row-class', cls[0]);
      }
    });
  }

  function extractScriptConfig(scriptText) {
    scriptText = String(scriptText || '');
    var rules = [];
    var re = /PlusMinusRow\s*\(\s*\{([\s\S]*?)\}\s*\)/g;
    var m;
    while ((m = re.exec(scriptText)) !== null) {
      var block = m[1];
      function pick(key) {
        var rx = new RegExp(key + '\\s*:\\s*["\']([^"\']+)["\']');
        var hit = block.match(rx);
        return hit ? hit[1] : '';
      }
      rules.push({
        type: 'plusMinusRow',
        tableId: pick('tableId') || 'dynamic_table1',
        plusBtnId: pick('plusBtnId') || 'plus1',
        minusBtnId: pick('minusBtnId') || 'minus1',
        copyRowClass: pick('copyRowClass') || 'copyRow1',
        copyRowNoClass: pick('copyRowNoClass') || '',
        maxRow: parseInt(pick('maxRow'), 10) || 0
      });
    }
    if (/calculateAll|dynamic_table1|ipt_editor_currency/i.test(scriptText)) {
      rules.push({ type: 'vehicleMileageCalc', tableId: 'dynamic_table1' });
    }
    return rules.length ? { version: 1, rules: rules } : null;
  }

  function extractScripts(root) {
    if (!root || !root.querySelectorAll) return null;
    var chunks = [];
    root.querySelectorAll('script').forEach(function (s) {
      if (s.getAttribute('type') === 'application/eap-form') return;
      var t = s.textContent || '';
      if (t.trim()) chunks.push(t);
      s.remove();
    });
    if (!chunks.length) return null;
    return extractScriptConfig(chunks.join('\n'));
  }

  function storeScriptConfig(root, cfg) {
    if (!cfg || !root) return;
    var old = root.querySelector('script[type="application/eap-form"]');
    if (old) old.remove();
    var holder = document.createElement('script');
    holder.type = 'application/eap-form';
    holder.textContent = JSON.stringify(cfg);
    root.appendChild(holder);
  }

  function readScriptConfig(root) {
    var s = root && root.querySelector('script[type="application/eap-form"]');
    if (!s) return null;
    try { return JSON.parse(s.textContent || '{}'); } catch (e) { return null; }
  }

  /** 자체 양식 편집기가 만든 HTML — Word/다우 import 용 칸 편집 처리를 하면 안 된다. */
  function eapIsNativeEditorHtml(root) {
    if (!root || !root.querySelector) return false;
    if (root.querySelector('.eap-doc-header, .eap-doc-body')) return true;
    if (root.querySelector('.eap-widget[data-eap-type], .eap-field[data-eap-type], .eap-grid-field[data-eap-type]')) {
      return true;
    }
    if (root.querySelector('table.eap-form-table, table.eap-product-table, table.eap-compact-table')) return true;
    return false;
  }

  function eapMigrateDaouHtml(root) {
    if (!root) return;
    removeDaouChrome(root);
    migrateApprovalSign(root);
    migrateCompWraps(root);
    tagRowTools(root);
    var cfg = extractScripts(root);
    if (cfg) storeScriptConfig(root, cfg);
    // 기안 입력·미리보기는 편집기와 다른 파이프라인이다. import 용 prepare 는
    // 모든 td/th 를 contentEditable 로 바꾸고 colgroup 을 강제로 넣는데,
    // 네이티브 양식(eap-form-table·eap-widget)에까지 적용하면 표·위젯 배치가
    // 미리보기와 달라져 기안 화면에서 칸·글자가 비어 보이는 경우가 있다.
    if (!eapIsNativeEditorHtml(root) && window.eapPrepareImportedHtmlForEdit) {
      window.eapPrepareImportedHtmlForEdit(root);
    }
  }

  g.eapMigrateDaouHtml = eapMigrateDaouHtml;
  g.eapIsNativeEditorHtml = eapIsNativeEditorHtml;
  g.eapExtractFormScriptConfig = extractScriptConfig;
  g.eapReadFormScriptConfig = readScriptConfig;
})(typeof window !== 'undefined' ? window : this);
