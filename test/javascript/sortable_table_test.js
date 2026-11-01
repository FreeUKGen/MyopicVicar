'use strict';

var assert = require('assert');
var SortableTable = require('../../app/assets/javascripts/sortable_table');

function test(name, callback) {
  try {
    callback();
    console.log('PASS ' + name);
  } catch (error) {
    console.error('FAIL ' + name);
    throw error;
  }
}

function element(attributes) {
  return {
    attributes: attributes || {},
    children: [],
    listeners: {},
    getAttribute: function(name) {
      return Object.prototype.hasOwnProperty.call(this.attributes, name) ? this.attributes[name] : null;
    },
    setAttribute: function(name, value) { this.attributes[name] = value; },
    appendChild: function(child) { this.children.push(child); },
    addEventListener: function(name, callback) { this.listeners[name] = callback; },
    querySelector: function(selector) {
      if (selector === '.sortable-table__indicator') return this.children[0];
      return null;
    }
  };
}

function sortableFixture(values, type) {
  var document = {
    createElement: function() { return element(); }
  };
  var heading = element({ 'data-sort-type': type });
  heading.cellIndex = 0;
  heading.ownerDocument = document;

  var rows = values.map(function(value, index) {
    var cell = element();
    cell.textContent = value;
    return { id: index, cells: [cell] };
  });
  var body = {
    rows: rows,
    appendChild: function(row) {
      this.rows.splice(this.rows.indexOf(row), 1);
      this.rows.push(row);
    }
  };
  var table = {
    tBodies: [body],
    querySelectorAll: function() { return [heading]; }
  };

  return { sorter: new SortableTable(table), heading: heading, body: body };
}

test('sorts text without regard to case', function() {
  assert.strictEqual(SortableTable.compareValues('Acle', 'briston', 'text'), -1);
  assert.strictEqual(SortableTable.compareValues('acle', 'Acle', 'text'), 0);
});

test('sorts formatted numbers numerically', function() {
  assert.strictEqual(SortableTable.compareValues('2', '10', 'number'), -1);
  assert.strictEqual(SortableTable.compareValues('1,200', '300', 'number'), 1);
});

test('sorts displayed dates chronologically', function() {
  assert.strictEqual(SortableTable.compareValues('7 Aug 1805', '12 Jan 1810', 'date'), -1);
  assert.strictEqual(SortableTable.compareValues('2025-02-01', '2024-12-31', 'date'), 1);
});

test('puts blank and invalid typed values after valid values', function() {
  assert.strictEqual(SortableTable.compareValues('', 'Acle', 'text'), 1);
  assert.strictEqual(SortableTable.compareValues('unknown', '10', 'number'), 1);
  assert.strictEqual(SortableTable.compareValues('', '', 'date'), 0);
});

test('reorders rows ascending and then descending', function() {
  var fixture = sortableFixture(['10', '', '2'], 'number');

  fixture.heading.listeners.dblclick();
  assert.deepStrictEqual(fixture.body.rows.map(function(row) { return row.id; }), [2, 0, 1]);
  assert.strictEqual(fixture.heading.getAttribute('aria-sort'), 'ascending');

  fixture.heading.listeners.dblclick();
  assert.deepStrictEqual(fixture.body.rows.map(function(row) { return row.id; }), [0, 2, 1]);
  assert.strictEqual(fixture.heading.getAttribute('aria-sort'), 'descending');
});

test('supports keyboard sorting and exposes an instruction', function() {
  var fixture = sortableFixture(['Briston', 'acle'], 'text');
  var prevented = false;

  fixture.heading.listeners.keydown({
    key: 'Enter',
    preventDefault: function() { prevented = true; }
  });

  assert.strictEqual(prevented, true);
  assert.deepStrictEqual(fixture.body.rows.map(function(row) { return row.id; }), [1, 0]);
  assert.strictEqual(fixture.heading.getAttribute('tabindex'), '0');
  assert.strictEqual(fixture.heading.getAttribute('title'), 'Double-click or press Enter to sort');
});
