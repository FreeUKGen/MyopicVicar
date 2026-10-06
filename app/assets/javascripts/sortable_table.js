(function(root, factory) {
  var SortableTable = factory();

  if (typeof module === 'object' && module.exports) {
    module.exports = SortableTable;
  }

  if (root) {
    root.SortableTable = SortableTable;
  }
})(typeof window !== 'undefined' ? window : null, function() {
  'use strict';

  var MONTHS = {
    jan: 0, feb: 1, mar: 2, apr: 3, may: 4, jun: 5,
    jul: 6, aug: 7, sep: 8, oct: 9, nov: 10, dec: 11
  };

  function textValue(cell) {
    var explicitValue = cell.getAttribute('data-sort-value');
    return (explicitValue === null ? cell.textContent : explicitValue).trim();
  }

  function numberValue(value) {
    var number = Number(value.replace(/,/g, ''));
    return Number.isNaN(number) ? null : number;
  }

  function dateValue(value) {
    var isoDate = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
    if (isoDate) {
      return Date.UTC(Number(isoDate[1]), Number(isoDate[2]) - 1, Number(isoDate[3]));
    }

    var displayedDate = /^(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})$/.exec(value);
    if (displayedDate) {
      var month = MONTHS[displayedDate[2].toLowerCase()];
      if (month !== undefined) {
        return Date.UTC(Number(displayedDate[3]), month, Number(displayedDate[1]));
      }
    }

    return null;
  }

  function typedValue(value, type) {
    if (value === '') return null;
    if (type === 'number') return numberValue(value);
    if (type === 'date') return dateValue(value);
    return value.toLocaleLowerCase();
  }

  function compareValues(left, right, type) {
    var leftValue = typedValue(left, type);
    var rightValue = typedValue(right, type);

    if (leftValue === null && rightValue === null) return 0;
    if (leftValue === null) return 1;
    if (rightValue === null) return -1;
    if (leftValue < rightValue) return -1;
    if (leftValue > rightValue) return 1;
    return 0;
  }

  function SortableTable(table) {
    this.table = table;
    this.headings = Array.prototype.slice.call(
      table.querySelectorAll('thead th[data-sort-type]')
    );
    this.bindHeadings();
  }

  SortableTable.prototype.bindHeadings = function() {
    var sortableTable = this;

    this.headings.forEach(function(heading) {
      heading.setAttribute('aria-sort', 'none');
      heading.setAttribute('tabindex', '0');
      heading.setAttribute('title', 'Double-click or press Enter to sort');

      var indicator = heading.ownerDocument.createElement('span');
      indicator.className = 'sortable-table__indicator';
      indicator.setAttribute('aria-hidden', 'true');
      indicator.textContent = ' ⇅';
      heading.appendChild(indicator);

      heading.addEventListener('dblclick', function() {
        sortableTable.sortBy(heading);
      });
      heading.addEventListener('keydown', function(event) {
        if (event.key === 'Enter' || event.key === ' ') {
          event.preventDefault();
          sortableTable.sortBy(heading);
        }
      });
    });
  };

  SortableTable.prototype.sortBy = function(heading) {
    var direction = heading.getAttribute('aria-sort') === 'ascending' ? 'descending' : 'ascending';
    var columnIndex = heading.cellIndex;
    var type = heading.getAttribute('data-sort-type');
    var multiplier = direction === 'ascending' ? 1 : -1;

    Array.prototype.slice.call(this.table.tBodies).forEach(function(body) {
      var rows = Array.prototype.slice.call(body.rows).map(function(row, index) {
        return { row: row, originalIndex: index };
      });

      rows.sort(function(left, right) {
        var leftText = textValue(left.row.cells[columnIndex]);
        var rightText = textValue(right.row.cells[columnIndex]);
        var comparison = compareValues(leftText, rightText, type);

        // Empty or invalid values stay at the end in either direction.
        if (typedValue(leftText, type) === null || typedValue(rightText, type) === null) {
          return comparison || left.originalIndex - right.originalIndex;
        }

        return (comparison * multiplier) || left.originalIndex - right.originalIndex;
      });

      rows.forEach(function(item) { body.appendChild(item.row); });
    });

    this.headings.forEach(function(item) {
      var active = item === heading;
      item.setAttribute('aria-sort', active ? direction : 'none');
      item.querySelector('.sortable-table__indicator').textContent = active ?
        (direction === 'ascending' ? ' \u25b2' : ' \u25bc') : ' ⇅';
    });
  };

  SortableTable.compareValues = compareValues;
  SortableTable.typedValue = typedValue;

  SortableTable.initialize = function(documentRoot) {
    Array.prototype.slice.call(documentRoot.querySelectorAll('table.js-sortable-table')).forEach(function(table) {
      if (table.getAttribute('data-sortable-table-initialized') === 'true') return;
      table.setAttribute('data-sortable-table-initialized', 'true');
      new SortableTable(table);
    });
  };

  return SortableTable;
});

if (typeof document !== 'undefined') {
  document.addEventListener('DOMContentLoaded', function() {
    window.SortableTable.initialize(document);
  });
  document.addEventListener('turbolinks:load', function() {
    window.SortableTable.initialize(document);
  });
}
