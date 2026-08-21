/* 전자결재 문서 — 붙여넣은 Word/HWP 표는 칸을 다시 나누지 않는다.
   짧은 칸이 세로로 쌓이지 않게 하고, 화면보다 넓으면 통째로 축소한다. */
(function (g) {
  var SKIP = '.eap-widget, .eap-approval-line, .eap-w-face, .eap-product-toolbar';

  function skip(el) {
    return !el || (el.closest && el.closest(SKIP));
  }

  function cellText(cell) {
    return String(cell.innerText || '')
      .replace(/\s+/g, ' ')
      .trim();
  }

  function ownCells(table) {
    var out = [];
    table.querySelectorAll('td, th').forEach(function (cell) {
      if (cell.closest('table') === table) out.push(cell);
    });
    return out;
  }

  function ownCols(table) {
    var out = [];
    table.querySelectorAll('col').forEach(function (col) {
      if (col.closest('table') === table) out.push(col);
    });
    return out;
  }

  function fitImage(img) {
    if (!img || skip(img)) return;
    img.style.maxWidth = '100%';
    img.style.height = 'auto';
    img.removeAttribute('height');
  }

  function stripFixedCellWidths(cell) {
    if (!cell || skip(cell)) return;
    var attr = cell.getAttribute('width');
    if (attr && /^\d+(\.\d+)?$/.test(String(attr).trim()) && parseFloat(attr) > 80) {
      cell.removeAttribute('width');
    }
    if (!cell.style) return;
    var sw = String(cell.style.width || '');
    if (/^\d+(\.\d+)?px$/i.test(sw)) cell.style.width = '';
    if (/^\d+(\.\d+)?px$/i.test(String(cell.style.minWidth || ''))) cell.style.minWidth = '';
  }

  function restoreCell(cell) {
    if (!cell || skip(cell)) return;
    stripFixedCellWidths(cell);
    cell.removeAttribute('nowrap');
    if (!cell.style) return;
    cell.style.overflowWrap = 'normal';
    cell.style.wordBreak = 'keep-all';
    cell.style.wordWrap = 'normal';
    cell.style.minWidth = '';
    if (cell.style.maxWidth === '100%') cell.style.maxWidth = '';
    var t = cellText(cell);
    if (t && t.length <= 28) {
      cell.style.whiteSpace = 'nowrap';
    } else if (/nowrap/i.test(cell.style.whiteSpace || '')) {
      cell.style.whiteSpace = 'normal';
    }
  }

  function cellSpan(cell) {
    return {
      cs: Math.max(1, parseInt(cell.getAttribute('colspan') || '1', 10) || 1),
      rs: Math.max(1, parseInt(cell.getAttribute('rowspan') || '1', 10) || 1)
    };
  }

  function buildTableGrid(table) {
    var trs = table.rows;
    var grid = [];
    var maxCols = 0;
    for (var r = 0; r < trs.length; r++) {
      if (!grid[r]) grid[r] = [];
      var col = 0;
      var cells = trs[r].cells;
      for (var i = 0; i < cells.length; i++) {
        while (grid[r][col]) col++;
        var cell = cells[i];
        var sp = cellSpan(cell);
        for (var rr = 0; rr < sp.rs; rr++) {
          if (r + rr >= trs.length) break;
          if (!grid[r + rr]) grid[r + rr] = [];
          for (var cc = 0; cc < sp.cs; cc++) grid[r + rr][col + cc] = cell;
        }
        col += sp.cs;
      }
      if (grid[r].length > maxCols) maxCols = grid[r].length;
    }
    return { grid: grid, rows: trs.length, cols: maxCols, trs: trs };
  }

  function cellOriginInGrid(g, cell) {
    for (var r = 0; r < g.rows; r++) {
      for (var c = 0; c < g.cols; c++) {
        if (g.grid[r][c] === cell) return { r: r, c: c };
      }
    }
    return null;
  }

  function cellHasContent(cell) {
    if (!cell) return false;
    return !!String(cell.innerText || '').replace(/\u00a0/g, ' ').replace(/\s+/g, ' ').trim();
  }

  function gridColumnUsed(g, col) {
    for (var r = 0; r < g.rows; r++) {
      var cell = g.grid[r][col];
      if (cell && cellHasContent(cell)) return true;
    }
    return false;
  }

  function gridRowUsed(g, row) {
    for (var c = 0; c < g.cols; c++) {
      var cell = g.grid[row][c];
      if (cell && cellHasContent(cell)) return true;
    }
    return false;
  }

  function deleteGridColumn(table, colIdx) {
    var g = buildTableGrid(table);
    if (colIdx < 0 || colIdx >= g.cols) return false;
    var seen = [];
    for (var r = 0; r < g.rows; r++) {
      var cell = g.grid[r][colIdx];
      if (!cell || seen.indexOf(cell) >= 0) continue;
      seen.push(cell);
      var o = cellOriginInGrid(g, cell);
      if (!o) continue;
      var sp = cellSpan(cell);
      if (o.c === colIdx) {
        if (sp.cs <= 1) cell.remove();
        else if (sp.cs === 2) cell.removeAttribute('colspan');
        else cell.setAttribute('colspan', String(sp.cs - 1));
      } else if (o.c < colIdx && o.c + sp.cs > colIdx) {
        if (sp.cs === 2) cell.removeAttribute('colspan');
        else cell.setAttribute('colspan', String(sp.cs - 1));
      }
    }
    var cg = table.querySelector('colgroup');
    if (cg && cg.children[colIdx]) cg.removeChild(cg.children[colIdx]);
    return true;
  }

  function deleteGridRow(table, rowIdx) {
    var g = buildTableGrid(table);
    if (rowIdx < 0 || rowIdx >= g.rows) return false;
    var seen = [];
    for (var c = 0; c < g.cols; c++) {
      var cell = g.grid[rowIdx][c];
      if (!cell || seen.indexOf(cell) >= 0) continue;
      seen.push(cell);
      var o = cellOriginInGrid(g, cell);
      if (!o) continue;
      var sp = cellSpan(cell);
      if (o.r === rowIdx) {
        if (sp.rs <= 1) cell.remove();
        else if (sp.rs === 2) cell.removeAttribute('rowspan');
        else cell.setAttribute('rowspan', String(sp.rs - 1));
      } else if (o.r < rowIdx && o.r + sp.rs > rowIdx) {
        if (sp.rs === 2) cell.removeAttribute('rowspan');
        else cell.setAttribute('rowspan', String(sp.rs - 1));
      }
    }
    var tr = g.trs[rowIdx];
    if (tr && tr.parentNode) tr.parentNode.removeChild(tr);
    return true;
  }

  function trimExcelTableGrid(table) {
    var guard = 0;
    var g = buildTableGrid(table);
    while (guard++ < 300 && g.cols > 1) {
      var removed = false;
      for (var c = g.cols - 1; c >= 0; c--) {
        if (!gridColumnUsed(g, c)) {
          deleteGridColumn(table, c);
          removed = true;
          break;
        }
      }
      if (!removed) break;
      g = buildTableGrid(table);
    }
    guard = 0;
    g = buildTableGrid(table);
    while (guard++ < 300 && g.rows > 1) {
      var removedR = false;
      for (var r = g.rows - 1; r >= 0; r--) {
        if (!gridRowUsed(g, r)) {
          deleteGridRow(table, r);
          removedR = true;
          break;
        }
      }
      if (!removedR) break;
      g = buildTableGrid(table);
    }
  }

  function clearExcelCellInners(cell) {
    cell.querySelectorAll('*').forEach(function (el) {
      if (!el.style) return;
      el.style.whiteSpace = '';
      el.style.width = '';
      el.style.minWidth = '';
      el.style.maxWidth = '';
      el.removeAttribute('nowrap');
    });
  }

  function measureCellMinWidth(cell) {
    if (!cell || !cell.ownerDocument) return 0;
    var doc = cell.ownerDocument;
    var win = doc.defaultView;
    if (!win) return 0;
    var text = cellText(cell);
    if (!text) return 20;
    var probe = doc.createElement('span');
    probe.style.cssText = 'position:absolute;left:-9999px;top:0;visibility:hidden;white-space:nowrap;padding:0;margin:0;';
    var cs = win.getComputedStyle(cell);
    probe.style.font = cs.font;
    probe.style.fontSize = cs.fontSize;
    probe.style.fontFamily = cs.fontFamily;
    probe.style.letterSpacing = cs.letterSpacing;
    probe.textContent = text;
    doc.body.appendChild(probe);
    var w = (probe.offsetWidth || 0) + 10;
    doc.body.removeChild(probe);
    return Math.max(20, w);
  }

  function applyExcelTablePxWidths(table, colPx) {
    if (!table || !colPx || !colPx.length) return 0;
    var cg = table.querySelector('colgroup');
    if (!cg) return 0;
    var cols = [];
    cg.querySelectorAll('col').forEach(function (col) {
      if (col.closest('table') === table) cols.push(col);
    });
    if (cols.length !== colPx.length) return 0;
    var total = colPx.reduce(function (a, b) { return a + (b || 0); }, 0);
    if (!(total > 0)) return 0;
    cols.forEach(function (col, i) {
      col.style.width = Math.max(20, Math.round(colPx[i] || 0)) + 'px';
    });
    table.style.tableLayout = 'fixed';
    table.style.width = total + 'px';
    table.style.minWidth = total + 'px';
    table.style.maxWidth = 'none';
    return total;
  }

  function ensureExcelColumnsFitContent(table) {
    var g = buildTableGrid(table);
    if (!g.cols) return 0;
    var cg = table.querySelector('colgroup');
    if (!cg) return 0;
    var cols = [];
    cg.querySelectorAll('col').forEach(function (col) {
      if (col.closest('table') === table) cols.push(col);
    });
    if (cols.length !== g.cols) return 0;

    var excelPx = cols.map(parseColPx);
    var contentPx = [];
    for (var c = 0; c < g.cols; c++) contentPx[c] = 0;

    var seen = [];
    for (var r = 0; r < g.rows; r++) {
      for (var c = 0; c < g.cols; c++) {
        var cell = g.grid[r][c];
        if (!cell || seen.indexOf(cell) >= 0) continue;
        var o = cellOriginInGrid(g, cell);
        if (!o) continue;
        seen.push(cell);
        var sp = cellSpan(cell);
        var need = measureCellMinWidth(cell);
        var perCol = need / sp.cs;
        for (var dc = 0; dc < sp.cs; dc++) {
          var ci = o.c + dc;
          if (contentPx[ci] < perCol) contentPx[ci] = perCol;
        }
      }
    }

    var merged = [];
    for (var i = 0; i < g.cols; i++) {
      merged[i] = Math.max(excelPx[i] || 0, contentPx[i] || 0, 20);
    }
    return applyExcelTablePxWidths(table, merged);
  }

  function relaxExcelCellWidths(table) {
    ownCells(table).forEach(function (cell) {
      if (!cell.style) return;
      clearExcelCellInners(cell);
      cell.removeAttribute('nowrap');
      cell.removeAttribute('width');
      cell.removeAttribute('data-eap-wrap');
      cell.removeAttribute('data-eap-nowrap');
      cell.style.width = '';
      cell.style.minWidth = '';
      cell.style.maxWidth = '';
      cell.style.whiteSpace = '';
      cell.style.wordBreak = '';
      cell.style.overflowWrap = '';
    });
  }

  function msoBorderToCss(val) {
    if (!val || /none/i.test(val)) return '';
    return String(val)
      .replace(/windowtext/gi, '#000')
      .replace(/black/gi, '#000')
      .replace(/(\d*\.?\d+)pt/gi, function (_, n) {
        return Math.max(1, Math.round(parseFloat(n) * 1.333)) + 'px';
      })
      .trim();
  }

  function parseMsoBorderCss(css) {
    var map = {};
    String(css || '').replace(/\.(xl[\w-]+)\s*\{([^}]+)\}/gi, function (_, cls, body) {
      var borders = {};
      var sides = ['top', 'right', 'bottom', 'left'];
      sides.forEach(function (side) {
        var m = body.match(new RegExp('border-' + side + '\\s*:\\s*([^;\\}]+)', 'i'));
        if (m) {
          var cv = msoBorderToCss(m[1]);
          if (cv) borders[side] = cv;
        }
      });
      var mAll = body.match(/(?:^|[;\s])border\s*:\s*([^;\}]+)/i);
      if (mAll) {
        var all = msoBorderToCss(mAll[1]);
        if (all) sides.forEach(function (s) { if (!borders[s]) borders[s] = all; });
      }
      if (Object.keys(borders).length) map[cls.toLowerCase()] = borders;
      return '';
    });
    return map;
  }

  function parseInlineBorderSides(styleText) {
    var borders = {};
    var sides = ['top', 'right', 'bottom', 'left'];
    sides.forEach(function (side) {
      var m = String(styleText || '').match(new RegExp('border-' + side + '\\s*:\\s*([^;]+)', 'i'));
      if (m) {
        var cv = msoBorderToCss(m[1]);
        if (cv) borders[side] = cv;
      }
    });
    var mAll = String(styleText || '').match(/(?:^|[;\s])border\s*:\s*([^;]+)/i);
    if (mAll) {
      var all = msoBorderToCss(mAll[1]);
      if (all) sides.forEach(function (s) { if (!borders[s]) borders[s] = all; });
    }
    return borders;
  }

  function applyBorderSides(cell, borders) {
    if (!cell || !cell.style || !borders) return;
    ['top', 'right', 'bottom', 'left'].forEach(function (side) {
      if (!borders[side]) return;
      var prop = 'border' + side.charAt(0).toUpperCase() + side.slice(1);
      cell.style[prop] = borders[side];
    });
  }

  function ptToPx(val) {
    var n = parseFloat(val);
    if (!(n > 0)) return 0;
    return Math.round(n * 1.333);
  }

  function parseColPx(col) {
    var style = col.getAttribute('style') || '';
    var m = style.match(/width:\s*([\d.]+)pt/i);
    if (m) return ptToPx(m[1]);
    var attr = col.getAttribute('width');
    if (attr && /^\d+(\.\d+)?$/.test(String(attr).trim())) return parseInt(attr, 10) || 0;
    m = style.match(/width:\s*([\d.]+)px/i);
    if (m) return Math.round(parseFloat(m[1]));
    return 0;
  }

  function preserveExcelColWidths(table) {
    var cols = [];
    table.querySelectorAll('colgroup > col').forEach(function (col) {
      if (col.closest('table') === table) cols.push(col);
    });
    if (!cols.length) return 0;
    var widths = cols.map(parseColPx);
    var total = widths.reduce(function (a, b) { return a + (b || 0); }, 0);
    if (!(total > 0)) return 0;
    return applyExcelTablePxWidths(table, widths);
  }

  function preserveExcelCellMetrics(cell) {
    if (!cell || !cell.style) return;
    var st = cell.getAttribute('style') || '';
    var hm = st.match(/height:\s*([\d.]+)pt/i);
    if (hm) cell.style.height = ptToPx(hm[1]) + 'px';
    cell.style.width = '';
    cell.removeAttribute('width');
  }

  function inlineExcelCellBorders(table, borderMap) {
    ownCells(table).forEach(function (cell) {
      if (skip(cell)) return;
      var merged = parseInlineBorderSides(cell.getAttribute('style') || '');
      String(cell.className || '').split(/\s+/).forEach(function (cls) {
        var b = borderMap[cls.toLowerCase()];
        if (b) {
          ['top', 'right', 'bottom', 'left'].forEach(function (side) {
            if (b[side]) merged[side] = b[side];
          });
        }
      });
      applyBorderSides(cell, merged);
      preserveExcelCellMetrics(cell);
    });
  }

  function flattenExcelAbsoluteTables(root) {
    root.querySelectorAll('table').forEach(function (t) {
      if (/absolute/i.test((t.style && t.style.position) || '')) {
        t.style.position = 'static';
        t.style.left = '';
        t.style.top = '';
        t.style.marginLeft = '';
        t.style.marginTop = '';
        t.style.zIndex = '';
      }
    });
    root.querySelectorAll('div, span').forEach(function (el) {
      if (el.tagName === 'TABLE' || (el.querySelector && el.querySelector('table'))) return;
      if (/absolute/i.test((el.style && el.style.position) || '')) {
        if (!String(el.textContent || '').replace(/\s+/g, '').length && !el.querySelector('img')) {
          el.remove();
        } else {
          el.style.position = 'static';
          el.style.left = '';
          el.style.top = '';
        }
      }
    });
  }

  /** Excel 붙여넣기 — MSO 테두리·열 너비를 inline 으로 고정해 선이 떠 보이지 않게 */
  function normalizeExcelPaste(root, cssText) {
    if (!root || !root.querySelectorAll) return;
    var borderMap = parseMsoBorderCss(cssText || '');
    root.querySelectorAll('style').forEach(function (s) {
      var extra = parseMsoBorderCss(s.textContent || '');
      Object.keys(extra).forEach(function (k) { borderMap[k] = extra[k]; });
    });
    root.querySelectorAll('table').forEach(function (t) {
      if (t.classList.contains('eap-approval-line')) return;
      t.classList.add('eap-excel-import');
      t.classList.add('eap-editable-table');
      t.style.borderCollapse = 'collapse';
      t.removeAttribute('border');
      t.removeAttribute('cellspacing');
      t.setAttribute('cellpadding', '0');
      inlineExcelCellBorders(t, borderMap);
      trimExcelTableGrid(t);
      preserveExcelColWidths(t);
      ensureExcelColumnsFitContent(t);
      relaxExcelCellWidths(t);
    });
    flattenExcelAbsoluteTables(root);
  }

  function isExcelClipboardHtml(raw) {
    raw = String(raw || '');
    return /xmlns:x="urn:schemas-microsoft-com:office:excel"/i.test(raw)
      || /Microsoft Excel/i.test(raw)
      || /mso-number-format/i.test(raw)
      || /mso-width-source/i.test(raw)
      || /mso-border-alt/i.test(raw)
      || /\bclass=["']?xl[\d-]/i.test(raw);
  }

  function fitTable(t) {
    if (!t || t.classList.contains('eap-approval-line')) return;
    if (t.classList.contains('eap-excel-import')) {
      t.style.boxSizing = 'border-box';
      t.style.borderCollapse = 'collapse';
      t.style.tableLayout = 'fixed';
      preserveExcelColWidths(t);
      ensureExcelColumnsFitContent(t);
      relaxExcelCellWidths(t);
      return;
    }
    var nested = !!(t.parentElement && t.parentElement.closest('table'));
    var cols = ownCols(t);
    t.style.boxSizing = 'border-box';
    t.style.height = '';
    t.style.minWidth = '';
    if (t.classList.contains('eap-tsv')) {
      t.style.tableLayout = 'fixed';
      t.style.width = '100%';
      t.style.maxWidth = '100%';
      return;
    }
    if (t.getAttribute('data-eap-col-lock') === '1' || cols.length > 0) {
      t.style.tableLayout = 'fixed';
      if (nested) {
        t.style.width = 'auto';
        t.style.maxWidth = '100%';
      } else {
        t.style.width = '100%';
        t.style.maxWidth = '100%';
      }
      ownCells(t).forEach(restoreCell);
      return;
    }
    t.style.tableLayout = 'auto';
    if (nested) {
      t.style.width = 'auto';
      t.style.maxWidth = '100%';
    } else {
      t.style.width = 'auto';
      t.style.minWidth = '100%';
      t.style.maxWidth = 'none';
    }
    ownCols(t).forEach(function (col) {
      var raw = col.style.width || col.getAttribute('width') || '';
      var n = parseFloat(raw);
      if (/%$/.test(String(raw)) && n > 0 && n < 4) {
        col.style.width = '';
        col.removeAttribute('width');
      }
    });
    ownCells(t).forEach(restoreCell);
  }

  function sanitizePasteCss(css) {
    css = String(css || '');
    css = css.replace(/@page[^{]*\{[\s\S]*?\}/gi, '');
    css = css.replace(/@font-face[^{]*\{[\s\S]*?\}/gi, '');
    return css;
  }

  function contentBoxWidth(el) {
    if (!el) return 0;
    var cs = window.getComputedStyle(el);
    var padL = parseFloat(cs.paddingLeft) || 0;
    var padR = parseFloat(cs.paddingRight) || 0;
    return Math.max(0, (el.clientWidth || el.offsetWidth || 0) - padL - padR);
  }

  function measureContentWidth(root) {
    var need = 0;
    root.querySelectorAll('table').forEach(function (t) {
      if (t.classList.contains('eap-approval-line')) return;
      need = Math.max(need, t.scrollWidth || 0, t.offsetWidth || 0);
    });
    if (!need) {
      var cs = window.getComputedStyle(root);
      var padL = parseFloat(cs.paddingLeft) || 0;
      var padR = parseFloat(cs.paddingRight) || 0;
      need = Math.max(0, (root.scrollWidth || 0) - padL - padR);
    }
    return need;
  }

  function scaleRoot(root) {
    if (!root || !root.style) return;
    root.style.transform = 'none';
    root.style.marginBottom = '';
    root.classList.remove('eap-doc-scaled');
    var avail = contentBoxWidth(root);
    if (avail < 40 && root.parentElement) {
      avail = contentBoxWidth(root.parentElement) - 8;
    }
    if (avail < 40) return;
    var need = measureContentWidth(root);
    if (need <= avail + 2) return;
    var s = Math.max(0.35, avail / need);
    root.style.transformOrigin = 'top center';
    root.style.transform = 'scale(' + s + ')';
    root.classList.add('eap-doc-scaled');
    var h = root.offsetHeight || root.scrollHeight || 0;
    root.style.marginBottom = ((s - 1) * h) + 'px';
  }

  function bindDocScaleResize(root) {
    if (!root || root._eapScaleBound) return;
    root._eapScaleBound = true;
    var timer;
    function refit() {
      clearTimeout(timer);
      timer = setTimeout(function () {
        eapFixDocTables(root, { scale: true });
      }, 80);
    }
    window.addEventListener('resize', refit);
    if (typeof ResizeObserver !== 'undefined') {
      var obs = new ResizeObserver(refit);
      if (root.parentElement) obs.observe(root.parentElement);
      obs.observe(root);
    }
  }

  function tableColCount(table) {
    var max = 0;
    table.querySelectorAll('tr').forEach(function (tr) {
      if (tr.closest('table') !== table) return;
      var n = 0;
      tr.querySelectorAll('td, th').forEach(function (cell) {
        if (cell.closest('table') === table) {
          n += parseInt(cell.getAttribute('colspan') || '1', 10) || 1;
        }
      });
      if (n > max) max = n;
    });
    return max;
  }

  function ensureColGroup(table) {
    var colCount = tableColCount(table);
    if (!colCount) return;
    var cg = table.querySelector('colgroup');
    if (!cg) {
      cg = document.createElement('colgroup');
      table.insertBefore(cg, table.firstChild);
    }
    while (cg.children.length < colCount) cg.appendChild(document.createElement('col'));
    while (cg.children.length > colCount) cg.removeChild(cg.lastChild);
    var pct = (100 / colCount).toFixed(2);
    Array.prototype.forEach.call(cg.children, function (colEl) {
      if (!colEl.style.width) colEl.style.width = pct + '%';
    });
    table.setAttribute('data-eap-col-lock', '1');
  }

  /** 기안 입력 — 편집기와 동일한 표 열 비율 유지 */
  function eapPrepareFormFillTables(root) {
    if (!root || !root.querySelectorAll) return;
    root.querySelectorAll('table').forEach(function (t) {
      if (t.classList.contains('eap-approval-line')) return;
      if (t.classList.contains('eap-excel-import')) {
        t.style.borderCollapse = 'collapse';
        return;
      }
      var nested = !!(t.parentElement && t.parentElement.closest('table'));
      if (nested) return;
      if (!t.querySelector('colgroup') && tableColCount(t) >= 2) ensureColGroup(t);
      t.classList.add('eap-editable-table');
    });
    eapFixDocTables(root);
  }

  function eapFixDocTables(root, opts) {
    if (!root || !root.querySelectorAll) return;
    opts = opts || {};
    root.querySelectorAll('style').forEach(function (s) {
      s.textContent = sanitizePasteCss(s.textContent);
    });
    root.querySelectorAll('img').forEach(fitImage);
    var tables = Array.prototype.slice.call(root.querySelectorAll('table'));
    tables.sort(function (a, b) {
      return b.querySelectorAll('table').length - a.querySelectorAll('table').length;
    });
    tables.forEach(fitTable);
    var hasExcel = !!root.querySelector('table.eap-excel-import');
    if (opts.scale && !hasExcel) {
      scaleRoot(root);
      if (opts.bindResize !== false) bindDocScaleResize(root);
    } else if (hasExcel && root.style) {
      root.style.transform = 'none';
      root.style.marginBottom = '';
      root.classList.remove('eap-doc-scaled');
    }
  }

  /** 기안·미리보기 — 편집기 전용 표 마크업/선택 상태 제거 */
  function sanitizeFormHtml(root, opts) {
    if (!root || !root.querySelectorAll) return;
    opts = opts || {};
    var keepLayout = !!opts.preserveTableLayout;
    root.querySelectorAll('.eap-cell-sel, .eap-cell-on, .eap-drop-cell').forEach(function (el) {
      el.classList.remove('eap-cell-sel', 'eap-cell-on', 'eap-drop-cell');
      if (!el.className) el.removeAttribute('class');
    });
    if (!keepLayout) {
      root.querySelectorAll('table.eap-editable-table').forEach(function (t) {
        if (t.classList.contains('eap-excel-import')) return;
        t.classList.remove('eap-editable-table');
        if (!t.className) t.removeAttribute('class');
      });
      root.querySelectorAll('table[data-eap-col-lock]').forEach(function (t) {
        if (t.classList.contains('eap-excel-import')) return;
        t.removeAttribute('data-eap-col-lock');
        if (t.style) {
          t.style.tableLayout = '';
          t.style.minWidth = '';
        }
      });
      root.querySelectorAll('table:not(.eap-tsv):not(.eap-excel-import) colgroup').forEach(function (cg) {
        cg.remove();
      });
    }
    root.querySelectorAll('table:not(.eap-tsv) td, table:not(.eap-tsv) th').forEach(function (cell) {
      if (skip(cell)) return;
      if (cell.closest && cell.closest('table.eap-excel-import')) return;
      if (!cell.style) return;
      if (/^\d+(\.\d+)?px$/.test(String(cell.style.width || ''))) cell.style.width = '';
      if (/^\d+(\.\d+)?px$/.test(String(cell.style.height || ''))) cell.style.height = '';
    });
  }

  /** Word/HWP·다우 HTML 붙여넣기 — 표 칸 텍스트 편집 가능하도록 */
  function unwrapPastedFormControlsInCells(root) {
    if (!root || !root.querySelectorAll) return;
    root.querySelectorAll('table td, table th').forEach(function (cell) {
      if (skip(cell)) return;
      if (cell.closest('.eap-approval-line')) return;
      if (cell.querySelector('.eap-widget, .eap-widget-block')) return;
      cell.querySelectorAll('input, select, textarea').forEach(function (inp) {
        if (skip(inp)) return;
        var tag = inp.tagName;
        var text = '';
        if (tag === 'SELECT') {
          var opt = inp.options[inp.selectedIndex];
          text = opt ? (opt.textContent || '').trim() : '';
        } else {
          text = (inp.value || inp.getAttribute('value') || inp.getAttribute('placeholder') || '').trim();
        }
        var span = document.createElement('span');
        span.textContent = text || '\u00a0';
        if (inp.parentNode) inp.parentNode.replaceChild(span, inp);
      });
    });
  }

  function prepareImportedHtmlForEdit(root, opts) {
    if (!root || !root.querySelectorAll) return;
    opts = opts || {};
    root.querySelectorAll('[contenteditable="false"]').forEach(function (el) {
      if (skip(el)) return;
      if (el.classList && el.classList.contains('eap-field')) return;
      if (el.matches && el.matches('tr.eap-field, .eap-grid-field, .eap-product-wrap')) return;
      if (el.matches && el.matches('table.eap-approval-line, .eap-product-table, .eap-widget, .eap-widget-block')) return;
      el.removeAttribute('contenteditable');
    });
    root.querySelectorAll('table').forEach(function (t) {
      if (t.classList.contains('eap-approval-line') || t.classList.contains('eap-product-table')) return;
      if (t.querySelector('tr.eap-field')) {
        t.setAttribute('contenteditable', 'false');
        return;
      }
      t.removeAttribute('contenteditable');
      if (!t.classList.contains('eap-editable-table')) t.classList.add('eap-editable-table');
      if (!opts.excelPaste && !t.classList.contains('eap-excel-import')) {
        if (!t.querySelector('colgroup') && tableColCount(t) >= 2) ensureColGroup(t);
      }
      ownCells(t).forEach(function (cell) {
        if (skip(cell)) return;
        if (cell.closest('.eap-approval-line')) return;
        cell.removeAttribute('contenteditable');
        cell.contentEditable = 'true';
      });
    });
    root.querySelectorAll('td, th').forEach(function (cell) {
      if (skip(cell)) return;
      if (cell.closest('.eap-approval-line')) return;
      cell.removeAttribute('contenteditable');
      cell.contentEditable = 'true';
      cell.querySelectorAll('div, p, span').forEach(function (inner) {
        if (skip(inner)) return;
        if (inner.matches && inner.matches('.eap-widget, .eap-widget-block')) return;
        if (inner.getAttribute('contenteditable') === 'false') inner.removeAttribute('contenteditable');
      });
    });
    if (opts.designMode) unwrapPastedFormControlsInCells(root);
    root.querySelectorAll('[unselectable="on"]').forEach(function (el) {
      el.removeAttribute('unselectable');
    });
  }

  function isPlaceholderSelectOption(opt) {
    if (!opt) return true;
    var v = String(opt.value || '').trim();
    var t = String(opt.textContent || opt.text || '').trim();
    if (t === '선택' || t === '선택하세요' || t === '--' || t === '-') return true;
    if (!v && !t) return true;
    return false;
  }

  function widgetDefaultValue(el) {
    if (!el || !el.closest) return '';
    var w = el.closest('.eap-widget[data-eap-default], .eap-field[data-eap-default], .eap-grid-field[data-eap-default]');
    return w ? String(w.getAttribute('data-eap-default') || '').trim() : '';
  }

  /** cloneNode 전에 select 선택 상태를 option attribute 로 고정 */
  function syncSelectState(root) {
    if (!root || !root.querySelectorAll) return;
    root.querySelectorAll('select').forEach(function (sel) {
      var idx = sel.selectedIndex;
      for (var i = 0; i < sel.options.length; i++) {
        if (i === idx) sel.options[i].setAttribute('selected', 'selected');
        else sel.options[i].removeAttribute('selected');
      }
    });
  }

  function readControlValue(el) {
    if (!el) return '';
    var tag = (el.tagName || '').toUpperCase();
    if (tag === 'SELECT') {
      var opt = el.options[el.selectedIndex];
      if (isPlaceholderSelectOption(opt)) {
        var fallback = widgetDefaultValue(el);
        if (fallback) return fallback;
        return '';
      }
      return (opt ? (opt.textContent || opt.text || opt.value) : el.value || '').trim();
    }
    if (tag === 'TEXTAREA') return (el.value || el.textContent || '').trim();
    if (tag === 'INPUT') {
      var type = (el.type || 'text').toLowerCase();
      if (type === 'checkbox' || type === 'radio') {
        return el.checked ? (el.value || '✓').trim() : '';
      }
      return (el.value || '').trim();
    }
    return (el.textContent || '').trim();
  }

  function removeFormActionControls(root) {
    if (!root || !root.querySelectorAll) return;
    root.querySelectorAll(
      'button, input[type="button"], input[type="submit"], input[type="reset"], '
      + '.eap-pick-btn, #plus1, #minus1, .eap-row-plus, .eap-row-minus, '
      + '[data-eap-action], a[onclick]'
    ).forEach(function (el) {
      if (el.closest && el.closest('.eap-approval-line')) return;
      el.remove();
    });
  }

  /** 입력·선택·버튼을 값 텍스트(span)로 바꿔 저장·조회용 정적 HTML 로 만든다. */
  function flattenFormControls(root) {
    if (!root || !root.querySelectorAll) return;
    removeFormActionControls(root);
    var nodes = Array.prototype.slice.call(root.querySelectorAll('input, select, textarea'));
    nodes.forEach(function (el) {
      if (!el.parentNode) return;
      if (el.closest && el.closest('.eap-approval-line')) return;
      var type = (el.type || '').toLowerCase();
      if (type === 'hidden') {
        el.remove();
        return;
      }
      if ((type === 'checkbox' || type === 'radio') && !el.checked) {
        el.remove();
        return;
      }
      var span = (root.ownerDocument || document).createElement('span');
      span.textContent = readControlValue(el) || '\u00a0';
      el.parentNode.replaceChild(span, el);
    });
    root.querySelectorAll('[contenteditable]').forEach(function (el) {
      el.contentEditable = 'false';
      el.removeAttribute('contenteditable');
    });
  }

  g.eapNormalizeExcelPaste = normalizeExcelPaste;
  g.eapIsExcelClipboardHtml = isExcelClipboardHtml;
  g.eapTrimExcelTableGrid = trimExcelTableGrid;
  g.eapRelaxExcelCellWidths = relaxExcelCellWidths;
  g.eapPreserveExcelColWidths = preserveExcelColWidths;
  g.eapEnsureExcelColumnsFitContent = ensureExcelColumnsFitContent;
  g.eapApplyExcelTablePxWidths = applyExcelTablePxWidths;
  g.eapFixDocTables = eapFixDocTables;
  g.eapPrepareFormFillTables = eapPrepareFormFillTables;
  g.eapBindDocScaleResize = bindDocScaleResize;
  g.eapSanitizePasteCss = sanitizePasteCss;
  g.eapSanitizeFormHtml = sanitizeFormHtml;
  g.eapPrepareImportedHtmlForEdit = prepareImportedHtmlForEdit;
  g.eapFlattenFormControls = flattenFormControls;
  g.eapReadControlValue = readControlValue;
  g.eapIsPlaceholderSelectOption = isPlaceholderSelectOption;
  g.eapWidgetDefaultValue = widgetDefaultValue;
  g.eapSyncSelectState = syncSelectState;
})(typeof window !== 'undefined' ? window : this);
