// 전자결재 본문 HTML 미리보기 — 헤더 정리·읽기 전용 flatten
(function (g) {
  function mergeDocHeaders(root) {
    if (!root) return;
    root.querySelectorAll('.eap-doc-title').forEach(function (el) {
      el.className = 'eap-title';
    });
    root.querySelectorAll('.eap-title').forEach(function (title) {
      if (title.closest('.eap-doc-header')) return;
      var h = document.createElement('div');
      h.className = 'eap-doc-header';
      title.parentNode.insertBefore(h, title);
      h.appendChild(title);
    });
    root.querySelectorAll('.eap-approval-line').forEach(function (tbl) {
      if (tbl.closest('.eap-doc-header')) return;
      var prev = tbl.previousElementSibling;
      if (prev && prev.classList.contains('eap-doc-header')) {
        prev.appendChild(tbl);
        return;
      }
      var h = document.createElement('div');
      h.className = 'eap-doc-header';
      tbl.parentNode.insertBefore(h, tbl);
      h.appendChild(tbl);
    });
    var hs = root.querySelectorAll('.eap-doc-header');
    for (var i = 0; i < hs.length - 1; i++) {
      var a = hs[i];
      var b = hs[i + 1];
      if (a.nextElementSibling !== b) continue;
      var aTitle = a.querySelector('.eap-title');
      var bTitle = b.querySelector('.eap-title');
      if (aTitle && !a.querySelector('.eap-approval-line') && b.querySelector('.eap-approval-line')) {
        // a 의 제목이 기본 문구뿐이면 b 의 진짜 제목을 살린다.
        // 예전에는 b 를 통째로 지워서 사용자가 지정한 문서 제목이 사라지고
        // '양식 제목' 만 남았다(편집기 쪽 mergeAdjacentHeaders 와 같은 결함).
        var aTxt = String(aTitle.textContent || '').replace(/ /g, ' ').trim();
        var bTxt = bTitle ? String(bTitle.textContent || '').replace(/ /g, ' ').trim() : '';
        if (bTxt && (aTxt === '' || aTxt === '양식 제목')) {
          aTitle.innerHTML = bTitle.innerHTML;
        }
        a.appendChild(b.querySelector('.eap-approval-line'));
        b.remove();
        i--;
      }
    }
  }

  function ensureTitleWrap(header) {
    if (!header) return;
    var title = header.querySelector('.eap-title');
    if (!title) return;
    var wrap = title.closest('.eap-title-wrap');
    if (!wrap) {
      wrap = document.createElement('div');
      wrap.className = 'eap-title-wrap';
      title.parentNode.insertBefore(wrap, title);
      wrap.appendChild(title);
    }
  }

  function preparePreviewHeaders(root) {
    if (!root) return;
    root.querySelectorAll('.eap-doc-header').forEach(ensureTitleWrap);
  }

  function applyCheckScales(root) {
    if (!root) return;
    root.querySelectorAll('.eap-widget[data-eap-check-scale], .eap-w-checks[data-eap-check-scale]').forEach(function (w) {
      var scale = parseFloat(w.getAttribute('data-eap-check-scale') || '100') / 100;
      var face = w.classList.contains('eap-w-checks') ? w : w.querySelector('.eap-w-checks');
      if (face) face.style.setProperty('--eap-check-scale', String(scale));
    });
  }

  function recoverExcelTables(root) {
    if (!root || !root.querySelectorAll) return false;
    var found = false;
    root.querySelectorAll('table').forEach(function (t) {
      if (t.classList.contains('eap-excel-import') || t.classList.contains('eap-approval-line')) return;
      if (t.classList.contains('eap-form-table') || t.classList.contains('eap-compact-table') || t.classList.contains('eap-product-table')) return;
      if (t.querySelector('.eap-widget, tr.eap-field, .eap-field')) return;
      var hasColgroup = !!t.querySelector('colgroup');
      var hasInlineBorder = !!t.querySelector('td[style*="border"], th[style*="border"]');
      if (hasColgroup && hasInlineBorder) {
        t.classList.add('eap-excel-import');
        found = true;
      }
    });
    return found;
  }

  function prepareExcelTables(root) {
    if (!root || !root.querySelectorAll) return;
    recoverExcelTables(root);
    root.querySelectorAll('table.eap-excel-import').forEach(function (t) {
      if (g.eapTrimExcelTableGrid) g.eapTrimExcelTableGrid(t);
      if (g.eapPreserveExcelColWidths) g.eapPreserveExcelColWidths(t);
      if (g.eapEnsureExcelColumnsFitContent) g.eapEnsureExcelColumnsFitContent(t);
      if (g.eapRelaxExcelCellWidths) g.eapRelaxExcelCellWidths(t);
    });
  }

  function initFormFillLayout(opts) {
    opts = opts || {};
    var root = opts.root || document.querySelector('.eap-a4');
    if (!root) return;
    mergeDocHeaders(root);
    preparePreviewHeaders(root);
    prepareExcelTables(root);
    root.querySelectorAll('table.eap-excel-import').forEach(function (t) {
      if (g.eapTrimExcelTableGrid) g.eapTrimExcelTableGrid(t);
      if (g.eapPreserveExcelColWidths) g.eapPreserveExcelColWidths(t);
      if (g.eapEnsureExcelColumnsFitContent) g.eapEnsureExcelColumnsFitContent(t);
      if (g.eapRelaxExcelCellWidths) g.eapRelaxExcelCellWidths(t);
    });
    applyCheckScales(root);
    if (g.eapPrepareFormFillTables) g.eapPrepareFormFillTables(root);
    else if (g.eapFixDocTables) g.eapFixDocTables(root);
  }

  function initPreview(opts) {
    opts = opts || {};
    var root = opts.root || document.querySelector('.eap-a4') || document.body;
    if (!root) return;
    mergeDocHeaders(root);
    preparePreviewHeaders(root);
    prepareExcelTables(root);
    var hasExcel = root.querySelector('table.eap-excel-import');
    if (g.eapFixDocTables) {
      g.eapFixDocTables(root, {});
    }
    applyCheckScales(root);
    if (opts.readOnly && g.eapFlattenFormControls) g.eapFlattenFormControls(root);
  }

  function boot() {
    var body = document.body;
    if (body.classList.contains('eap-form-fill-host')) return;
    initPreview({ readOnly: body.getAttribute('data-readonly') === '1' });
  }

  g.eapInitPreview = initPreview;
  g.eapInitFormFillLayout = initFormFillLayout;
  g.eapPrepareExcelTables = prepareExcelTables;
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', boot);
  } else {
    boot();
  }
})(typeof window !== 'undefined' ? window : this);
