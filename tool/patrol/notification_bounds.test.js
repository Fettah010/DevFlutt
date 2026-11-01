'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');

const { clickableBoundsForText } = require('./notification_bounds.js');

test('finds the clickable notification ancestor and returns its center', () => {
  const xml = '<hierarchy><node clickable="true" bounds="[10,20][110,220]">' +
    '<node text="Tap &amp; open" clickable="false" bounds="[20,30][90,60]" />' +
    '</node></hierarchy>';

  assert.deepEqual(clickableBoundsForText(xml, 'Tap & open'), [60, 120]);
});

test('returns null when notification text is absent', () => {
  assert.equal(clickableBoundsForText('<hierarchy />', 'Missing'), null);
});

test('returns null when the matching text has no clickable ancestor', () => {
  assert.equal(
    clickableBoundsForText('<hierarchy><node text="Not clickable" /></hierarchy>', 'Not clickable'),
    null,
  );
});
