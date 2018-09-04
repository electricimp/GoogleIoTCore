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

// GoogleIoTCore library example:
// - downloads a private key using the provided URL
// - connects to Google IoT Core using the private key and the other provided credentials
// - enables Configuration updates receiving
// - receives and logs notifications when Configuration is updated
// - sends the Configuration value as a device state

// An error code to send to the imp-device when we can't connect
const ERROR_CANNOT_CONNECT = 1;
// An error code to send to the imp-device when we can't download a private key
const ERROR_CANNOT_GET_PRIVATE_KEY = 1;
// Delay (in seconds) betweent reconnect attempts
const DELAY_RECONNECT = 5;

class CfgStateExample {
    _googleIoTCoreClient = null;

    _projectId = null;
    _cloudRegion = null;
    _registryId = null;
    _deviceId = null;
    _privateKey = null;

    _privateKeyUrl = null;

    constructor(projectId,
                cloudRegion,
                registryId,
                deviceId,
                privateKeyUrl) {
        _projectId = projectId;
        _cloudRegion = cloudRegion;
        _registryId = registryId;
        _deviceId = deviceId;
        _privateKeyUrl = privateKeyUrl;
    }

    function start() {
        local privKeyLoaded = function (err) {
            if (err != 0) {
                // You can report to the imp-device about an important error
                signalToDevice("error", ERROR_CANNOT_GET_PRIVATE_KEY);
                return;
            }
            _googleIoTCoreClient = GoogleIoTCore.Client(_projectId,
                                                        _cloudRegion,
                                                        _registryId,
                                                        _deviceId,
                                                        _privateKey,
                                                        onConnected.bindenv(this),
                                                        onDisconnected.bindenv(this));

            _googleIoTCoreClient.connect();
        }.bindenv(this);

        getPrivateKey(privKeyLoaded);
    }

    function getPrivateKey(callback) {
        // You can store (with server.save(), for example) the key after it is downloaded
        // and then it can be loaded from the persistent storage
        // But here we download the key every time

        log("Downloading the private key..");
        local downloaded = function (err, data) {
            if (err != 0) {
                logError("Private key downloading is failed: " + err);
            } else {
                log("Private key is loaded");
                _privateKey = data;
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
                    logError("Downloading is failed: redirective response does not contain \"location\" header");
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

    function onConfigReceived(config) {
        log("Configuration received: " + config.tostring());
        log("Reporting new state..");
        signalToDevice("new_configuration", config)
    }

    function reportState(data) {
        _googleIoTCoreClient.reportState(data, onStateReported.bindenv(this));
    }

    function onStateReported(data, error) {
        if (error != 0) {
            // Here you can handle received error code
            logError("Report state error: code = " + error);
            return;
        }
        log("State has been reported!");
    }

    function onConnected(error) {
        if (error != 0) {
            logError("Can't connect: " + error);
            // You can report to the imp-device about an important error
            signalToDevice("error", ERROR_CANNOT_CONNECT);
            // Wait and try to connect again
            log("Trying to connect again..");
            imp.wakeup(DELAY_RECONNECT, _googleIoTCoreClient.connect.bindenv(_googleIoTCoreClient));
        } else {
            log("Connected successfully!");
            log("Enabling configuration updates receiving..");
            _googleIoTCoreClient.enableCfgReceiving(onConfigReceived.bindenv(this), onCfgEnabled.bindenv(this));
        }
    }

    function onCfgEnabled(error) {
        if (error != 0) {
            // Here you can handle received error code
            // For example, if it is an MQTT-specific error, you can just try again or reconnect and then try again
            logError("Can't enable: " + error);
            return;
        }
        log("Successfully enabled!");
    }

    function onDisconnected(error) {
        log("Disconnected: " + error);
        if (error != 0) {
            // Wait and reconnect if it was an unexpected disconnection
            log("Trying to reconnect..");
            imp.wakeup(DELAY_RECONNECT, _googleIoTCoreClient.connect.bindenv(_googleIoTCoreClient));
        }
    }

    function signalToDevice(type, data) {
        // You can send some signal to the imp-device
        // This signal may contain some information about agent's state and according to this signal
        // the imp-device can report to a customer about an error or something else

        // "type" parameter can be, for example, "error", "new_configuration", ...

        // device.send(type, data);

        // Here we imitate sending of a configuration update to the imp-device
        // and then we imitate receiving of a state from the imp-device. This state is actually that configuration
        if (type == "new_configuration") {
            newStateFromDevice(data);
        }
    }

    // This is a stub for receiving state updates from the imp-device
    function newStateFromDevice(state) {
        reportState(state);
    }

    function log(text) {
        server.log(text);
        // Here you can send your logs to some server/cloud/etc.
    }

    function logError(text) {
        server.error(text);
        // Here you can send your error logs to some server/cloud/etc.
    }
}

// RUNTIME
// ---------------------------------------------------------------------------------

// GOOGLE IOT CORE CONSTANTS
// ---------------------------------------------------------------------------------

// Values for these constants can be obtained from outside instead of hardcoding
const GOOGLE_IOT_CORE_PROJECT_ID    = "<YOUR_PROJECT_ID>";
const GOOGLE_IOT_CORE_CLOUD_REGION  = "us-central1";
const GOOGLE_IOT_CORE_REGISTRY_ID   = "example-registry";
const GOOGLE_IOT_CORE_DEVICE_ID     = "example-device_2";

const PRIVATE_KEY_URL = "<YOUR_PRIVATE_KEY_URL>";

// Start Application
googleIoTCore <- CfgStateExample(GOOGLE_IOT_CORE_PROJECT_ID,
                                 GOOGLE_IOT_CORE_CLOUD_REGION,
                                 GOOGLE_IOT_CORE_REGISTRY_ID,
                                 GOOGLE_IOT_CORE_DEVICE_ID,
                                 PRIVATE_KEY_URL);
googleIoTCore.start();
