import assert from 'node:assert';
import { describe, it } from 'node:test';

import {
  PROJECT_NAME_REGEXP,
} from '../src/constants.js';

describe('# Project / Hostname RegExp', () => {
  it('should accept valid names', () => {
    const valid = [
      'coucou1234',
      'coucou_1234',
      'coucou-1234',
    ];

    valid.forEach(str => {
      // console.log(`- "${str}" should be valid`);
      assert.equal(PROJECT_NAME_REGEXP.test(str), true);
    });
  });

  it('should refuse invalid names', () => {
    const invalid = [
      '',
      'Coucou1234',
      'coucou.1234',
      'coucou 1234',
      'hého',
      '$sef',
    ];

    invalid.forEach(str => {
      // console.log(`- "${str}" should be invalid`);
      assert.equal(PROJECT_NAME_REGEXP.test(str), false);
    });
  });
});
