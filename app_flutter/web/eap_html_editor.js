(function () {
  var urlParams = new URLSearchParams(window.location.search);
  var editorMode = urlParams.get('mode') || 'design';
  var composeMode = editorMode === 'compose';
  var formMode = editorMode === 'form';
  var chromelessMode = composeMode || formMode;
  if (composeMode) document.body.classList.add('eap-compose-mode');
  if (formMode) document.body.classList.add('eap-form-mode');

  var editor = document.getElementById('editor');
  var source = document.getElementById('source');
  var bar = document.getElementById('bar');
  var tablePop = document.getElementById('tablePop');
  var linkPop = document.getElementById('linkPop');
  var sourceMode = false;
  var painterOn = false;
  var painterCss = null;
  var selectedImg = null;
  var imgDrag = null;
  var imgBox = document.getElementById('imgBox');
  var imgW = document.getElementById('imgW');
  var tableBox = document.getElementById('tableBox');
  var tableToolbar = document.getElementById('tableToolbar');
  var tblWidth = document.getElementById('tblWidth');
  var tblColW = document.getElementById('tblColW');
  var tblRowH = document.getElementById('tblRowH');
  var inspTable = document.getElementById('inspTable');
  var inspTblWidth = document.getElementById('inspTblWidth');
  var inspTblColW = document.getElementById('inspTblColW');
  var inspTblRowH = document.getElementById('inspTblRowH');
  var inspTblBorderColor = document.getElementById('inspTblBorderColor');
  var inspTblBorderWidth = document.getElementById('inspTblBorderWidth');
  var inspTblBorderStyle = document.getElementById('inspTblBorderStyle');
  var selectedCell = null;
  var pendingTableDeleteCell = null;
  var selectedRange = null;
  var tableResizeDrag = null;
  var cellDrag = null;
  var rangeDragJustEnded = false;
  var undoStack = [];
  var redoStack = [];
  var undoTimer = null;
  var applyingHistory = false;
  var savedEditorRange = null;

  function saveEditorSelection() {
    var sel = window.getSelection();
    if (!sel || !sel.rangeCount) return;
    var range = sel.getRangeAt(0);
    if (!editor.contains(range.commonAncestorContainer)) return;
    savedEditorRange = range.cloneRange();
  }

  function restoreEditorSelection() {
    if (!savedEditorRange) return false;
    var sel = window.getSelection();
    if (!sel) return false;
    sel.removeAllRanges();
    sel.addRange(savedEditorRange);
    return true;
  }

  function currentHtml() {
    if (sourceMode) return source.value;
    var clone = editor.cloneNode(true);
    clone.querySelectorAll('.eap-img-on, .eap-cell-on, .eap-cell-sel, .eap-on').forEach(function (el) {
      el.classList.remove('eap-img-on');
      el.classList.remove('eap-cell-on');
      el.classList.remove('eap-cell-sel');
      el.classList.remove('eap-on');
      if (!el.className) el.removeAttribute('class');
    });
    clone.querySelectorAll('.eap-w-del, .eap-h-del').forEach(function (el) { el.remove(); });
    var hasExcel = clone.querySelector('table.eap-excel-import');
    if (window.eapSanitizeFormHtml) {
      window.eapSanitizeFormHtml(clone, hasExcel ? { preserveTableLayout: true } : {});
    }
    if (window.eapFixDocTables) window.eapFixDocTables(clone);
    return clone.innerHTML;
  }

  function loadEditorHtml(html) {
    editor.innerHTML = html || '';
    if (window.eapMigrateDaouHtml) window.eapMigrateDaouHtml(editor);
    if (window.eapSanitizeFormHtml) window.eapSanitizeFormHtml(editor);
    if (window.eapPrepareImportedHtmlForEdit) window.eapPrepareImportedHtmlForEdit(editor, { designMode: true });
    if (window.migrateLegacyFormFields) window.migrateLegacyFormFields();
    if (composeMode) {
      if (window.eapFixDocTables) window.eapFixDocTables(editor);
    } else {
      prepareAllTables();
    }
    fitImages();
    if (window.refreshAllWidgetFaces) window.refreshAllWidgetFaces();
    if (formMode) {
      delete editor._eapMileageCalcBound;
      if (window.eapRunFormRuntime) window.eapRunFormRuntime(editor);
    }
    clearTableSelection();
    editor.focus();
  }

  function hideImgBox() {
    selectedImg = null;
    imgBox.classList.remove('show');
    editor.querySelectorAll('img.eap-img-on').forEach(function (el) {
      el.classList.remove('eap-img-on');
    });
  }

  function layoutImgBox() {
    if (!selectedImg || !imgBox.classList.contains('show')) return;
    var wr = document.getElementById('wrap').getBoundingClientRect();
    var r = selectedImg.getBoundingClientRect();
    imgBox.style.left = (r.left - wr.left) + 'px';
    imgBox.style.top = (r.top - wr.top) + 'px';
    imgBox.style.width = r.width + 'px';
    imgBox.style.height = r.height + 'px';
    imgW.value = String(Math.round(r.width));
  }

  function editorMaxW() {
    var cs = getComputedStyle(editor);
    var pad = parseFloat(cs.paddingLeft) + parseFloat(cs.paddingRight);
    return Math.max(80, editor.clientWidth - pad);
  }

  function applyImgSize(w) {
    if (!selectedImg) return;
    w = Math.max(20, Math.min(editorMaxW(), Math.round(w)));
    selectedImg.style.width = w + 'px';
    selectedImg.style.height = 'auto';
    selectedImg.style.maxWidth = '100%';
    selectedImg.removeAttribute('width');
    selectedImg.removeAttribute('height');
    layoutImgBox();
  }

  function parseLen(s) {
    if (!s) return 0;
    s = String(s).trim();
    var n = parseFloat(s);
    if (!n) return 0;
    if (/%$/.test(s)) return 0;
    if (/pt$/i.test(s)) return n;
    if (/px$/i.test(s)) return n * 0.75;
    if (/cm$/i.test(s)) return n * 28.35;
    if (/mm$/i.test(s)) return n * 2.835;
    return n;
  }

  function fitTablesOnPaste(isExcel) {
    if (window.eapMigrateDaouHtml) window.eapMigrateDaouHtml(editor);
    if (window.eapPrepareImportedHtmlForEdit) {
      window.eapPrepareImportedHtmlForEdit(editor, { designMode: true, excelPaste: !!isExcel });
    }
    if (window.eapFixDocTables) {
      window.eapFixDocTables(editor, {});
    }
    if (!isExcel && !composeMode) {
      editor.querySelectorAll('table').forEach(prepareEditableTable);
    } else if (!isExcel && composeMode) {
      editor.querySelectorAll('table:not(.eap-excel-import)').forEach(function (t) {
        if (!t.classList.contains('eap-approval-line')) t.classList.add('eap-editable-table');
      });
    }
    fitImages();
  }

  function prepareEditableTable(table) {
    if (!table || !editor.contains(table)) return table;
    if (table.classList.contains('eap-excel-import')) return table;
    if (table.classList.contains('eap-approval-line') || table.classList.contains('eap-product-table')) {
      return table;
    }
    table.classList.add('eap-editable-table');
    table.style.boxSizing = 'border-box';
    var nested = !!(table.parentElement && table.parentElement.closest('table'));
    if (nested) {
      table.style.tableLayout = 'auto';
      if (!table.style.width && !table.getAttribute('width')) table.style.width = 'auto';
      return table;
    }
    if (!table.style.width && !table.getAttribute('width')) {
      table.style.width = '100%';
    }
    lockTableColLayout(table);
    table.style.tableLayout = 'fixed';
    table.style.minWidth = '0';
    table.querySelectorAll('td, th').forEach(function (cell) {
      if (cell.closest('.eap-approval-line')) return;
      if (cell.querySelector('.eap-widget, .eap-widget-block')) return;
      cell.contentEditable = 'true';
    });
    return table;
  }

  function prepareAllTables() {
    if (composeMode) {
      if (window.eapSanitizeFormHtml) window.eapSanitizeFormHtml(editor);
      if (window.eapPrepareImportedHtmlForEdit) window.eapPrepareImportedHtmlForEdit(editor, { designMode: true });
      if (window.eapFixDocTables) window.eapFixDocTables(editor);
      return;
    }
    editor.querySelectorAll('table').forEach(prepareEditableTable);
    if (window.eapFixDocTables) window.eapFixDocTables(editor);
  }

  function countTableCols(table) {
    return tableGrid(table).cols || 0;
  }

  function ensureColGroup(table) {
    var colCount = countTableCols(table);
    if (!colCount) return null;
    var cg = table.querySelector('colgroup');
    if (!cg) {
      cg = document.createElement('colgroup');
      table.insertBefore(cg, table.firstChild);
    }
    while (cg.children.length < colCount) {
      var col = document.createElement('col');
      col.style.width = (100 / colCount).toFixed(2) + '%';
      cg.appendChild(col);
    }
    while (cg.children.length > colCount) cg.removeChild(cg.lastChild);
    if (cg.children[0] && !cg.children[0].style.width) {
      var pct = (100 / colCount).toFixed(2);
      Array.prototype.forEach.call(cg.children, function (colEl) {
        if (!colEl.style.width) colEl.style.width = pct + '%';
      });
    }
    return cg;
  }

  function measureColWidthsPx(table) {
    var g = tableGrid(table);
    var widths = [];
    for (var c = 0; c < g.cols; c++) {
      var w = 0;
      for (var r = 0; r < g.rows; r++) {
        var cell = g.grid[r] && g.grid[r][c];
        if (!cell) continue;
        var sp = cellSpan(cell);
        var o = cellOrigin(table, cell);
        if (o && o.c === c && sp.cs === 1) {
          w = cell.getBoundingClientRect().width;
          break;
        }
      }
      if (!w) {
        for (var r2 = 0; r2 < g.rows; r2++) {
          var cell2 = g.grid[r2] && g.grid[r2][c];
          if (!cell2) continue;
          var sp2 = cellSpan(cell2);
          w = cell2.getBoundingClientRect().width / Math.max(1, sp2.cs);
          break;
        }
      }
      widths.push(w || 0);
    }
    return widths;
  }

  function gridColRightX(table, g, colIdx) {
    for (var r = 0; r < g.rows; r++) {
      var cell = g.grid[r] && g.grid[r][colIdx];
      if (!cell) continue;
      var o = cellOrigin(table, cell);
      var sp = cellSpan(cell);
      if (o && o.c + sp.cs - 1 === colIdx) return cell.getBoundingClientRect().right;
    }
    var next = g.grid[0] && g.grid[0][colIdx + 1];
    return next ? next.getBoundingClientRect().left : null;
  }

  function lockTableColLayout(table) {
    if (!table || table.classList.contains('eap-approval-line')) return null;
    if (table.parentElement && table.parentElement.closest('table')) return null;
    var cg = ensureColGroup(table);
    if (!cg || !cg.children.length) return null;
    var px = measureColWidthsPx(table);
    var sum = 0;
    for (var i = 0; i < px.length; i++) sum += px[i];
    if (sum <= 0) sum = 1;
    var n = cg.children.length;
    for (var j = 0; j < n; j++) {
      var pct = ((px[j] || 0) / sum) * 100;
      if (!(pct > 0)) pct = 100 / n;
      cg.children[j].style.width = pct.toFixed(2) + '%';
    }
    table.style.tableLayout = 'fixed';
    table.setAttribute('data-eap-col-lock', '1');
    table.querySelectorAll('td, th').forEach(function (c) {
      if (c.closest('table') !== table) return;
      c.style.width = '';
      c.removeAttribute('width');
    });
    return cg;
  }

  function parseColWidthPct(col, table, colIdx) {
    var w = col.style.width || col.getAttribute('width') || '';
    var n = parseFloat(w);
    if (isNaN(n)) {
      var row = table.querySelector('tr');
      if (row && row.cells[colIdx]) {
        var tw = table.getBoundingClientRect().width || 1;
        return Math.max(5, Math.min(95, Math.round((row.cells[colIdx].getBoundingClientRect().width / tw) * 100)));
      }
      var total = table.querySelectorAll('colgroup col').length || 1;
      return Math.round(100 / total);
    }
    if (String(w).indexOf('px') >= 0) {
      var tableW = table.getBoundingClientRect().width || 1;
      return Math.max(5, Math.min(95, Math.round((n / tableW) * 100)));
    }
    return Math.max(5, Math.min(95, Math.round(n)));
  }

  function normalizeColGroupPct(table) {
    var cg = ensureColGroup(table);
    if (!cg || !cg.children.length) return cg;
    var n = cg.children.length;
    var pcts = [];
    var sum = 0;
    for (var i = 0; i < n; i++) {
      var p = parseColWidthPct(cg.children[i], table, i);
      pcts.push(p);
      sum += p;
    }
    if (sum <= 0 || Math.abs(sum - 100) > 2) {
      var even = 100 / n;
      for (var j = 0; j < n; j++) cg.children[j].style.width = even.toFixed(2) + '%';
    } else {
      for (var k = 0; k < n; k++) {
        cg.children[k].style.width = ((pcts[k] / sum) * 100).toFixed(2) + '%';
      }
    }
    table.querySelectorAll('td, th').forEach(function (c) {
      c.style.width = '';
      c.removeAttribute('width');
    });
    return cg;
  }

  function selectedColRange(table, colCount) {
    var from = 0;
    var to = Math.max(0, colCount - 1);
    if (selectedRange && selectedRange.table === table && selectedRange.c2 > selectedRange.c1) {
      from = Math.max(0, selectedRange.c1);
      to = Math.min(colCount - 1, selectedRange.c2);
    }
    return { from: from, to: to };
  }

  function selectedRowRange(table) {
    var n = table.rows.length;
    var from = 0;
    var to = Math.max(0, n - 1);
    if (selectedRange && selectedRange.table === table && selectedRange.r2 > selectedRange.r1) {
      from = Math.max(0, selectedRange.r1);
      to = Math.min(n - 1, selectedRange.r2);
    }
    return { from: from, to: to };
  }

  function equalizeColumns(table) {
    var cg = lockTableColLayout(table) || ensureColGroup(table);
    if (!cg || !cg.children.length) return;
    var n = cg.children.length;
    var range = selectedColRange(table, n);
    var count = range.to - range.from + 1;
    if (count < 1) return;
    beforeEdit();
    if (count >= n) {
      var pct = (100 / n).toFixed(2);
      Array.prototype.forEach.call(cg.children, function (col) {
        col.style.width = pct + '%';
      });
    } else {
      var sum = 0;
      for (var i = range.from; i <= range.to; i++) {
        sum += parseColWidthPct(cg.children[i], table, i);
      }
      var each = sum / count;
      for (var j = range.from; j <= range.to; j++) {
        cg.children[j].style.width = each.toFixed(2) + '%';
      }
    }
    table.querySelectorAll('td, th').forEach(function (c) {
      c.style.width = '';
      c.removeAttribute('width');
    });
    afterEdit();
    syncTableToolbarInputs();
    layoutTableBox();
    layoutColHandles();
  }

  function equalizeRows(table) {
    var range = selectedRowRange(table);
    var rows = [];
    for (var r = range.from; r <= range.to && r < table.rows.length; r++) {
      rows.push(table.rows[r]);
    }
    if (!rows.length) return;
    var sumH = 0;
    rows.forEach(function (row) {
      sumH += row.getBoundingClientRect().height;
    });
    var h = Math.max(20, Math.round(sumH / rows.length) || 28);
    beforeEdit();
    rows.forEach(function (row) {
      row.style.height = h + 'px';
      Array.prototype.forEach.call(row.cells, function (c) {
        if (cellSpan(c).rs > 1) return;
        c.style.height = h + 'px';
      });
    });
    afterEdit();
    tblRowH.value = String(h);
    if (inspTblRowH) inspTblRowH.value = String(h);
    layoutTableBox();
    layoutColHandles();
  }

  function cellIndex(cell) {
    return Array.prototype.indexOf.call(cell.parentNode.cells, cell);
  }

  function cellSpan(cell) {
    var cs = parseInt(cell.getAttribute('colspan'), 10);
    var rs = parseInt(cell.getAttribute('rowspan'), 10);
    if (isNaN(cs) || cs < 1) cs = 1;
    if (isNaN(rs) || rs < 1) rs = 1;
    return { cs: cs, rs: rs };
  }

  function tableGrid(table) {
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

  function cellOrigin(table, cell) {
    var g = tableGrid(table);
    for (var r = 0; r < g.rows; r++) {
      for (var c = 0; c < g.cols; c++) {
        if (g.grid[r][c] === cell) return { r: r, c: c, grid: g };
      }
    }
    return null;
  }

  function originCellAt(table, g, r, c) {
    if (r < 0 || c < 0 || r >= g.rows || c >= g.cols) return null;
    var cell = g.grid[r][c];
    if (!cell) return null;
    var o = cellOrigin(table, cell);
    if (!o) return null;
    return g.grid[o.r][o.c];
  }

  function firstOriginCellInRow(table, g, row) {
    for (var c = 0; c < g.cols; c++) {
      var cell = originCellAt(table, g, row, c);
      if (cell) return cell;
    }
    return null;
  }

  function lastOriginCellInRow(table, g, row) {
    for (var c = g.cols - 1; c >= 0; c--) {
      var cell = g.grid[row][c];
      if (!cell) continue;
      var o = cellOrigin(table, cell);
      if (o && o.r === row && o.c === c) return cell;
    }
    return null;
  }

  function findNavTarget(table, fromR, fromC, direction) {
    var g = tableGrid(table);
    var cell = g.grid[fromR] && g.grid[fromR][fromC];
    if (!cell) return null;
    var origin = cellOrigin(table, cell);
    if (!origin) return null;
    var r = origin.r;
    var c = origin.c;
    var sp = cellSpan(cell);

    if (direction === 'right') {
      var nc = c + sp.cs;
      if (nc < g.cols) return originCellAt(table, g, r, nc);
      if (r + 1 < g.rows) return firstOriginCellInRow(table, g, r + 1);
      return null;
    }
    if (direction === 'left') {
      if (c > 0) return originCellAt(table, g, r, c - 1);
      if (r > 0) return lastOriginCellInRow(table, g, r - 1);
      return null;
    }
    if (direction === 'down') {
      var nr = r + sp.rs;
      if (nr < g.rows) return originCellAt(table, g, nr, c);
      return null;
    }
    if (direction === 'up') {
      if (r > 0) return originCellAt(table, g, r - 1, c);
      return null;
    }
    return null;
  }

  function isCaretAtCellBoundary(cell, sel, direction) {
    if (!sel || !sel.rangeCount) return true;
    var range = sel.getRangeAt(0);
    if (!range.collapsed) return true;
    var probe = document.createRange();
    probe.selectNodeContents(cell);
    if (direction === 'left') {
      probe.collapse(true);
      return range.compareBoundaryPoints(Range.START_TO_START, probe) === 0;
    }
    if (direction === 'right') {
      probe.collapse(false);
      return range.compareBoundaryPoints(Range.END_TO_END, probe) === 0;
    }
    return true;
  }

  function tableNavOrigin(direction) {
    if (selectedRange && selectedRange.table) {
      if (direction === 'left' || direction === 'up') {
        return { table: selectedRange.table, r: selectedRange.r1, c: selectedRange.c1 };
      }
      return { table: selectedRange.table, r: selectedRange.r2, c: selectedRange.c2 };
    }
    var cell = activeTableCellFromSelection();
    if (!cell) return null;
    var table = cell.closest('table');
    var o = cellOrigin(table, cell);
    if (!o) return null;
    return { table: table, r: o.r, c: o.c };
  }

  function focusTableCell(cell, atStart) {
    if (!cell) return;
    selectTableCell(cell);
    editor.focus();
    var sel = window.getSelection();
    if (!sel) return;
    var range = document.createRange();
    range.selectNodeContents(cell);
    range.collapse(!!atStart);
    sel.removeAllRanges();
    sel.addRange(range);
  }

  function handleTableArrowKey(e, direction) {
    if (sourceMode || e.ctrlKey || e.metaKey || e.altKey) return false;

    var origin = tableNavOrigin(direction);
    if (!origin) return false;

    if (!isMultiCellRange()) {
      var sel = window.getSelection();
      var node = sel && sel.anchorNode;
      if (node && node.nodeType === 3) node = node.parentNode;
      var cell = node && node.closest ? node.closest('td, th') : null;
      if (!cell || !editor.contains(cell)) return false;
      if ((direction === 'left' || direction === 'right') &&
          !isCaretAtCellBoundary(cell, sel, direction)) {
        return false;
      }
    }

    var target = findNavTarget(origin.table, origin.r, origin.c, direction);
    if (!target) return false;
    e.preventDefault();
    focusTableCell(target, direction === 'left' || direction === 'up');
    return true;
  }

  function handleTableTabKey(e) {
    if (sourceMode) return false;
    var origin = tableNavOrigin(e.shiftKey ? 'left' : 'right');
    if (!origin) return false;
    var target = findNavTarget(origin.table, origin.r, origin.c, e.shiftKey ? 'left' : 'right');
    if (!target) return false;
    e.preventDefault();
    focusTableCell(target, !e.shiftKey);
    return true;
  }

  function expandRangeToMerged(table, r1, c1, r2, c2) {
    var a = Math.min(r1, r2), b = Math.max(r1, r2);
    var x = Math.min(c1, c2), y = Math.max(c1, c2);
    var g = tableGrid(table);
    var changed = true;
    while (changed) {
      changed = false;
      for (var r = a; r <= b; r++) {
        for (var c = x; c <= y; c++) {
          var cell = g.grid[r] && g.grid[r][c];
          if (!cell) continue;
          var o = cellOrigin(table, cell);
          if (!o) continue;
          var sp = cellSpan(cell);
          var na = Math.min(a, o.r);
          var nx = Math.min(x, o.c);
          var nb = Math.max(b, o.r + sp.rs - 1);
          var ny = Math.max(y, o.c + sp.cs - 1);
          if (na !== a || nx !== x || nb !== b || ny !== y) {
            a = na; x = nx; b = nb; y = ny;
            changed = true;
          }
        }
      }
    }
    return { r1: a, c1: x, r2: b, c2: y };
  }

  function uniqueCellsInRange(table, r1, c1, r2, c2) {
    var g = tableGrid(table);
    var seen = [];
    for (var r = r1; r <= r2; r++) {
      for (var c = c1; c <= c2; c++) {
        var cell = g.grid[r] && g.grid[r][c];
        if (!cell || seen.indexOf(cell) >= 0) continue;
        seen.push(cell);
      }
    }
    return seen;
  }

  function selectedEditorCells() {
    var nodes = editor.querySelectorAll('td.eap-cell-sel, th.eap-cell-sel');
    if (nodes.length) return Array.prototype.slice.call(nodes);
    if (selectedCell && editor.contains(selectedCell)) return [selectedCell];
    return [];
  }

  function applyToSelectedCells(mutator) {
    var cells = selectedEditorCells();
    if (!cells.length) return false;
    beforeEdit();
    cells.forEach(mutator);
    afterEdit();
    return true;
  }

  function activeTitleEl() {
    var sel = window.getSelection();
    if (!sel || !sel.rangeCount) return null;
    var n = sel.anchorNode;
    if (n && n.nodeType === 3) n = n.parentNode;
    if (!n || !n.closest) return null;
    return n.closest('.eap-title');
  }

  function applyTitleTextAlign(align) {
    var title = activeTitleEl();
    if (!title || !editor.contains(title)) return false;
    beforeEdit();
    title.style.setProperty('text-align', align, 'important');
    afterEdit();
    return true;
  }

  function applyTitleFontSize(size) {
    var title = activeTitleEl();
    if (!title || !editor.contains(title)) return false;
    beforeEdit();
    paintFontSize(title, size);
    title.querySelectorAll('*').forEach(function (el) {
      paintFontSize(el, size);
    });
    afterEdit();
    return true;
  }
  function applyCellTextAlign(align) {
    if (!selectionInsideSelectedCells()) return false;
    return applyToSelectedCells(function (cell) {
      cell.style.textAlign = align;
      cell.querySelectorAll('p,div,li,h1,h2,h3,h4,h5,h6').forEach(function (el) {
        el.style.textAlign = align;
      });
    });
  }

  function selectionInsideSelectedCells() {
    var cells = editor.querySelectorAll('td.eap-cell-sel, th.eap-cell-sel');
    if (!cells.length) return false;
    var sel = window.getSelection();
    if (!sel || !sel.rangeCount) return true;
    var n = sel.anchorNode;
    if (n && n.nodeType === 3) n = n.parentNode;
    if (!n || !n.closest) return false;
    var cell = n.closest('td, th');
    if (!cell || !editor.contains(cell)) return false;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] === cell || cells[i].contains(cell)) return true;
    }
    return false;
  }

  function closestAlignBlock(node) {
    var n = node;
    if (n && n.nodeType === 3) n = n.parentNode;
    while (n && n !== editor) {
      if (n.nodeType === 1) {
        var tag = n.tagName;
        if (/^(P|LI|H[1-6]|BLOCKQUOTE|PRE|CENTER|TD|TH)$/i.test(tag)) return n;
        if (tag === 'DIV' && !n.classList.contains('eap-widget')) {
          if (!n.querySelector('p, li, h1, h2, h3, h4, h5, h6, table')) return n;
        }
      }
      n = n.parentNode;
    }
    return null;
  }

  function lineIndexInBlock(block, targetNode) {
    var idx = 0;
    var found = false;
    function walk(n) {
      if (found || !n) return;
      if (n === targetNode) {
        found = true;
        return;
      }
      if (n.nodeName === 'BR') {
        idx += 1;
        return;
      }
      for (var c = n.firstChild; c; c = c.nextSibling) walk(c);
    }
    walk(block);
    return idx;
  }

  function splitBlockOnBr(block) {
    if (!block || block === editor) return [block];
    if (/^(TABLE|THEAD|TBODY|TR)$/i.test(block.tagName)) return [block];
    if (!/<br\s*\/?>/i.test(block.innerHTML)) return [block];
    var chunks = block.innerHTML.split(/<br\s*\/?>/i);
    var created = [];
    var inheritAlign = (block.style && block.style.textAlign) || block.getAttribute('align') || '';
    chunks.forEach(function (chunk) {
      var p = document.createElement('p');
      p.innerHTML = chunk && String(chunk).replace(/^\s+|\s+$/g, '') ? chunk : '&nbsp;';
      if (inheritAlign) p.style.textAlign = inheritAlign;
      created.push(p);
    });
    if (/^(TD|TH)$/i.test(block.tagName)) {
      block.innerHTML = '';
      created.forEach(function (p) { block.appendChild(p); });
      return created;
    }
    var parent = block.parentNode;
    if (!parent) return [block];
    created.forEach(function (p) { parent.insertBefore(p, block); });
    block.remove();
    return created.length ? created : [block];
  }

  function setElAlign(el, align) {
    if (!el || el === editor) return;
    if (el.tagName === 'CENTER') {
      var p = document.createElement('p');
      p.innerHTML = el.innerHTML;
      el.parentNode.replaceChild(p, el);
      el = p;
    }
    el.style.setProperty('text-align', align, 'important');
    el.removeAttribute('align');
    el.querySelectorAll('[align], [style*="text-align"]').forEach(function (s) {
      if (s === el) return;
      s.style.removeProperty('text-align');
      s.removeAttribute('align');
    });
  }

  function applyBlockTextAlign(align) {
    var sel = window.getSelection();
    if (!sel || !sel.rangeCount) return false;
    var range = sel.getRangeAt(0).cloneRange();
    var startB = closestAlignBlock(range.startContainer);
    if (startB && startB.classList && startB.classList.contains('eap-title')) {
      beforeEdit();
      startB.style.setProperty('text-align', align, 'important');
      afterEdit();
      return true;
    }
    var endB = closestAlignBlock(range.endContainer) || startB;
    if (!startB) return false;
    beforeEdit();
    var startLine = lineIndexInBlock(startB, range.startContainer);
    var endLine = lineIndexInBlock(endB, range.endContainer);
    var same = startB === endB;
    var startParts = splitBlockOnBr(startB);
    var endParts = same ? startParts : splitBlockOnBr(endB);
    var targets = [];
    if (same) {
      var from = Math.min(startLine, endLine);
      var to = Math.max(startLine, endLine);
      for (var i = from; i <= to && i < startParts.length; i++) targets.push(startParts[i]);
    } else {
      for (var a = startLine; a < startParts.length; a++) targets.push(startParts[a]);
      for (var b = 0; b <= endLine && b < endParts.length; b++) targets.push(endParts[b]);
    }
    if (!targets.length) {
      targets = [startParts[Math.min(startLine, startParts.length - 1)]];
    }
    targets.forEach(function (el) { setElAlign(el, align); });
    afterEdit();
    return true;
  }

  function applyCellFill(color) {
    return applyToSelectedCells(function (cell) {
      cell.style.backgroundColor = color;
    });
  }

  function paintTextColor(el, color) {
    el.style.color = color;
    el.removeAttribute('color');
  }

  function applyCellColor(color) {
    return applyToSelectedCells(function (cell) {
      paintTextColor(cell, color);
      cell.querySelectorAll('*').forEach(function (el) {
        paintTextColor(el, color);
      });
    });
  }

  function isMultiCellRange() {
    if (!selectedRange) return false;
    return selectedRange.r1 !== selectedRange.r2 || selectedRange.c1 !== selectedRange.c2;
  }

  function shouldApplyCmdToCellSelection() {
    var cells = selectedEditorCells();
    if (cells.length > 1) return true;
    return isMultiCellRange();
  }

  function execCommandOnElementContents(el, cmd, value) {
    if (!el || !editor.contains(el)) return;
    if (el.closest('.eap-widget, .eap-widget-block')) return;
    var range = document.createRange();
    range.selectNodeContents(el);
    var sel = window.getSelection();
    if (!sel) return;
    sel.removeAllRanges();
    sel.addRange(range);
    if (value !== undefined && value !== null) {
      document.execCommand(cmd, false, value);
    } else {
      document.execCommand(cmd, false, null);
    }
  }

  function applyCellTextCommand(cmd, value) {
    var cells = selectedEditorCells();
    if (!cells.length) return false;
    beforeEdit();
    cells.forEach(function (cell) {
      execCommandOnElementContents(cell, cmd, value);
    });
    afterEdit();
    focusEditor();
    return true;
  }

  function activeTableCellFromSelection() {
    var sel = window.getSelection();
    if (!sel || !sel.rangeCount) return selectedCell;
    var n = sel.anchorNode;
    if (n && n.nodeType === 3) n = n.parentNode;
    if (!n || !n.closest) return selectedCell;
    var cell = n.closest('td, th');
    if (cell && editor.contains(cell)) return cell;
    return selectedCell;
  }

  function selectedCellsToTsv() {
    if (!selectedRange) return '';
    var table = selectedRange.table;
    var g = tableGrid(table);
    var r1 = selectedRange.r1;
    var r2 = selectedRange.r2;
    var c1 = selectedRange.c1;
    var c2 = selectedRange.c2;
    var seen = {};
    var rows = [];
    for (var r = r1; r <= r2; r++) {
      var cols = [];
      for (var c = c1; c <= c2; c++) {
        var cell = g.grid[r] && g.grid[r][c];
        if (!cell) {
          cols.push('');
          continue;
        }
        var o = cellOrigin(table, cell);
        if (!o || o.r !== r || o.c !== c) {
          cols.push('');
          continue;
        }
        var key = cell;
        if (seen[key]) {
          cols.push('');
          continue;
        }
        seen[key] = true;
        cols.push(String(cell.innerText || '').replace(/\u00a0/g, ' ').trim());
      }
      rows.push(cols.join('\t'));
    }
    return rows.join('\n');
  }

  function selectedCellsToHtml() {
    if (!selectedRange) return '';
    var table = selectedRange.table;
    var g = tableGrid(table);
    var r1 = selectedRange.r1;
    var r2 = selectedRange.r2;
    var c1 = selectedRange.c1;
    var c2 = selectedRange.c2;
    var html = '<table><tbody>';
    var seen = {};
    for (var r = r1; r <= r2; r++) {
      html += '<tr>';
      for (var c = c1; c <= c2; c++) {
        var cell = g.grid[r] && g.grid[r][c];
        if (!cell) {
          html += '<td></td>';
          continue;
        }
        var o = cellOrigin(table, cell);
        if (!o || o.r !== r || o.c !== c || seen[cell]) {
          html += '<td></td>';
          continue;
        }
        seen[cell] = true;
        html += '<td>' + cell.innerHTML + '</td>';
      }
      html += '</tr>';
    }
    html += '</tbody></table>';
    return html;
  }

  function writeClipboard(text, html) {
    if (navigator.clipboard && window.ClipboardItem && html) {
      var item = new ClipboardItem({
        'text/plain': new Blob([text], { type: 'text/plain' }),
        'text/html': new Blob([html], { type: 'text/html' })
      });
      return navigator.clipboard.write([item]);
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      return navigator.clipboard.writeText(text);
    }
    return Promise.reject(new Error('clipboard unavailable'));
  }

  function copySelectedCells() {
    if (!isMultiCellRange() && selectedEditorCells().length <= 1) return false;
    var text = selectedCellsToTsv();
    if (!text && text !== '') return false;
    var html = selectedCellsToHtml();
    writeClipboard(text, html).catch(function () {});
    return true;
  }

  function cutSelectedCells() {
    if (!copySelectedCells()) return false;
    beforeEdit();
    selectedEditorCells().forEach(function (cell) {
      if (cell.querySelector('.eap-widget, .eap-widget-block')) return;
      cell.innerHTML = '&nbsp;';
    });
    afterEdit();
    return true;
  }

  function parsePasteGrid(text) {
    var rows = String(text || '').replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
    while (rows.length && !rows[rows.length - 1].trim()) rows.pop();
    return rows.map(function (row) { return row.split('\t'); });
  }

  function pasteGridIntoRange(grid) {
    if (!selectedRange || !grid.length) return false;
    var table = selectedRange.table;
    var g = tableGrid(table);
    beforeEdit();
    for (var ri = 0; ri < grid.length; ri++) {
      var row = grid[ri];
      var r = selectedRange.r1 + ri;
      if (r > selectedRange.r2 || r >= g.rows) break;
      for (var ci = 0; ci < row.length; ci++) {
        var c = selectedRange.c1 + ci;
        if (c > selectedRange.c2 || c >= g.cols) break;
        var cell = g.grid[r] && g.grid[r][c];
        if (!cell) continue;
        var o = cellOrigin(table, cell);
        if (!o || o.r !== r || o.c !== c) continue;
        if (cell.querySelector('.eap-widget, .eap-widget-block')) continue;
        var val = String(row[ci] || '');
        cell.innerHTML = val ? escapeHtml(val) : '&nbsp;';
      }
    }
    afterEdit();
    return true;
  }

  function pasteIntoTableCell(cell, html, text) {
    if (!cell || !editor.contains(cell)) return false;
    if (cell.querySelector('.eap-widget, .eap-widget-block')) return false;
    beforeEdit();
    var sel = window.getSelection();
    var hasRange = sel && sel.rangeCount && cell.contains(sel.anchorNode);
    if (hasRange) {
      var range = sel.getRangeAt(0);
      range.deleteContents();
      if (html && /<[a-z]/i.test(html) && !hasTable(html)) {
        var box = document.createElement('div');
        box.innerHTML = lightClean(html);
        box.querySelectorAll('script,meta,link,iframe,object,embed,table').forEach(function (n) { n.remove(); });
        var frag = document.createDocumentFragment();
        while (box.firstChild) frag.appendChild(box.firstChild);
        range.insertNode(frag);
      } else if (text) {
        var lines = String(text).replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
        lines.forEach(function (line, idx) {
          if (idx > 0) range.insertNode(document.createElement('br'));
          if (line) range.insertNode(document.createTextNode(line));
        });
      }
    } else if (text) {
      var safe = escapeHtml(text).replace(/\n/g, '<br>');
      if (cell.innerHTML.replace(/&nbsp;|\u00a0|\s|<br\s*\/?>/gi, '').trim()) {
        cell.innerHTML += safe;
      } else {
        cell.innerHTML = safe || '&nbsp;';
      }
    } else if (html && !hasTable(html)) {
      var inline = document.createElement('div');
      inline.innerHTML = lightClean(html);
      inline.querySelectorAll('script,meta,link,iframe,object,embed,table').forEach(function (n) { n.remove(); });
      cell.innerHTML = inline.innerHTML || '&nbsp;';
    } else {
      afterEdit();
      return false;
    }
    afterEdit();
    selectTableCell(cell);
    return true;
  }

  function clearCellHighlight() {
    editor.querySelectorAll('.eap-cell-sel, .eap-cell-on').forEach(function (el) {
      el.classList.remove('eap-cell-sel');
      el.classList.remove('eap-cell-on');
    });
  }

  function setCellRange(table, r1, c1, r2, c2) {
    var a = Math.min(r1, r2), b = Math.max(r1, r2);
    var x = Math.min(c1, c2), y = Math.max(c1, c2);
    if (a === b) {
      var g = tableGrid(table);
      for (var c = x; c <= y; c++) {
        var cell = g.grid[a] && g.grid[a][c];
        if (!cell) continue;
        var o = cellOrigin(table, cell);
        if (!o) continue;
        var sp = cellSpan(cell);
        x = Math.min(x, o.c);
        y = Math.max(y, o.c + sp.cs - 1);
      }
    } else {
      var exp = expandRangeToMerged(table, a, x, b, y);
      a = exp.r1; x = exp.c1; b = exp.r2; y = exp.c2;
    }
    clearCellHighlight();
    var cells = uniqueCellsInRange(table, a, x, b, y);
    cells.forEach(function (el) { el.classList.add('eap-cell-sel'); });
    selectedCell = cells[0] || null;
    if (selectedCell) selectedCell.classList.add('eap-cell-on');
    selectedRange = { table: table, r1: a, c1: x, r2: b, c2: y };
  }

  function mergeSelectedCells() {
    if (!selectedRange || !selectedCell) return;
    var table = selectedRange.table;
    var r1 = selectedRange.r1, c1 = selectedRange.c1, r2 = selectedRange.r2, c2 = selectedRange.c2;
    if (r1 === r2 && c1 === c2) return;
    var g = tableGrid(table);
    var master = g.grid[r1] && g.grid[r1][c1];
    if (!master) return;
    var seen = [];
    var toRemove = [];
    var html = [];
    for (var r = r1; r <= r2; r++) {
      for (var c = c1; c <= c2; c++) {
        var cell = g.grid[r] && g.grid[r][c];
        if (!cell || seen.indexOf(cell) >= 0) continue;
        seen.push(cell);
        var o = cellOrigin(table, cell);
        if (!o || o.r < r1 || o.c < c1 || o.r > r2 || o.c > c2) continue;
        var t = String(cell.innerHTML).replace(/&nbsp;|\u00a0/g, ' ').replace(/<br\s*\/?>/gi, '').trim();
        if (t) html.push(cell.innerHTML);
        if (cell !== master) toRemove.push(cell);
      }
    }
    if (!toRemove.length && seen.length < 2) return;
    beforeEdit();
    master.innerHTML = html.length ? html.join('<br>') : '&nbsp;';
    var cs = c2 - c1 + 1;
    var rs = r2 - r1 + 1;
    if (cs > 1) master.setAttribute('colspan', String(cs));
    else master.removeAttribute('colspan');
    if (rs > 1) master.setAttribute('rowspan', String(rs));
    else master.removeAttribute('rowspan');
    toRemove.forEach(function (cell) { cell.remove(); });
    master.querySelectorAll('.eap-widget').forEach(function (w) {
      if (window.applyWidgetLayout) window.applyWidgetLayout(w);
    });
    afterEdit();
    selectTableCell(master);
  }

  function splitSelectedCell() {
    var cell = selectedCell;
    if (!cell) return;
    var table = cell.closest('table');
    var g = tableGrid(table);
    var o = cellOrigin(table, cell);
    if (!o) return;
    var sp = cellSpan(cell);
    if (sp.cs <= 1 && sp.rs <= 1) return;
    beforeEdit();
    var tag = cell.tagName.toLowerCase();
    cell.removeAttribute('colspan');
    cell.removeAttribute('rowspan');
    var after = cell;
    for (var n = 1; n < sp.cs; n++) {
      var td = document.createElement(tag);
      td.innerHTML = '&nbsp;';
      after.insertAdjacentElement('afterend', td);
      after = td;
    }
    for (var r = o.r + 1; r < o.r + sp.rs; r++) {
      var tr = g.trs[r];
      if (!tr) continue;
      var anchor = null;
      for (var i = 0; i < tr.cells.length; i++) {
        var origCol = null;
        for (var c = 0; c < g.cols; c++) {
          if (g.grid[r][c] === tr.cells[i]) { origCol = c; break; }
        }
        if (origCol !== null && origCol < o.c) anchor = tr.cells[i];
      }
      var cursor = anchor;
      for (n = 0; n < sp.cs; n++) {
        var extra = document.createElement(tag);
        extra.innerHTML = '&nbsp;';
        if (cursor) cursor.insertAdjacentElement('afterend', extra);
        else tr.insertBefore(extra, tr.firstElementChild);
        cursor = extra;
      }
    }
    afterEdit();
    selectTableCell(cell);
  }

  function hideTblCtxMenu() {
    var menu = document.getElementById('tblCtxMenu');
    if (menu) menu.classList.remove('show');
  }

  function pushHistory() {
    if (applyingHistory || sourceMode) return;
    var html = currentHtml();
    if (undoStack.length && undoStack[undoStack.length - 1] === html) return;
    undoStack.push(html);
    if (undoStack.length > 80) undoStack.shift();
    redoStack = [];
  }

  function beforeEdit() { pushHistory(); }
  function afterEdit() { pushHistory(); }

  function applyHistory(html) {
    applyingHistory = true;
    editor.innerHTML = html || '';
    clearTableSelection();
    hideImgBox();
    prepareAllTables();
    applyingHistory = false;
  }

  function undoEdit() {
    if (undoStack.length < 2) return;
    redoStack.push(undoStack.pop());
    applyHistory(undoStack[undoStack.length - 1]);
  }

  function redoEdit() {
    if (!redoStack.length) return;
    var html = redoStack.pop();
    undoStack.push(html);
    applyHistory(html);
  }

  function syncInspTablePanel(show) {
    var e = document.getElementById('inspEmpty');
    var f = document.getElementById('inspForm');
    var a = document.getElementById('inspApproval');
    var del = document.getElementById('inspDel');
    var title = document.getElementById('inspTableTitle');
    if (!inspTable) return;
    if (show) {
      if (window.clearWidgetSelection) window.clearWidgetSelection();
      if (e) e.style.display = 'none';
      if (f) f.style.display = 'none';
      if (a) a.style.display = 'none';
      if (del) {
        del.style.display = 'block';
        del.textContent = '🗑 표 삭제';
      }
      if (title) title.textContent = formMode ? '표 편집' : '표 · 셀 크기';
      inspTable.style.display = 'block';
    } else {
      inspTable.style.display = 'none';
    }
  }

  /** 병합 셀 내부 열 경계에는 col-handle을 그리지 않는다 (한 칸처럼 보이게). */
  function isInternalMergedColHandle(table, colHandleIdx) {
    if (!selectedCell) return false;
    var o = cellOrigin(table, selectedCell);
    if (!o) return false;
    var sp = cellSpan(selectedCell);
    if (sp.cs <= 1) return false;
    return colHandleIdx >= o.c && colHandleIdx < o.c + sp.cs - 1;
  }

  function mergedColWidthPct(table, cg, cell) {
    if (!cg || !cell) return null;
    var o = cellOrigin(table, cell);
    if (!o) return null;
    var sp = cellSpan(cell);
    var sum = 0;
    for (var i = o.c; i < o.c + sp.cs && i < cg.children.length; i++) {
      sum += parseColWidthPct(cg.children[i], table, i);
    }
    return Math.max(5, Math.min(95, Math.round(sum)));
  }

  function layoutColHandles() {
    var box = document.getElementById('colHandles');
    if (!box || !selectedCell) return;
    var table = selectedCell.closest('table');
    if (!table) return;
    var wr = tableBox.getBoundingClientRect();
    var g = tableGrid(table);
    var n = Math.max(0, g.cols - 1);
    var dragging = tableResizeDrag && tableResizeDrag.type === 'col' && box.children.length === n;
    if (!dragging) box.innerHTML = '';
    for (var c = 0; c < n; c++) {
      if (isInternalMergedColHandle(table, c)) continue;
      var x = gridColRightX(table, g, c);
      if (x == null) continue;
      var left = (x - wr.left) + 'px';
      if (dragging) {
        box.children[c].style.left = left;
        continue;
      }
      var h = document.createElement('div');
      h.className = 'eap-col-handle';
      h.style.left = left;
      h.title = '열 너비 조절';
      (function (idx) {
        h.addEventListener('mousedown', function (ev) {
          ev.preventDefault();
          ev.stopPropagation();
          startColResize(table, idx, ev);
        });
      })(c);
      box.appendChild(h);
    }
  }

  function clearTableSelectionOnly() {
    clearCellHighlight();
    selectedCell = null;
    pendingTableDeleteCell = null;
    selectedRange = null;
    tableToolbar.classList.remove('show');
    tableBox.classList.remove('show');
    syncInspTablePanel(false);
    var ch = document.getElementById('colHandles');
    if (ch) ch.innerHTML = '';
    var e = document.getElementById('inspEmpty');
    if (e && !document.querySelector('.eap-widget.eap-on, .eap-approval-line.eap-on')) {
      e.style.display = 'block';
    }
  }

  function clearTableSelection() {
    if (window.clearWidgetSelection) window.clearWidgetSelection();
    clearTableSelectionOnly();
  }

  function layoutTableBox() {
    if (!selectedCell) return;
    var table = selectedCell.closest('table');
    if (!table) return;
    var wr = document.getElementById('wrap').getBoundingClientRect();
    var r = table.getBoundingClientRect();
    tableBox.style.left = (r.left - wr.left) + 'px';
    tableBox.style.top = (r.top - wr.top) + 'px';
    tableBox.style.width = r.width + 'px';
    tableBox.style.height = r.height + 'px';
    tableToolbar.style.left = (r.left - wr.left) + 'px';
    tableToolbar.style.top = Math.max(4, r.top - wr.top - 38) + 'px';
  }

  function syncTableToolbarInputs() {
    if (!selectedCell) return;
    var table = selectedCell.closest('table');
    var cg = table.querySelector('colgroup');
    var o = cellOrigin(table, selectedCell);
    var ci = o ? o.c : cellIndex(selectedCell);
    var tw = Math.max(20, Math.min(100, Math.round(tableWidthPct(table))));
    tblWidth.value = String(tw);
    var mergedPct = mergedColWidthPct(table, cg, selectedCell);
    if (mergedPct != null) {
      tblColW.value = String(mergedPct);
    } else if (cg && cg.children[ci]) {
      tblColW.value = String(parseColWidthPct(cg.children[ci], table, ci));
    } else {
      var tableW = table.getBoundingClientRect().width || 1;
      tblColW.value = String(Math.max(5, Math.min(95, Math.round((selectedCell.getBoundingClientRect().width / tableW) * 100))));
    }
    tblRowH.value = String(Math.round(selectedCell.getBoundingClientRect().height));
    if (inspTblWidth) inspTblWidth.value = tblWidth.value;
    if (inspTblColW) inspTblColW.value = tblColW.value;
    if (inspTblRowH) inspTblRowH.value = tblRowH.value;
    syncBorderControlsFromCell();
  }

  function getActiveCellRange() {
    if (selectedRange && selectedRange.table) {
      return {
        table: selectedRange.table,
        r1: selectedRange.r1,
        c1: selectedRange.c1,
        r2: selectedRange.r2,
        c2: selectedRange.c2
      };
    }
    if (!selectedCell) return null;
    var table = selectedCell.closest('table');
    if (!table) return null;
    var o = cellOrigin(table, selectedCell);
    if (!o) return null;
    var sp = cellSpan(selectedCell);
    return {
      table: table,
      r1: o.r,
      c1: o.c,
      r2: o.r + sp.rs - 1,
      c2: o.c + sp.cs - 1
    };
  }

  function rgbToHex(rgb) {
    if (!rgb) return '#333333';
    if (rgb.charAt(0) === '#') return rgb;
    var m = rgb.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)/);
    if (!m) return '#333333';
    return '#' + [m[1], m[2], m[3]].map(function (x) {
      var h = parseInt(x, 10).toString(16);
      return h.length === 1 ? '0' + h : h;
    }).join('');
  }

  function parseBorderSideValue(value) {
    if (!value || value === 'none' || value.indexOf('none') >= 0) return null;
    var parts = value.trim().split(/\s+/);
    if (parts.length < 3) return null;
    var width = parseFloat(parts[0]) || 1;
    var style = parts[1] || 'solid';
    var color = parts.slice(2).join(' ');
    return { width: Math.round(width), style: style, color: rgbToHex(color) };
  }

  function readBorderSpecFromUI() {
    var color = inspTblBorderColor ? inspTblBorderColor.value : '#333333';
    var width = inspTblBorderWidth ? parseInt(inspTblBorderWidth.value, 10) : 1;
    var style = inspTblBorderStyle ? inspTblBorderStyle.value : 'solid';
    if (!(width > 0)) width = 1;
    if (!style) style = 'solid';
    if (!color) color = '#333333';
    return width + 'px ' + style + ' ' + color;
  }

  function setCellSideBorder(cell, side, value) {
    var prop = 'border' + side.charAt(0).toUpperCase() + side.slice(1);
    cell.style[prop] = value || 'none';
  }

  function applyBorderPreset(preset) {
    var range = getActiveCellRange();
    if (!range) return;
    var table = range.table;
    if (table.classList.contains('eap-approval-line')) return;
    var cells = uniqueCellsInRange(table, range.r1, range.c1, range.r2, range.c2);
    if (!cells.length) return;
    var clear = preset === 'none' || preset === 'clear';
    var spec = clear ? null : readBorderSpecFromUI();
    beforeEdit();
    cells.forEach(function (cell) {
      var o = cellOrigin(table, cell);
      if (!o) return;
      var sp = cellSpan(cell);
      var rEnd = o.r + sp.rs - 1;
      var cEnd = o.c + sp.cs - 1;
      if (clear) {
        ['top', 'right', 'bottom', 'left'].forEach(function (s) { setCellSideBorder(cell, s, null); });
        return;
      }
      if (preset === 'all') {
        ['top', 'right', 'bottom', 'left'].forEach(function (s) { setCellSideBorder(cell, s, spec); });
        return;
      }
      if (preset === 'outer') {
        if (o.r === range.r1) setCellSideBorder(cell, 'top', spec);
        if (rEnd === range.r2) setCellSideBorder(cell, 'bottom', spec);
        if (o.c === range.c1) setCellSideBorder(cell, 'left', spec);
        if (cEnd === range.c2) setCellSideBorder(cell, 'right', spec);
        return;
      }
      if (preset === 'inner') {
        if (rEnd < range.r2) setCellSideBorder(cell, 'bottom', spec);
        if (cEnd < range.c2) setCellSideBorder(cell, 'right', spec);
        return;
      }
      if (preset === 'inner-h') {
        if (rEnd < range.r2) setCellSideBorder(cell, 'bottom', spec);
        return;
      }
      if (preset === 'inner-v') {
        if (cEnd < range.c2) setCellSideBorder(cell, 'right', spec);
        return;
      }
      if (preset === 'left' && o.c === range.c1) setCellSideBorder(cell, 'left', spec);
      if (preset === 'top' && o.r === range.r1) setCellSideBorder(cell, 'top', spec);
      if (preset === 'right' && cEnd === range.c2) setCellSideBorder(cell, 'right', spec);
      if (preset === 'bottom' && rEnd === range.r2) setCellSideBorder(cell, 'bottom', spec);
    });
    afterEdit();
  }

  function syncBorderControlsFromCell() {
    if (!selectedCell || !inspTblBorderColor) return;
    var cs = window.getComputedStyle(selectedCell);
    var parsed = parseBorderSideValue(cs.borderTopWidth + ' ' + cs.borderTopStyle + ' ' + cs.borderTopColor);
    if (!parsed) parsed = { width: 1, style: 'solid', color: '#333333' };
    inspTblBorderColor.value = parsed.color;
    if (inspTblBorderWidth) {
      var wOpt = String(parsed.width);
      if (inspTblBorderWidth.querySelector('option[value="' + wOpt + '"]')) {
        inspTblBorderWidth.value = wOpt;
      } else {
        inspTblBorderWidth.value = '1';
      }
    }
    if (inspTblBorderStyle && inspTblBorderStyle.querySelector('option[value="' + parsed.style + '"]')) {
      inspTblBorderStyle.value = parsed.style;
    }
  }

  function selectTableCell(cell) {
    hideImgBox();
    pendingTableDeleteCell = cell;
    var table = cell.closest('table');
    if (!table) return;
    prepareEditableTable(table);
    var o = cellOrigin(table, cell);
    var sp = cellSpan(cell);
    if (o) setCellRange(table, o.r, o.c, o.r + sp.rs - 1, o.c + sp.cs - 1);
    else {
      clearCellHighlight();
      selectedCell = cell;
      cell.classList.add('eap-cell-on');
      cell.classList.add('eap-cell-sel');
    }
    tableToolbar.classList.add('show');
    tableBox.classList.add('show');
    // form 모드에서는 플로팅 툴바만 숨기고, 표 크기 드래그 핸들(tableBox)은 유지한다.
    if (formMode) tableToolbar.classList.remove('show');
    syncTableToolbarInputs();
    syncInspTablePanel(true);
    layoutTableBox();
    layoutColHandles();
  }

  function tableWidthPct(table) {
    var sw = table.style.width || '';
    if (sw.indexOf('%') >= 0) return parseFloat(sw) || 100;
    if (sw.indexOf('px') >= 0) {
      var ew = editorMaxW();
      return ew > 0 ? Math.round((parseFloat(sw) / ew) * 100) : 100;
    }
    var attr = table.getAttribute('width');
    if (attr && String(attr).indexOf('%') >= 0) return parseFloat(attr) || 100;
    var tw = table.getBoundingClientRect().width;
    var ew2 = editorMaxW();
    return ew2 > 0 ? Math.round((tw / ew2) * 100) : 100;
  }

  function applyTableWidthPct(table, w) {
    w = Math.max(20, Math.min(100, Math.round(w)));
    table.style.setProperty('width', w + '%', 'important');
    table.style.setProperty('max-width', w + '%', 'important');
    table.style.minWidth = '0';
    table.style.boxSizing = 'border-box';
    table.removeAttribute('width');
    normalizeColGroupPct(table);
    tblWidth.value = String(w);
    if (inspTblWidth) inspTblWidth.value = String(w);
    layoutTableBox();
    layoutColHandles();
  }

  function setTableAlign(table, align) {
    table.style.marginLeft = align === 'right' ? 'auto' : (align === 'center' ? 'auto' : '0');
    table.style.marginRight = align === 'left' ? 'auto' : (align === 'center' ? 'auto' : '0');
    table.setAttribute('data-eap-align', align);
    layoutTableBox();
  }

  function insertTableRow(refCell, above) {
    beforeEdit();
    var table = refCell.closest('table');
    var row = refCell.parentNode;
    var cols = row.cells.length;
    var newRow = row.cloneNode(false);
    for (var i = 0; i < cols; i++) {
      var td = document.createElement(row.cells[i].tagName.toLowerCase());
      td.innerHTML = '&nbsp;';
      newRow.appendChild(td);
    }
    if (above) row.parentNode.insertBefore(newRow, row);
    else row.parentNode.insertBefore(newRow, row.nextSibling);
    ensureColGroup(table);
    afterEdit();
    selectTableCell(newRow.cells[cellIndex(refCell)] || newRow.cells[0]);
  }

  function insertTableCol(refCell, left) {
    beforeEdit();
    var table = refCell.closest('table');
    var ci = cellIndex(refCell);
    var insertAt = left ? ci : ci + 1;
    table.querySelectorAll('tr').forEach(function (tr) {
      var ref = tr.cells[insertAt] || null;
      var td = document.createElement(tr.cells[0] ? tr.cells[0].tagName.toLowerCase() : 'td');
      td.innerHTML = '&nbsp;';
      if (ref) tr.insertBefore(td, ref);
      else tr.appendChild(td);
    });
    var cg = ensureColGroup(table);
    if (cg) {
      var col = document.createElement('col');
      col.style.width = (100 / cg.children.length).toFixed(2) + '%';
      var refCol = cg.children[insertAt];
      if (refCol) cg.insertBefore(col, refCol);
      else cg.appendChild(col);
    }
    selectTableCell(selectedCell);
    syncTableToolbarInputs();
    afterEdit();
  }

  function deleteTableRow(refCell) {
    beforeEdit();
    var table = refCell.closest('table');
    var rows = table.querySelectorAll('tr');
    if (rows.length <= 1) return;
    var row = refCell.parentNode;
    var next = row.nextElementSibling || row.previousElementSibling;
    row.remove();
    if (next && next.cells.length) selectTableCell(next.cells[0]);
    else clearTableSelection();
    afterEdit();
  }

  function deleteTableCol(refCell) {
    beforeEdit();
    var table = refCell.closest('table');
    var ci = cellIndex(refCell);
    if (table.querySelector('tr').cells.length <= 1) return;
    table.querySelectorAll('tr').forEach(function (tr) {
      if (tr.cells[ci]) tr.deleteCell(ci);
    });
    var cg = table.querySelector('colgroup');
    if (cg && cg.children[ci]) cg.removeChild(cg.children[ci]);
    var row = table.querySelector('tr');
    if (row && row.cells.length) {
      var newCi = Math.min(ci, row.cells.length - 1);
      selectTableCell(row.cells[newCi]);
    } else clearTableSelection();
    afterEdit();
  }

  function deleteTable(refCell) {
    var cell = refCell || pendingTableDeleteCell || selectedCell;
    if (!cell) return;
    var table = cell.closest('table');
    if (!table || !editor.contains(table)) return;
    if (table.classList.contains('eap-approval-line')) return;
    beforeEdit();
    table.remove();
    pendingTableDeleteCell = null;
    clearTableSelection();
    afterEdit();
  }

  function applyColWidthPct(pct) {
    if (!selectedCell) return;
    pct = Math.max(5, Math.min(95, Math.round(pct)));
    var table = selectedCell.closest('table');
    var cg = lockTableColLayout(table);
    var o = cellOrigin(table, selectedCell);
    var ci = o ? o.c : cellIndex(selectedCell);
    if (!cg || !cg.children[ci]) return;
    var n = cg.children.length;
    var sp = cellSpan(selectedCell);
    var spanCols = (o && sp.cs > 1) ? sp.cs : 1;
    if (spanCols > 1) {
      var rest = 100 - pct;
      var others = n - spanCols;
      var eachOther = others > 0 ? rest / others : 0;
      var eachMerged = pct / spanCols;
      for (var j = 0; j < n; j++) {
        if (j >= ci && j < ci + spanCols) {
          cg.children[j].style.width = eachMerged.toFixed(2) + '%';
        } else {
          cg.children[j].style.width = eachOther.toFixed(2) + '%';
        }
      }
    } else if (n <= 1) {
      cg.children[0].style.width = '100%';
    } else {
      var restSingle = 100 - pct;
      var eachSingle = restSingle / (n - 1);
      for (var i = 0; i < n; i++) {
        cg.children[i].style.width = (i === ci ? pct : eachSingle).toFixed(2) + '%';
      }
    }
    normalizeColGroupPct(table);
    syncTableToolbarInputs();
    layoutTableBox();
    layoutColHandles();
  }

  function applyRowHeightPx(h) {
    if (!selectedCell) return;
    h = Math.max(20, h);
    var row = selectedCell.parentNode;
    Array.prototype.forEach.call(row.cells, function (c) {
      c.style.height = h + 'px';
    });
    layoutTableBox();
    layoutColHandles();
  }

  function startColResize(table, colIdx, e) {
    var cg = lockTableColLayout(table);
    if (!cg) return;
    var cols = cg.children;
    if (!cols[colIdx]) return;
    var startX = e.clientX;
    var tableW = table.getBoundingClientRect().width || 1;
    var w0 = parseColWidthPct(cols[colIdx], table, colIdx);
    var w1 = colIdx + 1 < cols.length ? parseColWidthPct(cols[colIdx + 1], table, colIdx + 1) : 0;
    tableResizeDrag = { type: 'col', colIdx: colIdx };
    function onMove(ev) {
      var dPct = ((ev.clientX - startX) / tableW) * 100;
      var pair = w0 + w1;
      var nw0 = Math.max(5, Math.min(pair ? pair - 5 : 95, w0 + dPct));
      cols[colIdx].style.width = nw0.toFixed(2) + '%';
      if (colIdx + 1 < cols.length) cols[colIdx + 1].style.width = Math.max(5, pair - nw0).toFixed(2) + '%';
      syncTableToolbarInputs();
      layoutTableBox();
      layoutColHandles();
    }
    function onUp() {
      tableResizeDrag = null;
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', onUp);
      layoutColHandles();
    }
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
  }

  function startRowResize(cell, e) {
    var table = cell.closest('table');
    var o = table ? cellOrigin(table, cell) : null;
    var sp = cellSpan(cell);
    var row = (o && table && table.rows[o.r + sp.rs - 1]) ? table.rows[o.r + sp.rs - 1] : cell.parentNode;
    var startY = e.clientY;
    var startH = row.getBoundingClientRect().height;
    tableResizeDrag = { type: 'row' };
    function onMove(ev) {
      var h = Math.max(20, startH + (ev.clientY - startY));
      row.style.height = h + 'px';
      Array.prototype.forEach.call(row.cells, function (c) {
        if (cellSpan(c).rs > 1) return;
        c.style.height = h + 'px';
      });
      tblRowH.value = String(Math.round(h));
      if (inspTblRowH) inspTblRowH.value = tblRowH.value;
      layoutTableBox();
    }
    function onUp() {
      tableResizeDrag = null;
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', onUp);
    }
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
  }

  function fitTables() {
    fitTablesOnPaste();
  }

  function fitPage() {
    prepareAllTables();
    fitImages();
  }

  function fitImages() {
    editor.querySelectorAll('img').forEach(function (img) {
      function apply() {
        img.style.maxWidth = '100%';
        img.style.height = 'auto';
        img.removeAttribute('height');
        var max = editorMaxW();
        var w = img.naturalWidth || img.width || 0;
        var attrW = parseInt(img.getAttribute('width') || '0', 10);
        if (w > max || attrW > max) {
          img.style.width = '100%';
          img.removeAttribute('width');
        }
      }
      if (img.complete) apply();
      else img.addEventListener('load', apply, { once: true });
    });
  }

  function selectImg(img) {
    editor.querySelectorAll('img.eap-img-on').forEach(function (el) {
      el.classList.remove('eap-img-on');
    });
    selectedImg = img;
    img.classList.add('eap-img-on');
    imgBox.classList.add('show');
    layoutImgBox();
  }

  editor.addEventListener('click', function (e) {
    if (e.target.closest('#tableToolbar')) return;
    if (e.target.closest('.eap-widget, .eap-widget-block, .eap-approval-line')) return;
    var img = e.target.closest('img');
    if (img && editor.contains(img)) {
      clearTableSelection();
      selectImg(img);
      e.preventDefault();
      return;
    }
    if (composeMode) {
      if (!e.target.closest('#imgBox')) hideImgBox();
      return;
    }
    var cell = e.target.closest('td, th');
    if (cell && editor.contains(cell)) {
      if (rangeDragJustEnded) {
        rangeDragJustEnded = false;
        return;
      }
      if (e.target.closest('.eap-widget, .eap-widget-block, .eap-approval-line')) {
        selectTableCell(cell);
        return;
      }
      focusTableCell(cell, false);
      return;
    }
    if (!e.target.closest('#imgBox')) hideImgBox();
    if (!e.target.closest('table')) clearTableSelection();
  });

  editor.addEventListener('mousedown', function (e) {
    if (composeMode || sourceMode || tableResizeDrag) return;
    hideTblCtxMenu();
    var cell = e.target.closest('td, th');
    if (!cell || !editor.contains(cell)) return;
    if (e.button !== 0) return;
    var rect = cell.getBoundingClientRect();
    var nearRight = e.clientX >= rect.right - 8;
    var nearBottom = e.clientY >= rect.bottom - 8;
    var table = cell.closest('table');
    if (nearRight && table) {
      e.preventDefault();
      selectTableCell(cell);
      var o = cellOrigin(table, cell);
      var sp = cellSpan(cell);
      startColResize(table, o ? (o.c + sp.cs - 1) : cellIndex(cell), e);
      return;
    }
    if (nearBottom) {
      e.preventDefault();
      selectTableCell(cell);
      startRowResize(cell, e);
      return;
    }
    if (!table) return;
    var origin = cellOrigin(table, cell);
    if (!origin) return;
    cellDrag = { table: table, r: origin.r, c: origin.c, moved: false, startX: e.clientX, startY: e.clientY };
  });

  editor.addEventListener('mousemove', function (e) {
    if (sourceMode) return;
    if (cellDrag) {
      var over = e.target.closest('td, th');
      if (over && over.closest('table') === cellDrag.table) {
        var o2 = cellOrigin(cellDrag.table, over);
        if (o2 && (o2.r !== cellDrag.r || o2.c !== cellDrag.c)) {
          var dx = e.clientX - cellDrag.startX;
          var dy = e.clientY - cellDrag.startY;
          if (!cellDrag.moved && (dx * dx + dy * dy) < 36) return;
          cellDrag.moved = true;
          editor.classList.add('eap-cell-dragging');
          e.preventDefault();
          try { window.getSelection().removeAllRanges(); } catch (err) {}
          setCellRange(cellDrag.table, cellDrag.r, cellDrag.c, o2.r, o2.c);
          tableBox.classList.add('show');
          layoutTableBox();
        }
      }
      return;
    }
    if (tableResizeDrag) return;
    var cell = e.target.closest('td, th');
    if (!cell || !editor.contains(cell)) {
      editor.style.cursor = '';
      return;
    }
    var rect = cell.getBoundingClientRect();
    if (e.clientX >= rect.right - 8) editor.style.cursor = 'col-resize';
    else if (e.clientY >= rect.bottom - 8) editor.style.cursor = 'row-resize';
    else editor.style.cursor = '';
  });

  window.addEventListener('resize', function () {
    layoutImgBox();
    layoutTableBox();
    layoutColHandles();
  });

  function handleTableToolbarClick(e) {
    var borderBtn = e.target.closest('button[data-border]');
    if (borderBtn) {
      e.preventDefault();
      applyBorderPreset(borderBtn.getAttribute('data-border'));
      return;
    }
    var btn = e.target.closest('button[data-tbl]');
    if (!btn || !selectedCell) return;
    var table = selectedCell.closest('table');
    var act = btn.getAttribute('data-tbl');
    if (act === 'align-left') setTableAlign(table, 'left');
    if (act === 'align-center') setTableAlign(table, 'center');
    if (act === 'align-right') setTableAlign(table, 'right');
    if (act === 'row-above') insertTableRow(selectedCell, true);
    if (act === 'row-below') insertTableRow(selectedCell, false);
    if (act === 'col-left') insertTableCol(selectedCell, true);
    if (act === 'col-right') insertTableCol(selectedCell, false);
    if (act === 'del-row') deleteTableRow(selectedCell);
    if (act === 'del-col') deleteTableCol(selectedCell);
    if (act === 'del-table') deleteTable(selectedCell);
    if (act === 'equal-cols') equalizeColumns(table);
    if (act === 'equal-rows') equalizeRows(table);
  }

  tableToolbar.addEventListener('click', handleTableToolbarClick);
  if (inspTable) {
    inspTable.addEventListener('click', handleTableToolbarClick);
    inspTable.addEventListener('mousedown', function (e) {
      if (e.target.closest('[data-tbl="del-table"], #inspDel')) {
        e.preventDefault();
      } else {
        e.preventDefault();
      }
    });
  }
  var inspDelBtn = document.getElementById('inspDel');
  if (inspDelBtn) {
    inspDelBtn.addEventListener('mousedown', function (e) {
      if (selectedCell || pendingTableDeleteCell) e.preventDefault();
    });
    inspDelBtn.addEventListener('click', function () {
      if (selectedCell || pendingTableDeleteCell) {
        deleteTable(selectedCell || pendingTableDeleteCell);
      }
    });
  }

  function onTblWidthInput() {
    if (!selectedCell) return;
    applyTableWidthPct(selectedCell.closest('table'), parseFloat(tblWidth.value) || 100);
  }
  tblWidth.addEventListener('change', onTblWidthInput);
  tblWidth.addEventListener('input', onTblWidthInput);

  tableBox.querySelector('.tbl-resize-e').addEventListener('mousedown', function (e) {
    if (!selectedCell) return;
    e.preventDefault();
    e.stopPropagation();
    var table = selectedCell.closest('table');
    var startX = e.clientX;
    var startW = table.getBoundingClientRect().width;
    var maxW = editorMaxW();
    function onMove(ev) {
      var nw = Math.max(maxW * 0.2, Math.min(maxW, startW + (ev.clientX - startX)));
      applyTableWidthPct(table, (nw / maxW) * 100);
    }
    function onUp() {
      window.removeEventListener('mousemove', onMove);
      window.removeEventListener('mouseup', onUp);
    }
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
  });

  tblColW.addEventListener('change', function () {
    applyColWidthPct(parseFloat(this.value) || 20);
    syncTableToolbarInputs();
  });

  tblRowH.addEventListener('change', function () {
    applyRowHeightPx(parseFloat(this.value) || 28);
  });

  if (inspTblWidth) {
    inspTblWidth.addEventListener('change', function () {
      tblWidth.value = this.value;
      onTblWidthInput();
    });
    inspTblWidth.addEventListener('input', function () {
      tblWidth.value = this.value;
      onTblWidthInput();
    });
  }
  if (inspTblColW) {
    inspTblColW.addEventListener('change', function () {
      tblColW.value = this.value;
      applyColWidthPct(parseFloat(this.value) || 20);
      syncTableToolbarInputs();
    });
  }
  if (inspTblRowH) {
    inspTblRowH.addEventListener('change', function () {
      tblRowH.value = this.value;
      applyRowHeightPx(parseFloat(this.value) || 28);
    });
  }

  tableToolbar.addEventListener('mousedown', function (e) { e.preventDefault(); });
  var tblCtxMenu = document.getElementById('tblCtxMenu');
  editor.addEventListener('contextmenu', function (e) {
    var cell = e.target.closest('td, th');
    if (!cell || !editor.contains(cell)) return;
    e.preventDefault();
    if (!cell.classList.contains('eap-cell-sel')) selectTableCell(cell);
    if (!tblCtxMenu) return;
    tblCtxMenu.classList.add('show');
    var x = Math.min(e.clientX, window.innerWidth - 180);
    var y = Math.min(e.clientY, window.innerHeight - 280);
    tblCtxMenu.style.left = x + 'px';
    tblCtxMenu.style.top = y + 'px';
  });
  document.addEventListener('mousedown', function (e) {
    if (tblCtxMenu && !tblCtxMenu.contains(e.target)) hideTblCtxMenu();
  });
  if (tblCtxMenu) {
    tblCtxMenu.addEventListener('mousedown', function (e) { e.preventDefault(); });
    tblCtxMenu.addEventListener('click', function (e) {
      var btn = e.target.closest('button[data-ctx]');
      if (!btn || !selectedCell) return;
      var act = btn.getAttribute('data-ctx');
      var table = selectedCell.closest('table');
      if (act === 'merge') mergeSelectedCells();
      if (act === 'split') splitSelectedCell();
      if (act === 'row-above') insertTableRow(selectedCell, true);
      if (act === 'row-below') insertTableRow(selectedCell, false);
      if (act === 'col-left') insertTableCol(selectedCell, true);
      if (act === 'col-right') insertTableCol(selectedCell, false);
      if (act === 'equal-cols') equalizeColumns(table);
      if (act === 'equal-rows') equalizeRows(table);
      if (act === 'border-all') applyBorderPreset('all');
      if (act === 'border-none') applyBorderPreset('none');
      if (act === 'del-row') deleteTableRow(selectedCell);
      if (act === 'del-col') deleteTableCol(selectedCell);
      if (act === 'del-table') deleteTable(selectedCell);
      hideTblCtxMenu();
    });
  }
  function wheelDeltaY(e) {
    var dy = e.deltaY;
    if (e.deltaMode === 1) dy *= 16;
    else if (e.deltaMode === 2) {
      var stage = document.getElementById('stage');
      dy *= stage ? stage.clientHeight : 400;
    }
    return dy;
  }

  document.addEventListener('wheel', function (e) {
    var stage = document.getElementById('stage');
    if (!stage || sourceMode) return;
    var dy = wheelDeltaY(e);
    if (dy === 0) return;
    e.preventDefault();

    var maxScroll = Math.max(0, stage.scrollHeight - stage.clientHeight);
    var before = stage.scrollTop;
    if (maxScroll > 0) {
      stage.scrollTop = Math.max(0, Math.min(maxScroll, before + dy));
    }
    var consumed = stage.scrollTop - before;
    var remaining = dy - consumed;
    if (chromelessMode || Math.abs(remaining) < 0.5) return;

    parent.postMessage(JSON.stringify({
      type: 'eapWheel',
      deltaY: remaining,
      deltaX: e.deltaX
    }), '*');
  }, { passive: false });

  imgBox.addEventListener('mousedown', function (e) {
    var h = e.target.getAttribute('data-h');
    if (!h || !selectedImg) return;
    e.preventDefault();
    var r = selectedImg.getBoundingClientRect();
    imgDrag = { h: h, x: e.clientX, y: e.clientY, w: r.width, ht: r.height };
  });

  window.addEventListener('mousemove', function (e) {
    if (cellDrag && cellDrag.moved) {
      e.preventDefault();
      var over = document.elementFromPoint(e.clientX, e.clientY);
      var cell = over && over.closest ? over.closest('td, th') : null;
      if (cell && cell.closest('table') === cellDrag.table) {
        var o2 = cellOrigin(cellDrag.table, cell);
        if (o2) setCellRange(cellDrag.table, cellDrag.r, cellDrag.c, o2.r, o2.c);
      }
      return;
    }
    if (!imgDrag || !selectedImg) return;
    var dx = e.clientX - imgDrag.x;
    var dy = e.clientY - imgDrag.y;
    var w = imgDrag.w;
    if (imgDrag.h.indexOf('e') >= 0) w = imgDrag.w + dx;
    if (imgDrag.h.indexOf('w') >= 0) w = imgDrag.w - dx;
    if (imgDrag.h === 's' && imgDrag.ht) {
      w = (imgDrag.ht + dy) * (imgDrag.w / imgDrag.ht);
    }
    applyImgSize(w);
  });

  window.addEventListener('mouseup', function () {
    imgDrag = null;
    if (cellDrag) {
      editor.classList.remove('eap-cell-dragging');
      if (cellDrag.moved) {
        rangeDragJustEnded = true;
        prepareEditableTable(cellDrag.table);
        tableBox.classList.add('show');
        layoutTableBox();
        layoutColHandles();
        syncTableToolbarInputs();
      }
      cellDrag = null;
    }
  });

  imgW.addEventListener('change', function () {
    applyImgSize(parseFloat(this.value) || 20);
  });

  imgBox.querySelector('.img-toolbar').addEventListener('click', function (e) {
    var btn = e.target.closest('button[data-imgw]');
    if (!btn || !selectedImg) return;
    var pct = parseFloat(btn.getAttribute('data-imgw')) / 100;
    var parentW = editorMaxW();
    applyImgSize(parentW * pct);
  });

  editor.addEventListener('keydown', function (e) {
    if ((e.ctrlKey || e.metaKey) && !e.altKey) {
      var k = e.key.toLowerCase();
      if (k === 'z') {
        e.preventDefault();
        if (e.shiftKey) redoEdit();
        else undoEdit();
        return;
      }
      if (k === 'y') {
        e.preventDefault();
        redoEdit();
        return;
      }
      if (k === 'c' && shouldApplyCmdToCellSelection()) {
        copySelectedCells();
        return;
      }
      if (k === 'x' && shouldApplyCmdToCellSelection()) {
        e.preventDefault();
        cutSelectedCells();
        return;
      }
    }

    var arrowMap = {
      ArrowLeft: 'left',
      ArrowRight: 'right',
      ArrowUp: 'up',
      ArrowDown: 'down'
    };
    if (arrowMap[e.key] && handleTableArrowKey(e, arrowMap[e.key])) return;
    if (e.key === 'Tab' && handleTableTabKey(e)) return;

    if ((e.key === ' ' || e.code === 'Space') && !e.ctrlKey && !e.metaKey && !e.altKey && !sourceMode) {
      var sel = window.getSelection();
      if (sel && sel.rangeCount) {
        var n = sel.anchorNode;
        if (n && n.nodeType === 3) n = n.parentNode;
        if (n && editor.contains(n)) {
          e.preventDefault();
          if (document.queryCommandSupported('insertText')) {
            document.execCommand('insertText', false, ' ');
          }
          return;
        }
      }
    }

    if (!selectedImg) return;
    if (e.key === 'Delete' || e.key === 'Backspace') {
      e.preventDefault();
      selectedImg.remove();
      hideImgBox();
    }
  });

  editor.addEventListener('input', function () {
    if (applyingHistory) return;
    clearTimeout(undoTimer);
    undoTimer = setTimeout(pushHistory, 400);
  });

  function focusEditor() {
    if (!sourceMode) editor.focus();
  }

  bar.addEventListener('mousedown', function (e) {
    if (e.target.closest('select,input,textarea')) {
      saveEditorSelection();
      return;
    }
    e.preventDefault();
  });

  editor.addEventListener('mouseup', saveEditorSelection);
  editor.addEventListener('keyup', saveEditorSelection);

  bar.addEventListener('click', function (ev) {
    var btn = ev.target.closest('button');
    if (!btn || btn.id === 'linkOk') return;
    var act = btn.getAttribute('data-act');
    var cmd = btn.getAttribute('data-cmd');
    if (act) runAct(act, btn);
    else if (cmd) {
      if (cmd === 'undo') { undoEdit(); return; }
      if (cmd === 'redo') { redoEdit(); return; }
      var alignMap = {
        justifyLeft: 'left',
        justifyCenter: 'center',
        justifyRight: 'right',
        justifyFull: 'justify'
      };
      if (alignMap[cmd]) {
        restoreEditorSelection();
        if (applyTitleTextAlign(alignMap[cmd]) || applyCellTextAlign(alignMap[cmd]) || applyBlockTextAlign(alignMap[cmd])) {
          saveEditorSelection();
          focusEditor();
          return;
        }
      }
      var cellCmds = {
        bold: true,
        italic: true,
        underline: true,
        strikeThrough: true,
        removeFormat: true,
        unlink: true
      };
      if (cellCmds[cmd] && shouldApplyCmdToCellSelection()) {
        applyCellTextCommand(cmd);
        return;
      }
      document.execCommand(cmd, false, null);
      focusEditor();
    }
  });

  document.getElementById('blockSel').addEventListener('change', function () {
    if (!this.value) return;
    document.execCommand('formatBlock', false, this.value);
    this.value = '';
    focusEditor();
  });
  document.getElementById('fontSel').addEventListener('change', function () {
    if (!this.value) return;
    document.execCommand('fontName', false, this.value);
    this.value = '';
    focusEditor();
  });
  document.getElementById('sizeSel').addEventListener('change', function () {
    if (!this.value) return;
    setFontSize(this.value);
    this.value = '';
    focusEditor();
  });
  document.getElementById('lineSel').addEventListener('change', function () {
    if (!this.value) return;
    setLineHeight(this.value);
    this.value = '';
    focusEditor();
  });
  function applyEditorTextColor(color) {
    document.getElementById('fgSwatch').style.background = color;
    if (applyCellColor(color)) return;
    document.execCommand('styleWithCSS', false, true);
    document.execCommand('foreColor', false, color);
    focusEditor();
  }

  document.getElementById('fgColor').addEventListener('input', function () {
    applyEditorTextColor(this.value);
  });
  document.getElementById('fgColor').addEventListener('change', function () {
    applyEditorTextColor(this.value);
  });
  document.getElementById('bgColor').addEventListener('input', function () {
    document.getElementById('bgSwatch').style.background = this.value;
    if (applyCellFill(this.value)) return;
    document.execCommand('styleWithCSS', false, true);
    document.execCommand('hiliteColor', false, this.value);
    focusEditor();
  });

  function paintFontSize(el, size) {
    if (!el || el === editor) return;
    if (el.closest && el.closest('.eap-widget, .eap-widget-block')) return;
    el.style.setProperty('font-size', size, 'important');
    el.removeAttribute('size');
  }

  function nodesInRange(range) {
    var root = range.commonAncestorContainer;
    if (root.nodeType === 3) root = root.parentNode;
    if (!root || !root.nodeType) return [];
    var out = [];
    var walker = document.createTreeWalker(root, NodeFilter.SHOW_ELEMENT | NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        if (!range.intersectsNode(node)) return NodeFilter.FILTER_REJECT;
        if (node.nodeType === 1 && node.closest && node.closest('.eap-widget, .eap-widget-block')) {
          return NodeFilter.FILTER_REJECT;
        }
        return NodeFilter.FILTER_ACCEPT;
      }
    });
    var n;
    while (n = walker.nextNode()) out.push(n);
    return out;
  }

  function applyFontSizeToRange(range, size) {
    var seen = {};
    nodesInRange(range).forEach(function (node) {
      if (node.nodeType === 3) {
        var el = node.parentElement;
        while (el && el !== editor) {
          if (seen[el]) break;
          seen[el] = true;
          paintFontSize(el, size);
          if (/^(P|DIV|TD|TH|LI|H[1-6]|SPAN|FONT|B|I|U|STRONG|EM|A)$/i.test(el.tagName)) break;
          el = el.parentElement;
        }
        return;
      }
      paintFontSize(node, size);
      node.querySelectorAll('*').forEach(function (child) {
        paintFontSize(child, size);
      });
    });
  }

  function applyFontSizeToCell(cell, size) {
    if (!cell || cell.querySelector('.eap-widget, .eap-widget-block')) return;
    paintFontSize(cell, size);
    cell.querySelectorAll('*').forEach(function (el) {
      paintFontSize(el, size);
    });
  }

  function setFontSize(pt) {
    var n = parseFloat(pt);
    if (isNaN(n) || n <= 0) return;
    var size = n + 'pt';
    restoreEditorSelection();

    if (applyTitleFontSize(size)) {
      saveEditorSelection();
      focusEditor();
      return;
    }

    if (shouldApplyCmdToCellSelection()) {
      beforeEdit();
      selectedEditorCells().forEach(function (cell) {
        applyFontSizeToCell(cell, size);
      });
      afterEdit();
      focusEditor();
      return;
    }

    var sel = window.getSelection();
    if (!sel || !sel.rangeCount) return;
    var range = sel.getRangeAt(0);
    if (!editor.contains(range.commonAncestorContainer)) return;

    beforeEdit();
    if (range.collapsed) {
      var block = closestBlock();
      if (block) paintFontSize(block, size);
    } else {
      applyFontSizeToRange(range, size);
    }
    afterEdit();
    saveEditorSelection();
    focusEditor();
  }

  function closestBlock() {
    var sel = window.getSelection();
    if (!sel.rangeCount) return null;
    var n = sel.anchorNode;
    if (n && n.nodeType === 3) n = n.parentNode;
    while (n && n !== editor && !/^(P|DIV|LI|H[1-6]|TD|TH|BLOCKQUOTE|PRE)$/i.test(n.tagName || '')) {
      n = n.parentNode;
    }
    return n && n !== editor ? n : null;
  }

  function setLineHeight(v) {
    var n = closestBlock();
    if (n) n.style.lineHeight = v;
  }

  function runAct(act, btn) {
    if (act === 'paste') pasteClicked();
    if (act === 'clear') {
      if (shouldApplyCmdToCellSelection()) {
        applyCellTextCommand('removeFormat');
        applyCellTextCommand('unlink');
        return;
      }
      document.execCommand('removeFormat', false, null);
      document.execCommand('unlink', false, null);
      focusEditor();
    }
    if (act === 'painter') togglePainter(btn);
    if (act === 'quote') {
      document.execCommand('formatBlock', false, 'blockquote');
      focusEditor();
    }
    if (act === 'image') document.getElementById('imgFile').click();
    if (act === 'table') togglePop(tablePop, btn);
    if (act === 'mergeCells') mergeSelectedCells();
    if (act === 'splitCell') splitSelectedCell();
    if (act === 'link') togglePop(linkPop, btn);
    if (act === 'full') toggleFull();
    if (act === 'spell') {
      editor.spellcheck = !editor.spellcheck;
      btn.classList.toggle('on', editor.spellcheck);
      focusEditor();
    }
    if (act === 'source') toggleSource(btn);
    if (act === 'htmlImport') document.getElementById('htmlFileInput').click();
  }

  function togglePainter(btn) {
    if (painterOn) {
      painterOn = false;
      painterCss = null;
      btn.classList.remove('on');
      return;
    }
    var n = closestBlock() || editor;
    var cs = getComputedStyle(n);
    painterCss = {
      color: cs.color,
      backgroundColor: cs.backgroundColor,
      fontFamily: cs.fontFamily,
      fontWeight: cs.fontWeight,
      fontStyle: cs.fontStyle
    };
    painterOn = true;
    btn.classList.add('on');
  }

  editor.addEventListener('mouseup', function () {
    if (!painterOn || !painterCss) return;
    document.execCommand('styleWithCSS', false, true);
    document.execCommand('foreColor', false, painterCss.color);
    if (painterCss.backgroundColor && painterCss.backgroundColor !== 'rgba(0, 0, 0, 0)') {
      document.execCommand('hiliteColor', false, painterCss.backgroundColor);
    }
    var family = (painterCss.fontFamily || '').split(',')[0].replace(/['"]/g, '').trim();
    if (family) document.execCommand('fontName', false, family);
    painterOn = false;
    document.getElementById('btnPainter').classList.remove('on');
  });

  function togglePop(pop, btn) {
    var show = !pop.classList.contains('show');
    tablePop.classList.remove('show');
    linkPop.classList.remove('show');
    if (!show) return;
    var r = btn.getBoundingClientRect();
    var br = bar.getBoundingClientRect();
    pop.style.left = (r.left - br.left) + 'px';
    pop.style.top = (r.bottom - br.top + 4) + 'px';
    pop.classList.add('show');
    if (pop === linkPop) {
      document.getElementById('linkUrl').value = 'https://';
      document.getElementById('linkUrl').focus();
    }
  }

  document.getElementById('linkOk').addEventListener('click', function () {
    var url = document.getElementById('linkUrl').value.trim();
    linkPop.classList.remove('show');
    if (url) document.execCommand('createLink', false, url);
    focusEditor();
  });

  (function buildTablePop() {
    for (var r = 1; r <= 8; r++) {
      for (var c = 1; c <= 8; c++) {
        var i = document.createElement('i');
        i.dataset.r = String(r);
        i.dataset.c = String(c);
        tablePop.appendChild(i);
      }
    }
    tablePop.addEventListener('mouseover', function (e) {
      var cell = e.target.closest('i');
      if (!cell) return;
      var rr = +cell.dataset.r, cc = +cell.dataset.c;
      tablePop.querySelectorAll('i').forEach(function (el) {
        el.classList.toggle('on', +el.dataset.r <= rr && +el.dataset.c <= cc);
      });
    });
    tablePop.addEventListener('click', function (e) {
      var cell = e.target.closest('i');
      if (!cell) return;
      insertTable(+cell.dataset.r, +cell.dataset.c);
      tablePop.classList.remove('show');
    });
  })();

  function insertTable(rows, cols) {
    beforeEdit();
    var pct = (100 / cols).toFixed(2);
    var colgroup = '<colgroup>';
    for (var c = 0; c < cols; c++) colgroup += '<col style="width:' + pct + '%">';
    colgroup += '</colgroup>';
    var html = '<p><br></p><table class="eap-tsv eap-editable-table" style="width:100%;table-layout:fixed">' + colgroup;
    for (var r = 0; r < rows; r++) {
      html += '<tr>';
      for (var c2 = 0; c2 < cols; c2++) html += '<td style="height:32px">&nbsp;</td>';
      html += '</tr>';
    }
    html += '</table><p><br></p>';
    var after = selectedCell && selectedCell.closest('table');
    if (!after) {
      var sel = window.getSelection();
      var n = sel && sel.rangeCount ? sel.anchorNode : null;
      if (n && n.nodeType === 3) n = n.parentNode;
      if (n && n.closest) after = n.closest('table');
    }
    if (after && editor.contains(after)) after.insertAdjacentHTML('afterend', html);
    else insertHtml(html);
    focusEditor();
    prepareAllTables();
    afterEdit();
    var tables = editor.querySelectorAll('table');
    if (tables.length) {
      var t = tables[tables.length - 1];
      var first = t.querySelector('td, th');
      if (first) selectTableCell(first);
    }
  }

  document.getElementById('imgFile').addEventListener('change', function () {
    var f = this.files && this.files[0];
    this.value = '';
    if (!f) return;
    var reader = new FileReader();
    reader.onload = function () {
      insertHtml('<img src="' + reader.result + '" alt="" style="width:100%;height:auto;max-width:100%">');
      focusEditor();
      fitImages();
      var imgs = editor.querySelectorAll('img');
      if (imgs.length) selectImg(imgs[imgs.length - 1]);
    };
    reader.readAsDataURL(f);
  });

  function toggleFull() {
    var el = document.documentElement;
    if (document.fullscreenElement) document.exitFullscreen();
    else if (el.requestFullscreen) el.requestFullscreen();
  }

  function toggleSource(btn) {
    setSourceMode(!sourceMode, btn);
  }

  function setSourceMode(on, btn) {
    if (on === sourceMode) return;
    sourceMode = on;
    var srcBtn = btn || document.getElementById('btnSource');
    if (srcBtn) srcBtn.classList.toggle('on', sourceMode);
    document.getElementById('tabDesign').classList.toggle('on', !sourceMode);
    document.getElementById('tabHtml').classList.toggle('on', sourceMode);
    document.body.classList.toggle('source-mode', sourceMode);
    if (sourceMode) {
      hideImgBox();
      clearTableSelection();
      source.value = editor.innerHTML;
      source.focus();
    } else {
      editor.innerHTML = source.value;
      fitPage();
      editor.focus();
    }
  }

  document.getElementById('tabDesign').addEventListener('click', function () {
    setSourceMode(false);
  });
  document.getElementById('tabHtml').addEventListener('click', function () {
    setSourceMode(true);
  });
  document.getElementById('btnBackDesign').addEventListener('click', function () {
    setSourceMode(false);
  });

  async function pasteClicked() {
    focusEditor();
    try {
      if (navigator.clipboard && navigator.clipboard.read) {
        var items = await navigator.clipboard.read();
        var html = '', text = '';
        for (var i = 0; i < items.length; i++) {
          var item = items[i];
          if (item.types.indexOf('text/html') >= 0) {
            html = await (await item.getType('text/html')).text();
          }
          if (item.types.indexOf('text/plain') >= 0) {
            text = await (await item.getType('text/plain')).text();
          }
        }
        applyPaste(html, text);
        return;
      }
    } catch (err) {}
    try {
      var plain = await navigator.clipboard.readText();
      applyPaste('', plain);
    } catch (err2) {
      document.execCommand('paste');
    }
  }

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function collectStyles(raw) {
    var out = [];
    raw.replace(/<style[^>]*>([\s\S]*?)<\/style>/gi, function (_, css) {
      out.push(css);
      return '';
    });
    return out;
  }

  function parseCfHtml(raw) {
    var m = raw.match(/StartHTML:(\d+)\s*EndHTML:(\d+)\s*StartFragment:(\d+)\s*EndFragment:(\d+)/);
    if (m) {
      var sh = parseInt(m[1], 10);
      var eh = parseInt(m[2], 10);
      var sf = parseInt(m[3], 10);
      var ef = parseInt(m[4], 10);
      if (eh > sh && eh <= raw.length + 32) {
        return {
          full: raw.substring(sh, Math.min(eh, raw.length)),
          fragment: ef > sf ? raw.substring(sf, Math.min(ef, raw.length)) : ''
        };
      }
    }
    var i = raw.search(/<html/i);
    if (i < 0) i = raw.search(/<table/i);
    var full = i >= 0 ? raw.substring(i) : raw;
    var a = full.indexOf('<!--StartFragment-->');
    var b = full.indexOf('<!--EndFragment-->');
    var fragment = (a >= 0 && b > a)
      ? full.substring(a + '<!--StartFragment-->'.length, b)
      : '';
    if (!fragment) {
      var body = full.match(/<body[^>]*>([\s\S]*)<\/body>/i);
      fragment = body ? body[1] : full;
    }
    return { full: full, fragment: fragment };
  }

  function lightClean(html) {
    html = html.replace(/<xml[\s\S]*?<\/xml>/gi, '');
    html = html.replace(/<\/?(o|v|w|x):[^>]*>/gi, '');
    return html;
  }

  function hasTable(html) {
    return /<table[\s>]/i.test(html || '');
  }

  function sanitizeDom(html, pasteStyles, isExcel) {
    var box = document.createElement('div');
    box.innerHTML = lightClean(html);
    if (isExcel == null && window.eapIsExcelClipboardHtml) {
      isExcel = window.eapIsExcelClipboardHtml(html);
    }
    box.querySelectorAll('script').forEach(function (n) {
      if (n.getAttribute('type') === 'application/eap-form') return;
      n.remove();
    });
    box.querySelectorAll('table').forEach(function (t) {
      if (!isExcel) {
        t.removeAttribute('border');
        t.removeAttribute('rules');
        t.removeAttribute('frame');
      } else {
        t.removeAttribute('cellspacing');
      }
    });
    if (isExcel && window.eapNormalizeExcelPaste) {
      window.eapNormalizeExcelPaste(box, (pasteStyles || []).join('\n'));
    }
    if (window.eapFixDocTables) window.eapFixDocTables(box);
    if (window.eapMigrateDaouHtml) window.eapMigrateDaouHtml(box);
    if (window.eapPrepareImportedHtmlForEdit) {
      window.eapPrepareImportedHtmlForEdit(box, { designMode: true, excelPaste: !!isExcel });
    }
    box.querySelectorAll('*').forEach(function (el) {
      Array.from(el.attributes).forEach(function (attr) {
        var n = attr.name.toLowerCase();
        if (n.indexOf('on') === 0 || (n === 'href' && /^javascript:/i.test(attr.value))) {
          el.removeAttribute(attr.name);
        }
      });
    });
    var tables = Array.prototype.slice.call(box.querySelectorAll('table'));
    var flowTables = tables.filter(function (t) {
      return !/absolute/i.test((t.style && t.style.position) || '');
    });
    if (!isExcel && flowTables.length) {
      box.querySelectorAll('[style*="absolute"], [style*="Absolute"]').forEach(function (el) {
        if (el.tagName === 'TABLE') return;
        if (el.querySelector && el.querySelector('table')) return;
        el.remove();
      });
    } else if (isExcel && window.eapNormalizeExcelPaste) {
      window.eapNormalizeExcelPaste(box, (pasteStyles || []).join('\n'));
    } else {
      box.querySelectorAll('*').forEach(function (el) {
        if (el.style && /absolute/i.test(el.style.position || '')) {
          el.style.position = 'static';
          el.style.left = '';
          el.style.top = '';
        }
      });
    }
    return box.innerHTML;
  }

  function preparePaste(raw) {
    var parsed = parseCfHtml(raw);
    var styles = collectStyles(parsed.full);
    var isExcel = window.eapIsExcelClipboardHtml
      ? window.eapIsExcelClipboardHtml(raw) || styles.some(function (s) { return /mso-/i.test(s); })
      : false;
    var sourceHtml = hasTable(parsed.fragment) ? parsed.fragment
      : hasTable(parsed.full) ? parsed.full
      : (parsed.fragment || parsed.full);
    return { html: sanitizeDom(sourceHtml, styles, isExcel), styles: styles, isExcel: isExcel };
  }

  function tsvToTable(text) {
    var rows = String(text).replace(/\r\n/g, '\n').replace(/\r/g, '\n').split('\n');
    while (rows.length && !rows[rows.length - 1].trim()) rows.pop();
    if (!rows.length) return '';
    var tabbed = rows.some(function (r) { return r.indexOf('\t') >= 0; });
    if (!tabbed) {
      if (rows.length === 1) return '';
      return rows.map(function (r) { return '<p>' + escapeHtml(r) + '</p>'; }).join('');
    }
    var html = '<table class="eap-tsv">';
    rows.forEach(function (row) {
      html += '<tr>';
      row.split('\t').forEach(function (cell) {
        html += '<td>' + escapeHtml(cell) + '</td>';
      });
      html += '</tr>';
    });
    html += '</table>';
    return html;
  }

  function injectStyles(cssList) {
    cssList.forEach(function (css) {
      var s = document.createElement('style');
      s.setAttribute('data-eap-paste', '1');
      s.textContent = window.eapSanitizePasteCss ? window.eapSanitizePasteCss(css) : css;
      document.head.appendChild(s);
    });
  }

  function editorLooksEmpty() {
    if (editor.querySelector('table, img, .eap-widget, .eap-doc-header')) return false;
    var t = editor.innerText.replace(/\u00a0/g, ' ').trim();
    return !t;
  }

  function insertHtml(html) {
    editor.focus();
    if (editorLooksEmpty()) {
      editor.innerHTML = html;
      return;
    }
    var sel = window.getSelection();
    if (!sel || sel.rangeCount === 0) {
      editor.insertAdjacentHTML('beforeend', html);
      return;
    }
    var range = sel.getRangeAt(0);
    var node = range.commonAncestorContainer;
    if (node.nodeType === 3) node = node.parentNode;
    if (!editor.contains(node) && node !== editor) {
      editor.insertAdjacentHTML('beforeend', html);
      return;
    }
    var inCell = node.closest && node.closest('td, th');
    if (inCell && editor.contains(inCell)) {
      var box = document.createElement('div');
      box.innerHTML = html;
      if (box.querySelector('table')) {
        inCell.closest('table').insertAdjacentHTML('afterend', html);
      } else {
        range.deleteContents();
        var frag = document.createDocumentFragment();
        while (box.firstChild) frag.appendChild(box.firstChild);
        range.insertNode(frag);
      }
      return;
    }
    if (node.closest && node.closest('table')) {
      node.closest('table').insertAdjacentHTML('afterend', html);
      return;
    }
    range.deleteContents();
    var wrap = document.createElement('div');
    wrap.innerHTML = html;
    var frag2 = document.createDocumentFragment();
    while (wrap.firstChild) frag2.appendChild(wrap.firstChild);
    range.insertNode(frag2);
  }

  function applyPaste(html, text) {
    if (isMultiCellRange() && text && !hasTable(html || '')) {
      if (text.indexOf('\t') >= 0 || text.indexOf('\n') >= 0) {
        if (pasteGridIntoRange(parsePasteGrid(text))) {
          fitTablesOnPaste(false);
          return;
        }
      } else {
        beforeEdit();
        selectedEditorCells().forEach(function (cell) {
          if (cell.querySelector('.eap-widget, .eap-widget-block')) return;
          cell.innerHTML = escapeHtml(text) || '&nbsp;';
        });
        afterEdit();
        fitTablesOnPaste(false);
        return;
      }
    }
    var cell = activeTableCellFromSelection();
    if (cell && !hasTable(html || '')) {
      if (pasteIntoTableCell(cell, html, text)) {
        fitTablesOnPaste(false);
        fitImages();
        return;
      }
    }
    beforeEdit();
    var built = '';
    var styles = [];
    var isExcel = false;
    if (html && /<[a-z]/i.test(html)) {
      var prepared = preparePaste(html);
      styles = prepared.styles;
      isExcel = !!prepared.isExcel;
      built = prepared.html;
    }
    if (!hasTable(built) && text) {
      var fromTsv = tsvToTable(text);
      if (fromTsv) built = fromTsv;
    }
    if (!built && text) {
      built = '<p>' + escapeHtml(text).replace(/\n/g, '<br>') + '</p>';
    }
    if (!built) return;
    injectStyles(styles);
    insertHtml(built);
    if (isExcel && window.eapNormalizeExcelPaste) {
      window.eapNormalizeExcelPaste(editor, styles.join('\n'));
    }
    fitTablesOnPaste(isExcel);
    fitImages();
    if (window.refreshAllWidgetFaces) window.refreshAllWidgetFaces();
    if (window.eapPrepareImportedHtmlForEdit) {
      window.eapPrepareImportedHtmlForEdit(editor, { designMode: true, excelPaste: isExcel });
    }
    if (formMode) {
      delete editor._eapMileageCalcBound;
      if (window.eapRunFormRuntime) window.eapRunFormRuntime(editor);
    }
    afterEdit();
  }

  function onPaste(e) {
    if (sourceMode) return;
    var clip = e.clipboardData;
    if (!clip) return;
    var html = clip.getData('text/html') || '';
    var text = clip.getData('text/plain') || '';
    if (!html.trim() && !text.trim()) return;
    e.preventDefault();
    e.stopPropagation();
    applyPaste(html, text);
  }

  editor.addEventListener('copy', function (e) {
    if (sourceMode || !shouldApplyCmdToCellSelection()) return;
    var text = selectedCellsToTsv();
    if (!text && text !== '') return;
    e.preventDefault();
    var html = selectedCellsToHtml();
    if (e.clipboardData) {
      e.clipboardData.setData('text/plain', text);
      e.clipboardData.setData('text/html', html);
    } else {
      writeClipboard(text, html).catch(function () {});
    }
  });

  editor.addEventListener('cut', function (e) {
    if (sourceMode || !shouldApplyCmdToCellSelection()) return;
    e.preventDefault();
    cutSelectedCells();
  });

  document.addEventListener('paste', onPaste, true);
  editor.addEventListener('paste', onPaste);

  var htmlFileInput = document.getElementById('htmlFileInput');
  if (htmlFileInput) {
    htmlFileInput.addEventListener('change', function (e) {
      var file = e.target.files && e.target.files[0];
      if (!file) return;
      var reader = new FileReader();
      reader.onload = function () {
        var html = reader.result || '';
        if (sourceMode) {
          source.value = html;
        } else {
          loadEditorHtml(html);
        }
        htmlFileInput.value = '';
      };
      reader.readAsText(file, 'UTF-8');
    });
  }

  window.addEventListener('message', function (e) {
    var d = e.data;
    if (typeof d === 'string') {
      try { d = JSON.parse(d); } catch (err) { return; }
    }
    d = d || {};
    if (d.type === 'eapSetHtml') {
      if (sourceMode) source.value = d.html || '';
      else {
        loadEditorHtml(d.html || '');
        undoStack = [];
        redoStack = [];
        pushHistory();
      }
    }
    if (d.type === 'eapGetHtml') {
      parent.postMessage(JSON.stringify({
        type: 'eapHtml',
        id: d.id,
        html: currentHtml(),
        schema: window.collectFormSchema ? window.collectFormSchema() : []
      }), '*');
    }
    if (d.type === 'eapSetPlaceholder' && d.text) {
      editor.setAttribute('data-placeholder', d.text);
    }
  });

  window.editor = editor;
  window.insertHtml = insertHtml;
  window.focusEditor = focusEditor;
  window.clearTableSelection = clearTableSelection;
  window.clearTableSelectionOnly = clearTableSelectionOnly;
  window.hideImgBox = hideImgBox;
  window.isSourceMode = function () { return sourceMode; };
  window.prepareEditableTable = prepareEditableTable;
  pushHistory();
})();
