'use strict';

const fs = require('node:fs');

function decodeXmlAttribute(value) {
  return value
    .replace(/&quot;/g, '"')
    .replace(/&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&');
}

function clickableBoundsForText(xml, targetText) {
  const stack = [];
  const nodeTags = xml.matchAll(/<node\b[^>]*\/?>|<\/node>/g);

  for (const match of nodeTags) {
    const tag = match[0];
    if (tag.startsWith('</')) {
      stack.pop();
      continue;
    }

    const attributes = Object.fromEntries(
      [...tag.matchAll(/([\w:-]+)="([^"]*)"/g)].map((attribute) => [
        attribute[1],
        decodeXmlAttribute(attribute[2]),
      ]),
    );
    const node = { attributes, parent: stack.at(-1) ?? null };

    if (attributes.text === targetText) {
      let clickable = node;
      while (clickable && clickable.attributes.clickable !== 'true') {
        clickable = clickable.parent;
      }
      if (!clickable) return null;

      const coordinates = [...(clickable.attributes.bounds ?? '').matchAll(/\d+/g)]
        .map((coordinate) => Number(coordinate[0]));
      if (coordinates.length !== 4) return null;
      return [
        Math.floor((coordinates[0] + coordinates[2]) / 2),
        Math.floor((coordinates[1] + coordinates[3]) / 2),
      ];
    }

    if (!tag.endsWith('/>')) stack.push(node);
  }

  return null;
}

if (require.main === module) {
  const title = process.argv[2];
  if (!title) {
    console.error('Usage: node notification_bounds.js <notification-title>');
    process.exit(2);
  }

  const xml = fs.readFileSync(0, 'utf8');
  const coordinates = clickableBoundsForText(xml, title);
  if (!coordinates) process.exit(1);
  process.stdout.write(`${coordinates[0]} ${coordinates[1]}\n`);
}

module.exports = { clickableBoundsForText };
