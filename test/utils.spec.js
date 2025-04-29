import assert from 'node:assert';
import { describe, it } from 'node:test';

import { readBashArray, readBashVariable, packageVersion } from '../src/utils.js';

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
      'bluetooth',
      'hifiberry amp+',
      'hifiberry amp2',
      'hifiberry amp3',
      'hifiberry amp4 pro',
      'hifiberry amp4',
      'hifiberry beocreate',
      'hifiberry dac for raspberry pi 1',
      'hifiberry dac zero',
      'hifiberry dac+ adc pro',
      'hifiberry dac+ adc',
      'hifiberry dac+ dsp',
      'hifiberry dac+ light',
      'hifiberry dac+ rtc',
      'hifiberry dac+ standard',
      'hifiberry dac2 hd',
      'hifiberry digi+ pro',
      'hifiberry digi+',
      'hifiberry miniamp',
      'hifiberry pro',
      'ue boom 2',
      'ue boom 3',
      'ue megaboom 2',
      'ue megaboom 3',
    ]);
  });
});
