/* 양식 동작 스크립트 — 행 추가/삭제, 자가차량운행 자동계산 등 */
(function (g) {
  function numVal(el) {
    if (!el) return 0;
    var v = parseFloat(String(el.value || el.textContent || '').replace(/[^0-9.-]/g, ''));
    return isNaN(v) ? 0 : v;
  }

  function readSelectValue(sel) {
    if (!sel || sel.tagName !== 'SELECT') return '';
    var opt = sel.options[sel.selectedIndex];
    if (g.eapIsPlaceholderSelectOption && g.eapIsPlaceholderSelectOption(opt)) return '';
    return (opt ? (opt.textContent || opt.value || '') : sel.value || '').trim();
  }

  function pickControlInCell(cell) {
    if (!cell) return null;
    if (cell.matches && cell.matches('input, select, textarea')) return cell;
    return cell.querySelector('.eap-widget select, .eap-widget input, .eap-widget textarea, select, input, textarea');
  }

  function cellIndex(cell) {
    var row = cell && cell.parentNode;
    if (!row || !row.children) return -1;
    return Array.prototype.indexOf.call(row.children, cell);
  }

  function findControlByLabel(table, labelText) {
    if (!table) return null;
    var matches = [];
    table.querySelectorAll('td, th').forEach(function (cell) {
      var plain = String(cell.textContent || '').replace(/\s+/g, '');
      if (plain.indexOf(labelText) < 0) return;
      matches.push({ cell: cell, row: cell.parentNode, colIdx: cellIndex(cell) });
    });
    if (!matches.length) return null;

    matches.sort(function (a, b) {
      var al = String(a.cell.textContent || '').replace(/\s+/g, '').length;
      var bl = String(b.cell.textContent || '').replace(/\s+/g, '').length;
      return al - bl;
    });
    var hit = matches[0];

    var inline = pickControlInCell(hit.cell.nextElementSibling);
    if (inline) return inline;

    var colIdx = hit.colIdx;
    if (colIdx < 0) return null;

    var rows = Array.prototype.slice.call(table.querySelectorAll('tr'));
    var labelRowIdx = rows.indexOf(hit.row);
    for (var ri = labelRowIdx + 1; ri < rows.length; ri++) {
      var tr = rows[ri];
      if (colIdx >= tr.children.length) continue;
      var ctrl = pickControlInCell(tr.children[colIdx]);
      if (ctrl) return ctrl;
    }
    for (var rj = 0; rj < rows.length; rj++) {
      if (rows[rj] === hit.row) continue;
      if (colIdx >= rows[rj].children.length) continue;
      var alt = pickControlInCell(rows[rj].children[colIdx]);
      if (alt) return alt;
    }
    return null;
  }

  function setControlValue(el, text) {
    if (!el) return;
    var next = text == null ? '' : String(text);
    if (el.tagName === 'SELECT') {
      for (var i = 0; i < el.options.length; i++) {
        var o = el.options[i];
        if (g.eapIsPlaceholderSelectOption && g.eapIsPlaceholderSelectOption(o)) continue;
        if (o.value === next || String(o.textContent || '').trim() === next) {
          if (el.selectedIndex !== i) el.selectedIndex = i;
          return;
        }
      }
      if (el.value !== next) el.value = next;
      return;
    }
    if (el.value === next) return;
    el.value = next;
  }

  /** 유종·연비·운행거리가 포함된 표 — 중첩 표는 바깥 표 우선 */
  function findMileageScope(root) {
    if (!root || !root.querySelectorAll) return null;
    var best = null;
    var bestScore = 0;
    root.querySelectorAll('table').forEach(function (t) {
      if (t.classList.contains('eap-approval-line')) return;
      var txt = String(t.textContent || '');
      var score = 0;
      if (txt.indexOf('유종') >= 0) score += 3;
      if (txt.indexOf('연비') >= 0) score += 3;
      if (txt.indexOf('운행거리') >= 0 || txt.indexOf('사용량') >= 0) score += 1;
      if (t.id === 'dynamic_table1' || (t.id && t.id.indexOf('dynamic') >= 0)) score += 2;
      if (t.querySelector('tr.copyRow1, tr[class*="copyRow"]')) score += 2;
      if (score > bestScore) {
        bestScore = score;
        best = t;
      }
    });
    if (!best) return null;
    var outer = best;
    while (outer.parentElement) {
      var parentTable = outer.parentElement.closest('table');
      if (!parentTable || parentTable.classList.contains('eap-approval-line')) break;
      var ptxt = String(parentTable.textContent || '');
      if (ptxt.indexOf('유종') >= 0 && ptxt.indexOf('연비') >= 0) outer = parentTable;
      else break;
    }
    return outer;
  }

  /**
   * 행 추가/삭제 버튼을 찾는 CSS 선택자를 안전하게 만든다.
   *
   * 예전에는 표 id 와 버튼 id 를 문자열로 그냥 이어 붙였다. 그런데 이 id 들은
   * 다우오피스·Word 에서 가져온 문서의 값을 **그대로** 쓰기 때문에 숫자로 시작하거나
   * 점·공백·콜론이 섞이는 일이 흔하다. 그러면 querySelectorAll 이
   * `SyntaxError: '...' is not a valid selector` 를 던지고, 그 예외가
   * eapRunFormRuntime 밖으로 빠져나가 **행 추가/삭제 기능 전체가 죽는다.**
   * (빈 id 일 때는 선택자가 `..., #` 로 끝나 무조건 예외였다.)
   */
  function eapRowToolSelector(kind, tableId, btnId) {
    var parts = ['.eap-row-' + kind + '[data-eap-table="' + String(tableId || '').replace(/"/g, '\\"') + '"]'];
    var id = String(btnId || '').trim();
    if (id) {
      parts.push('#' + (g.CSS && g.CSS.escape ? g.CSS.escape(id) : id));
    }
    return parts.join(', ');
  }

  function ensureMileageRules(cfg, root) {
    cfg = cfg || { version: 1, rules: [] };
    if (!cfg.rules) cfg.rules = [];
    var has = false;
    cfg.rules.forEach(function (r) { if (r.type === 'vehicleMileageCalc') has = true; });
    // 근거가 확실할 때만 규칙을 붙인다. mileageScope 의 id 기반 후보(#dynamic_table1 등)
    // 는 다우 양식에서만 나오고, findMileageScope 는 유종·연비 표기를 실제로 확인한다.
    if (!has && (mileageScope(root) || findMileageScope(root))) {
      cfg.rules.push({ type: 'vehicleMileageCalc', tableId: 'dynamic_table1' });
    }
    return cfg;
  }

  function clearRowInputs(row) {
    row.querySelectorAll('input, select, textarea').forEach(function (inp) {
      if (inp.tagName === 'SELECT') inp.selectedIndex = 0;
      else inp.value = '';
    });
    row.querySelectorAll('.eap-widget').forEach(function (w) {
      w.removeAttribute('data-value');
    });
  }

  function rewireRowFields(row, tableId, rowIndex) {
    var n = 0;
    row.querySelectorAll('[data-eap-id]').forEach(function (el) {
      n += 1;
      el.setAttribute('data-eap-id', tableId + '_r' + rowIndex + '_f' + n);
    });
  }

  function activateClonedRow(row) {
    row.querySelectorAll('.eap-widget[data-eap-type]').forEach(function (w) {
      if (w.querySelector('input, select, textarea')) return;
      if (g.eapFillActivateWidgetRow) g.eapFillActivateWidgetRow(w);
      else if (g.eapFillBuildInput) {
        w.innerHTML = g.eapFillBuildInput(w);
        if (g.eapFillApplyWidgetLayout) g.eapFillApplyWidgetLayout(w);
      }
    });
  }

  function refitDocTables(root) {
    var target = root;
    if (root && root.id !== 'page' && root.id !== 'editor') {
      target = root.querySelector('#page') || root.querySelector('#editor') || root;
    }
    if (target && g.eapFixDocTables) g.eapFixDocTables(target);
  }

  function plusMinusRow(cfg, root) {
    var table = root.querySelector('#' + cfg.tableId) || root.querySelector('table[id="' + cfg.tableId + '"]');
    if (!table) return;
    var copyClass = cfg.copyRowClass || 'copyRow1';
    var template = table.querySelector('tr.' + copyClass);
    if (!template) return;

    function cloneCount() {
      return table.querySelectorAll('tr.copiedRow').length;
    }

    function plus() {
      var max = cfg.maxRow || 0;
      var total = table.querySelectorAll('tr.' + copyClass + ', tr.copiedRow').length;
      if (max > 0 && total >= max) return;
      var clone = template.cloneNode(true);
      clone.classList.remove(copyClass);
      clone.classList.add('copiedRow');
      clearRowInputs(clone);
      rewireRowFields(clone, cfg.tableId, cloneCount() + 1);
      activateClonedRow(clone);
      var last = table.querySelector('tr.copiedRow:last-of-type') || template;
      last.parentNode.insertBefore(clone, last.nextSibling);
      refitDocTables(root);
      if (g.eapFormRuntimeRecalc) g.eapFormRuntimeRecalc(root);
    }

    function minus() {
      var rows = table.querySelectorAll('tr.copiedRow');
      if (!rows.length) return;
      var copyLen = table.querySelectorAll('tr.' + copyClass).length;
      for (var i = 0; i < copyLen; i++) {
        var last = table.querySelector('tr.copiedRow:last-of-type');
        if (last) last.remove();
      }
      refitDocTables(root);
      if (g.eapFormRuntimeRecalc) g.eapFormRuntimeRecalc(root);
    }

    root.querySelectorAll(eapRowToolSelector('plus', cfg.tableId, cfg.plusBtnId)).forEach(function (btn) {
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        plus();
      });
    });
    root.querySelectorAll(eapRowToolSelector('minus', cfg.tableId, cfg.minusBtnId)).forEach(function (btn) {
      btn.addEventListener('click', function (e) {
        e.preventDefault();
        minus();
      });
    });
  }

  /** 다우 `#dynamic_table1`(tbody) 또는 유종·연비가 있는 표 */
  function mileageScope(root) {
    if (!root || !root.querySelector) return null;
    var tbody = root.querySelector('#dynamic_table1');
    if (tbody) return tbody;
    // 아래 후보들은 **자가차량운행 표라는 근거가 있을 때만** 쓴다.
    // 예전에는 마지막 후보가 `root.querySelector('table')`, 즉 **문서의 아무 표나**
    // 였다. findMileageScope 는 일반 서식에서 항상 null 을 돌려주므로 그 폴백이
    // 늘 걸렸고, 그 결과 서식을 열기만 해도 마일리지 계산기가 붙어 recalc() 가
    // 표 셀을 덮어썼다(합계 옆 칸을 "0" 으로, 마지막 행 마지막 칸을 textContent
    // 대입으로 비워 그 안의 위젯까지 통째로 삭제). 저장하면 그대로 반영됐다.
    return findMileageScope(root)
      || root.querySelector('tbody[id*="dynamic"]')
      || root.querySelector('table[id*="dynamic"]');
  }

  function widgetOptions(el) {
    var w = el && el.closest ? el.closest('.eap-widget') : null;
    if (!w) return '';
    return (w.getAttribute('data-eap-options') || '').replace(/\\n/g, '\n');
  }

  function findSelectByDsl(scope, needle) {
    if (!scope) return null;
    var found = null;
    scope.querySelectorAll('.eap-widget[data-eap-type="select"], select[data-eap-dsl]').forEach(function (el) {
      if (found) return;
      var dsl = el.getAttribute('data-eap-dsl')
        || (el.closest('.eap-widget') && el.closest('.eap-widget').getAttribute('data-eap-dsl'))
        || '';
      if (dsl.indexOf(needle) >= 0) {
        found = el.tagName === 'SELECT' ? el : el.querySelector('select');
      }
    });
    return found;
  }

  function findFuelAndEfficiencyControls(scope) {
    if (!scope) return { fuelSel: null, effCtrl: null };

    var fuelSel = findSelectByDsl(scope, '휘발유');
    var effCtrl = findSelectByDsl(scope, '9_11');

    if (!fuelSel) {
      scope.querySelectorAll('select').forEach(function (s) {
        if (fuelSel) return;
        var opts = widgetOptions(s);
        if (opts.indexOf('휘발유') >= 0 && opts.indexOf('경유') >= 0) fuelSel = s;
      });
    }
    if (!effCtrl) {
      scope.querySelectorAll('select').forEach(function (s) {
        if (effCtrl || s === fuelSel) return;
        var opts = widgetOptions(s);
        if (opts === '9\n11' || opts === '11\n9' || (opts.indexOf('9') >= 0 && opts.indexOf('11') >= 0)) {
          effCtrl = s;
        }
      });
    }

    // rowspan 으로 헤더·데이터 열이 어긋날 때 — 마지막 데이터 행의 select 2개
    if (!fuelSel || !effCtrl) {
      var rows = scope.querySelectorAll('tr');
      for (var ri = rows.length - 1; ri >= 0; ri--) {
        var sels = rows[ri].querySelectorAll('select');
        if (sels.length >= 2) {
          if (!fuelSel) fuelSel = sels[0];
          if (!effCtrl) effCtrl = sels[1];
          break;
        }
      }
    }
    if (!fuelSel) fuelSel = scope.querySelector('select.editor_slt, select');
    return { fuelSel: fuelSel, effCtrl: effCtrl };
  }

  function vehicleMileageCalc(cfg, root) {
    if (!root) return;
    if (root._eapMileageCalcBound) return;
    root._eapMileageCalcBound = true;

    var recalcLock = false;

    function scopeEl() {
      return mileageScope(root);
    }

    function recalc() {
      if (recalcLock) return;
      recalcLock = true;
      try {
        var scope = scopeEl();
        if (!scope) return;

        var total = 0;
        scope.querySelectorAll('tr.copyRow1, tr.copiedRow, tr[class*="copyRow"]').forEach(function (row) {
          var distInput = row.querySelector('input.eap-amount, input.eap-number, input.ipt_editor_currency');
          if (!distInput) {
            var inputs = row.querySelectorAll('input[type=text], input[type=number]');
            if (inputs.length >= 3) distInput = inputs[2];
          }
          if (distInput) total += numVal(distInput);
        });

        var totalTd = null;
        scope.querySelectorAll('td, th').forEach(function (td) {
          if ((td.textContent || '').replace(/\s+/g, '').indexOf('합계') >= 0) {
            totalTd = td.nextElementSibling;
          }
        });
        if (totalTd) {
          var totalText = total.toLocaleString('ko-KR');
          var p = totalTd.querySelector('p');
          if (p) {
            if (p.textContent !== totalText) p.textContent = totalText;
          } else if (totalTd.textContent !== totalText) {
            totalTd.textContent = totalText;
          }
        }

        var ctrls = findFuelAndEfficiencyControls(scope);
        if (ctrls.fuelSel && !readSelectValue(ctrls.fuelSel) && g.eapWidgetDefaultValue) {
          var fuelDef = g.eapWidgetDefaultValue(ctrls.fuelSel);
          if (fuelDef) setControlValue(ctrls.fuelSel, fuelDef);
        }
        var fuel = ctrls.fuelSel ? readSelectValue(ctrls.fuelSel) : '';
        var efficiency = fuel.indexOf('경유') >= 0 ? 11 : 9;
        if (ctrls.effCtrl) setControlValue(ctrls.effCtrl, String(efficiency));

        var usage = efficiency > 0 ? total / efficiency : 0;
        var bottomInputs = scope.querySelector('tr:last-child') ?
          Array.prototype.slice.call(scope.querySelectorAll('tr:last-child input')) : [];
        if (bottomInputs.length < 2) {
          bottomInputs = Array.prototype.slice.call(scope.querySelectorAll('tr:last-child input'));
        }
        var usageInput = bottomInputs[0];
        var priceInput = bottomInputs[1];
        setControlValue(
          usageInput,
          usage > 0 ? (Math.round(usage * 100) / 100).toLocaleString('ko-KR') : '0'
        );

        var amount = Math.round(usage * numVal(priceInput));
        var amountText = amount > 0 ? amount.toLocaleString('ko-KR') : '';
        var amountTd = scope.querySelector('tr:last-child td:last-child');
        if (amountTd) {
          var ap = amountTd.querySelector('p');
          if (ap) {
            if (ap.textContent !== amountText) ap.textContent = amountText;
          } else if (pickControlInCell(amountTd)) {
            setControlValue(pickControlInCell(amountTd), amountText);
          } else if (amountTd.textContent !== amountText) {
            amountTd.textContent = amountText;
          }
        }
      } finally {
        recalcLock = false;
      }
    }

    function onFormChange(e) {
      var t = e.target;
      if (!t || !t.tagName) return;
      var tag = t.tagName.toUpperCase();
      if (tag === 'SELECT' || tag === 'INPUT' || tag === 'TEXTAREA') recalc();
    }

    root.addEventListener('input', onFormChange, false);
    root.addEventListener('change', onFormChange, false);
    recalc();
    g.eapFormRuntimeRecalc = function (r) {
      if (!r || r === root) recalc();
    };
  }

  function eapRunFormRuntime(root) {
    if (!root) return;
    var cfg = g.eapReadFormScriptConfig ? g.eapReadFormScriptConfig(root) : null;
    if (!cfg || !cfg.rules) {
      cfg = { version: 1, rules: [] };
      if (root.querySelector('.eap-row-plus, #plus1, #dynamic_table1')) {
        cfg.rules.push({
          type: 'plusMinusRow',
          tableId: 'dynamic_table1',
          plusBtnId: 'plus1',
          minusBtnId: 'minus1',
          copyRowClass: 'copyRow1'
        });
      }
    }
    cfg = ensureMileageRules(cfg, root);
    if (!cfg.rules.length) return;
    cfg.rules.forEach(function (rule) {
      if (rule.type === 'plusMinusRow') plusMinusRow(rule, root);
      if (rule.type === 'vehicleMileageCalc') vehicleMileageCalc(rule, root);
    });
    refitDocTables(root);
  }

  g.eapRunFormRuntime = eapRunFormRuntime;
  g.eapFindMileageScope = findMileageScope;
  g.eapMileageScope = mileageScope;
})(typeof window !== 'undefined' ? window : this);
