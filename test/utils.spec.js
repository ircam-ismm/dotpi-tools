import assert from 'node:assert';
import { describe, it } from 'node:test';

import { readBashArray, readBashVariable, packageVersion } from '../js/utils.js';

describe('# utils', () => {
  it('packageVersion()', () => {
    const version = packageVersion();
    console.log('package version:', version);
    assert.equal(typeof version, 'string');
  });

  it('readBashVariable()', () => {
    const value = readBashVariable('dotpi_audio_device');
    assert.equal(value, 'default');
  });

  it('readBashArray()', () => {
    const arr = readBashArray('dotpi_audio_device_supported');
    assert.deepEqual(arr, [
      'default',
      'none',
      'headphones',
      'hifiberry dac+ adc pro',
      'hifiberry dac+ adc',
      'hifiberry dac+ standard',
      'hifiberry dac+ light',
      'hifiberry dac zero',
      'hifiberry miniamp',
      'hifiberry beocreate',
      'hifiberry dac+ dsp',
      'hifiberry dac+ rtc',
      'hifiberry pro',
      'hifiberry amp2',
      'hifiberry dac2 hd',
      'hifiberry digi+',
      'hifiberry digi+ pro',
      'hifiberry amp+',
      'hifiberry amp3',
      'bluetooth',
      'ue boom 2',
      'ue boom 3',
      'ue megaboom 2',
      'ue megaboom 3',
      'hifiberry dac for raspberry pi 1'
    ]);
  });
});
