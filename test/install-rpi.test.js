import installRpi from '../src/install-rpi.js';

const mocks = {
  projectName: 'getting-started',
  instanceNumber: 12,
};

await installRpi(mocks);
