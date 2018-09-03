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
#require "OAuth2.agent.lib.nut:2.0.0"

// GoogleIoTCore library example:
// - Downloads public and private keys using the provided URLs. All other configuration settings are hardcoded in the example's code.
// - Registers a device (if not registered yet) in the Google IoT Core platform using the optional `register()` method of the library.
// - Connects to Google IoT Core.
// - Sends telemetry events every 8 sec. Each event contains the current timestamp.

// Number of seconds to wait before the next publishing
const PUBLISH_DELAY = 8;

class AutoRegisterExample {
    _googleIoTCoreClient = null;

    _projectId = null;
    _cloudRegion = null;
    _registryId = null;
    _deviceId = null;
    _privateKey = null;

    _iss = null;
    _secret = null;
    _publicKey = null;

    _publicKeyUrl = null;
    _privateKeyUrl = null;

    constructor(projectId,
                cloudRegion,
                registryId,
                deviceId,
                iss,
                secret,
                publicKeyUrl,
                privateKeyUrl) {
        _projectId = projectId;
        _cloudRegion = cloudRegion;
        _registryId = registryId;
        _deviceId = deviceId;
        _iss = iss;
        _secret = secret;
        _publicKeyUrl = publicKeyUrl;
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

            server.log("Trying to register the device..");
            _googleIoTCoreClient.register(_iss, _secret, _publicKey, onRegistered.bindenv(this));
        }.bindenv(this);

        local pubKeyLoaded = function (err, pubKey) {
            if (err != 0) {
                server.log("Public key downloading is failed: " + err);
                return;
            }
            server.log("Public key is loaded");
            _publicKey = pubKey;
            downloadKey(_privateKeyUrl, privKeyLoaded);
        }.bindenv(this);

        server.log("Downloading keys..");
        downloadKey(_publicKeyUrl, pubKeyLoaded);
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

    function onRegistered(error) {
        if (error != 0) {
            server.error("Registration error: code = " + error);
            return;
        }
        server.log("Successfully registered!");
        _googleIoTCoreClient.connect();
    }

    function publishTelemetry() {
        _googleIoTCoreClient.publish(time().tostring(), null, onPublished.bindenv(this));
    }

    function onPublished(data, error) {
        if (error != 0) {
            server.error("Publish telemetry error: code = " + error);
            return;
        }
        server.log("Telemetry has been published. Data = " + data);
        imp.wakeup(PUBLISH_DELAY, publishTelemetry.bindenv(this));
    }

    function onConnected(error) {
        if (error != 0) {
            server.error("Can't connect: " + error);
        } else {
            server.log("Connected successfully!");
            publishTelemetry();
        }
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

const GOOGLE_ISS = "<YOUR_GOOGLE_ISS>";
const GOOGLE_SECRET_KEY = "<YOUR_GOOGLE_SECRET_KEY>";

const PUBLIC_KEY_URL = "<YOUR_PUBLIC_KEY_URL>";
const PRIVATE_KEY_URL = "<YOUR_PRIVATE_KEY_URL>";

// Start Application
googleIoTCore <- AutoRegisterExample(GOOGLE_IOT_CORE_PROJECT_ID,
                                     GOOGLE_IOT_CORE_CLOUD_REGION,
                                     GOOGLE_IOT_CORE_REGISTRY_ID,
                                     GOOGLE_IOT_CORE_DEVICE_ID,
                                     GOOGLE_ISS,
                                     GOOGLE_SECRET_KEY,
                                     PUBLIC_KEY_URL,
                                     PRIVATE_KEY_URL);
googleIoTCore.start();
