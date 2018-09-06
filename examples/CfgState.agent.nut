// MIT License
//
// Copyright 2018 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.


#require "GoogleIoTCore.agent.lib.nut:1.0.0"

// This is an example of a more production oriented application.
// It has a design which may be used in a real production code, includes additional comments with production-related hints.

// This application:

// - Assumes a device is already registered in the Google IoT Core platform, eg. by a production server.
// - Uses the minimum settings required for the application initialization.
// - After the first start, downloads the application settings, eg. from the production server,
//   which URL is pre-hardcoded in the application (for the simplicity, only a private key is downloaded from the URL but all other settings are hardcoded).
//   After the first initialization all settings may be stored in the imp-agent and after the application restart downloaded from the store (not implemented for the simplicity).
// - Connects to the Google IoT Core.
// - Enables "Configuration updates receiving" feature.
// - When a new Configuration is received from the Google IoT Core, sends it to the imp-device and waits for a new state from the imp-device.
//   When the new state is received from the imp-device, reports it as the device state to the Google IoT Core (for the simplicity, a real communication with the imp-device is not implemented).
// - Logs all errors and other significant events to the production server or other logging utility (for the simplicity, logs to the imp log stream).
//   Signals some of the errors to the imp-device, eg. to display them (a real communication with the imp-device is not implemented).


// GOOGLE IOT CORE CONSTANTS
// ---------------------------------------------------------------------------------

// Values for these constants can be obtained from outside instead of hardcoding
const GOOGLE_IOT_CORE_PROJECT_ID    = "<YOUR_PROJECT_ID>";
const GOOGLE_IOT_CORE_CLOUD_REGION  = "us-central1";
const GOOGLE_IOT_CORE_REGISTRY_ID   = "example-registry";
const GOOGLE_IOT_CORE_DEVICE_ID     = "example-device_2";

const PRIVATE_KEY_URL = "<YOUR_PRIVATE_KEY_URL>";

// ---------------------------------------------------------------------------------

// An error code to send to the imp-device when we can't connect
const ERROR_CANNOT_CONNECT = 1;
// An error code to send to the imp-device when we can't download a private key
const ERROR_CANNOT_INIT_SETTINGS = 1;
// Delay (in seconds) betweent reconnect attempts
const DELAY_RECONNECT = 5;

// You can add more log levels, like DEBUG, WARNING
enum LOG_LEVEL {
    INFO,
    ERROR
}

CfgStateExample <- {

    // Here you can make a multi-level logger
    log = function (text, level = LOG_LEVEL.INFO) {
        if (level == LOG_LEVEL.INFO) server.log("[CfgStateExample] " + text);
        else if (level == LOG_LEVEL.ERROR) server.error("[CfgStateExample] " + text);
        // Logs can be sent to some server/cloud/etc.
    }

    // This class is responsible for getting of application settings including credentials
    AppSettings = class {
        projectId   = null;
        cloudRegion = null;
        registryId  = null;
        deviceId    = null;
        privateKey  = null;

        _privateKeyUrl = null;

        function init(callback) {
            projectId = GOOGLE_IOT_CORE_PROJECT_ID;
            cloudRegion = GOOGLE_IOT_CORE_CLOUD_REGION;
            registryId = GOOGLE_IOT_CORE_REGISTRY_ID;
            deviceId = GOOGLE_IOT_CORE_DEVICE_ID;
            _privateKeyUrl = PRIVATE_KEY_URL;
            getPrivateKey(callback);
        }

        function getPrivateKey(callback) {
            // You can store (with server.save(), for example) the key after it is downloaded
            // and then it can be loaded from the persistent storage
            // But here we download the key every time

            CfgStateExample.log("Downloading the private key..");
            local downloaded = function (err, data) {
                if (err != 0) {
                    CfgStateExample.log("Private key downloading is failed: " + err, LOG_LEVEL.ERROR);
                } else {
                    CfgStateExample.log("Private key is loaded");
                    privateKey = data;
                }
                callback(err);
            }.bindenv(this);
            downloadFile(_privateKeyUrl, downloaded);
        }

        function downloadFile(url, callback) {
            local req = http.get(url);
            local sent = null;

            sent = function (resp) {
                if (resp.statuscode / 100 == 3) {
                    if (!("location" in resp.headers)) {
                        CfgStateExample.log("Downloading is failed: redirective response does not contain \"location\" header", LOG_LEVEL.ERROR);
                        callback(resp.statuscode, null);
                        return;
                    }
                    req = http.get(resp.headers.location);
                    req.sendasync(sent);
                } else if (resp.statuscode / 100 == 2) {
                    callback(0, resp.body);
                } else {
                    callback(resp.statuscode, null);
                }
            }.bindenv(this);

            req.sendasync(sent);
        }
    }

    // This class is responsible for communication with the imp-device
    DeviceCommunicator = class {
        _stateHandler = null;

        function init() {
            // device.on("state", _onStateReceived);
        }

        function sendError(error) {
            // You can send a signal to the imp-device about occured errors
            // According to this signal the imp-device can report to a customer about an error

            // device.send("error", error);
        }

        function sendConfiguration(config) {
            // Here you can prepare and send configuration updates to the imp-device
            // The imp-device can react on that by sending some singals to its hardware

            // device.send("config", config);

            // Here we imitate sending of a configuration update to the imp-device
            // and then we imitate receiving of a state from the imp-device. This state is actually that configuration
            _onStateReceived(config);
        }

        function setStateHandler(handler) {
            _stateHandler = handler;
        }

        function _onStateReceived(state) {
            // Here you can make some preprocessing of the received state and pass it in to the App's handler

            _stateHandler && _stateHandler(state);
        }
    }

    // This class implements the business-logic of the application
    App = class {
        _googleIoTCoreClient = null;
        _appSettings         = null;
        _deviceCommunicator  = null;

        function start() {
            _appSettings = CfgStateExample.AppSettings();
            _deviceCommunicator = CfgStateExample.DeviceCommunicator();

            local settingsLoaded = function (err) {
                if (err != 0) {
                    // You can report to the imp-device about an important error
                    _deviceCommunicator.sendError(ERROR_CANNOT_INIT_SETTINGS);
                    return;
                }
                initApp();
            }.bindenv(this);

            _appSettings.init(settingsLoaded);
        }

        function initApp() {
            _googleIoTCoreClient = GoogleIoTCore.Client(_appSettings.projectId,
                                                        _appSettings.cloudRegion,
                                                        _appSettings.registryId,
                                                        _appSettings.deviceId,
                                                        _appSettings.privateKey,
                                                        onConnected.bindenv(this),
                                                        onDisconnected.bindenv(this));

            _googleIoTCoreClient.connect();

            // We want to report all state updates to the Google IoT Core cloud
            _deviceCommunicator.setStateHandler(reportState.bindenv(this));

            // Here you can initialize your application specific objects
        }

        function onConfigReceived(config) {
            CfgStateExample.log("Configuration received: " + config.tostring());
            // Here you can do some actions according to the configuration received
            // We will simply send the configuration to the imp-device
            _deviceCommunicator.sendConfiguration(config);
        }

        function reportState(data) {
            CfgStateExample.log("Reporting new state..");
            _googleIoTCoreClient.reportState(data, onStateReported.bindenv(this));
        }

        function onStateReported(data, error) {
            if (error != 0) {
                // Here you can handle received error code
                CfgStateExample.log("Report state error: code = " + error, LOG_LEVEL.ERROR);
                return;
            }
            CfgStateExample.log("State has been reported!");
        }

        function onConnected(error) {
            if (error != 0) {
                CfgStateExample.log("Can't connect: " + error, LOG_LEVEL.ERROR);
                // You can report to the imp-device about an important error
                _deviceCommunicator.sendError(ERROR_CANNOT_CONNECT);
                // Wait and try to connect again
                CfgStateExample.log("Trying to connect again..");
                imp.wakeup(DELAY_RECONNECT, _googleIoTCoreClient.connect.bindenv(_googleIoTCoreClient));
            } else {
                CfgStateExample.log("Connected successfully!");
                CfgStateExample.log("Enabling configuration updates receiving..");
                _googleIoTCoreClient.enableCfgReceiving(onConfigReceived.bindenv(this), onCfgEnabled.bindenv(this));
            }
        }

        function onCfgEnabled(error) {
            if (error != 0) {
                // Here you can handle received error code
                // For example, if it is an MQTT-specific error, you can just try again or reconnect and then try again
                CfgStateExample.log("Can't enable configuration receiving: " + error, LOG_LEVEL.ERROR);
                return;
            }
            CfgStateExample.log("Successfully enabled!");
        }

        function onDisconnected(error) {
            CfgStateExample.log("Disconnected: " + error);
            if (error != 0) {
                // Wait and reconnect if it was an unexpected disconnection
                CfgStateExample.log("Trying to reconnect..");
                imp.wakeup(DELAY_RECONNECT, _googleIoTCoreClient.connect.bindenv(_googleIoTCoreClient));
            }
        }
    }
}

// RUNTIME
// ---------------------------------------------------------------------------------

// Start Application
cfgStateExample <- CfgStateExample.App();
cfgStateExample.start();
