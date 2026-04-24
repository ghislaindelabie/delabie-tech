// Generic two-axis filter for any list that opts in via data attributes.
//
// Expected DOM shape, per filtered region:
//
//   <div data-filter-list>
//     <section data-filter-controls>
//       <div class="filter-group" data-group="AXIS_NAME">
//         <button class="filter-pill" data-filter="VALUE" aria-pressed="false">…</button>
//         …
//       </div>
//       <button data-filter-reset hidden>…</button>
//     </section>
//     <ul data-filter-items>
//       <li data-filter-item data-AXIS_NAME_attr="value1 value2" …>…</li>
//       …
//     </ul>
//     <p data-filter-empty hidden>…</p>
//   </div>
//
// Axes are derived from the `data-group` attributes present under
// `data-filter-controls`. For each axis `X`, each item must carry a
// `data-X` attribute holding one or more space-separated values. Within
// an axis the filter is OR; across axes it is AND. Empty axis selection
// means "no constraint".
//
// No dependencies. Safe no-op when the DOM shape is missing.
(function () {
  'use strict';

  function initRoot(root) {
    var controls = root.querySelector('[data-filter-controls]');
    var itemsRoot = root.querySelector('[data-filter-items]');
    if (!controls || !itemsRoot) return;

    var items = Array.prototype.slice.call(itemsRoot.querySelectorAll('[data-filter-item]'));
    var emptyMsg = root.querySelector('[data-filter-empty]');
    var resetBtn = controls.querySelector('[data-filter-reset]');
    var groups = controls.querySelectorAll('[data-group]');
    var axes = {};
    for (var i = 0; i < groups.length; i++) {
      axes[groups[i].getAttribute('data-group')] = new Set();
    }

    function applyFilters() {
      var visible = 0;
      for (var i = 0; i < items.length; i++) {
        var item = items[i];
        var show = true;
        for (var axis in axes) {
          if (!axes[axis].size) continue;
          var raw = item.getAttribute('data-' + axis) || '';
          var values = raw.split(/\s+/).filter(Boolean);
          var hit = false;
          for (var j = 0; j < values.length; j++) {
            if (axes[axis].has(values[j])) { hit = true; break; }
          }
          if (!hit) { show = false; break; }
        }
        item.hidden = !show;
        if (show) visible++;
      }
      if (emptyMsg) emptyMsg.hidden = visible > 0;
      if (resetBtn) {
        var anyActive = false;
        for (var axis in axes) if (axes[axis].size) { anyActive = true; break; }
        resetBtn.hidden = !anyActive;
      }
    }

    controls.addEventListener('click', function (e) {
      var btn = e.target.closest('.filter-pill');
      if (!btn) return;
      var group = btn.closest('[data-group]');
      if (!group) return;
      var axis = group.getAttribute('data-group');
      var value = btn.getAttribute('data-filter');
      if (!axis || !value || !axes[axis]) return;
      if (axes[axis].has(value)) {
        axes[axis].delete(value);
        btn.setAttribute('aria-pressed', 'false');
      } else {
        axes[axis].add(value);
        btn.setAttribute('aria-pressed', 'true');
      }
      applyFilters();
    });

    if (resetBtn) {
      resetBtn.addEventListener('click', function () {
        for (var axis in axes) axes[axis].clear();
        var pills = controls.querySelectorAll('.filter-pill');
        for (var i = 0; i < pills.length; i++) pills[i].setAttribute('aria-pressed', 'false');
        applyFilters();
      });
    }
  }

  var roots = document.querySelectorAll('[data-filter-list]');
  for (var i = 0; i < roots.length; i++) initRoot(roots[i]);
})();
