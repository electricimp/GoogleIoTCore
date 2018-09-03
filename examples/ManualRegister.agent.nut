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

class ManualRegisterExample {
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
        local privKeyLoaded = function (err, privKey) {
            if (err != 0) {
                server.log("Private key downloading is failed: " + err);
                return;
            }
            server.log("Private key is loaded");
            _privateKey = privKey;
            _googleIoTCoreClient = GoogleIoTCore.Client(_projectId,
                                                        _cloudRegion,
                                                        _registryId,
                                                        _deviceId,
                                                        _privateKey,
                                                        onConnected.bindenv(this),
                                                        onDisconnected.bindenv(this));

            _googleIoTCoreClient.connect();
        }.bindenv(this);

        server.log("Downloading the private key..");
        downloadKey(_privateKeyUrl, privKeyLoaded);
    }

    function downloadKey(url, callback) {
        local req = http.get(url);
        local sent = null;

        sent = function (resp) {
            if (resp.statuscode / 100 == 3) {
                if (!("location" in resp.headers)) {
                    server.log("Downloading is failed: redirective response does not contain \"location\" header");
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
        server.log("Configuration received: " + config.tostring());
        server.log("Reporting new state..");
        reportState(config);
    }

    function reportState(data) {
        _googleIoTCoreClient.reportState(data, onStateReported.bindenv(this));
    }

    function onStateReported(data, error) {
        if (error != 0) {
            server.error("Report state error: code = " + error);
            return;
        }
        server.log("State has been reported!");
    }

    function onConnected(error) {
        if (error != 0) {
            server.error("Can't connect: " + error);
        } else {
            server.log("Connected successfully!");
            server.log("Enabling configuration updates receiving..");
            _googleIoTCoreClient.enableCfgReceiving(onConfigReceived.bindenv(this), onCfgEnabled.bindenv(this));
        }
    }

    function onCfgEnabled(error) {
        if (error != 0) {
            server.error("Can't enable: " + error);
            return;
        }
        server.log("Successfully enabled!");
    }

    function onDisconnected(error) {
        server.error("Disconnected: " + error);
    }
}

// RUNTIME
// ---------------------------------------------------------------------------------

// GOOGLE IOT CORE CONSTANTS
// ---------------------------------------------------------------------------------
const GOOGLE_IOT_CORE_PROJECT_ID    = "<YOUR_PROJECT_ID>";
const GOOGLE_IOT_CORE_CLOUD_REGION  = "<YOUR_CLOUD_REGION>";
const GOOGLE_IOT_CORE_REGISTRY_ID   = "<YOUR_REGISTRY_ID>";
const GOOGLE_IOT_CORE_DEVICE_ID     = "<YOUR_DEVICE_ID>";

const PRIVATE_KEY_URL = "<YOUR_PRIVATE_KEY_URL>";

// Start Application
googleIoTCore <- ManualRegisterExample(GOOGLE_IOT_CORE_PROJECT_ID,
                                       GOOGLE_IOT_CORE_CLOUD_REGION,
                                       GOOGLE_IOT_CORE_REGISTRY_ID,
                                       GOOGLE_IOT_CORE_DEVICE_ID,
                                       PRIVATE_KEY_URL);
googleIoTCore.start();
