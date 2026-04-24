// Teaching page filter logic. Two independent multi-select axes.
// Within an axis: OR. Across axes: AND.
// Vanilla JS, no dependencies. Graceful no-op if the page shape is missing.
(function () {
  'use strict';

  var filterSection = document.querySelector('[data-test="teaching-filters"]');
  var list = document.querySelector('[data-test="teaching-list"]');
  if (!filterSection || !list) return;

  var items = Array.prototype.slice.call(list.querySelectorAll('[data-test="teaching-item"]'));
  var emptyMsg = document.querySelector('[data-test="teaching-empty"]');
  var resetBtn = filterSection.querySelector('[data-test="teaching-filter-reset"]');
  var active = { theme: new Set(), format: new Set() };

  function applyFilters() {
    var visible = 0;
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      var itemThemes = (item.getAttribute('data-themes') || '').split(/\s+/).filter(Boolean);
      var itemFormat = item.getAttribute('data-format') || '';
      var themeOk = active.theme.size === 0 || itemThemes.some(function (x) { return active.theme.has(x); });
      var formatOk = active.format.size === 0 || active.format.has(itemFormat);
      var show = themeOk && formatOk;
      item.hidden = !show;
      if (show) visible++;
    }
    if (emptyMsg) emptyMsg.hidden = visible > 0;
    if (resetBtn) resetBtn.hidden = active.theme.size === 0 && active.format.size === 0;
  }

  filterSection.addEventListener('click', function (e) {
    var btn = e.target.closest('.filter-pill');
    if (!btn) return;
    var group = btn.closest('.filter-group');
    if (!group) return;
    var axis = group.getAttribute('data-group');
    var value = btn.getAttribute('data-filter');
    if (!axis || !value || !active[axis]) return;
    if (active[axis].has(value)) {
      active[axis].delete(value);
      btn.setAttribute('aria-pressed', 'false');
    } else {
      active[axis].add(value);
      btn.setAttribute('aria-pressed', 'true');
    }
    applyFilters();
  });

  if (resetBtn) {
    resetBtn.addEventListener('click', function () {
      active.theme.clear();
      active.format.clear();
      var pills = filterSection.querySelectorAll('.filter-pill');
      for (var i = 0; i < pills.length; i++) pills[i].setAttribute('aria-pressed', 'false');
      applyFilters();
    });
  }
})();
