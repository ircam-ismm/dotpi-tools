
import { greetings } from '../src/utils.js';
import {
  prepareProject,
  configureProject,
  configureSSH,
  configureWiFi,
  injectUtilityFiles,
  persistProject,
} from '../src/create-project.js';

// must match the order of the questions
const prepareProject = {
  projectName: 'coucou',
  password: 'my-password',
};

const configureProjectMocks = {
  soundcard: 'hifiberry dac+ adc pro',
  nodeVersion: 'lts',
  timeZone: 'Europe/Paris',
  keyMap: 'fr',
  installDotpiManager: true,
  installDotpiLed: false,
};

const sshMocks = {
  createOrResuse: 'create',
}

const configureWifiInfraMocks = {
  wifiId: 'test_infra',
  wifiMode: 'infrastructure',
  wifiSsid: 'INFRA_SSID',
  wifiPsk: 'INFRA_PASSWD',
  wifiPriority: 12,
  createAnotherConnection: false,
}

const configureWifiAPMocks = {
  wifiId: 'test_ap',
  wifiMode: 'ap',
  wifiSsid: 'AP_SSID',
  wifiPsk: 'PS_PASSWD',
  createAnotherConnection: false,
}

// greetings();
const data = {};
await prepareProject(data, prepareMocks);
// await configureProject(data);
// await configureSSH(data);
// await configureWiFi(data, configureWifiAPMocks);
await injectUtilityFiles(data);
// await persistProject(data);
console.log(data);
