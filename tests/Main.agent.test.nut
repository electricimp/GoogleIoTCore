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


const GOOGLE_IOT_CORE_PROJECT_ID = "@{GOOGLE_IOT_CORE_PROJECT_ID}";
const GOOGLE_IOT_CORE_CLOUD_REGION = "@{GOOGLE_IOT_CORE_CLOUD_REGION}";
const GOOGLE_IOT_CORE_REGISTRY_ID = "@{GOOGLE_IOT_CORE_REGISTRY_ID}";
const GOOGLE_IOT_CORE_DEVICE_ID = "@{GOOGLE_IOT_CORE_DEVICE_ID}";
const GOOGLE_IOT_CORE_PRIVATE_KEY = "@{GOOGLE_IOT_CORE_PRIVATE_KEY}";

class MainTestCase extends ImpTestCase {
    _googleIoTCoreClient = null;

    function setUp() {
        return _connect();
    }

    function tearDown() {
        return _disconnect();
    }

    function testIsConnected() {
        this.assertTrue(_googleIoTCoreClient.isConnected());
    }

    function testPublish() {
        return Promise(function (resolve, reject) {
            local telemetry = blob();
            telemetry.writestring("test");
            local callback = function (data, err) {
                if (data.tostring() != telemetry.tostring()) {
                    return reject("The returned data is not equal to the original data passed in to the method");
                }
                if (err == 0) {
                    return resolve();
                }
                return reject("Can't publish telemetry: " + err);
            }.bindenv(this);
            _googleIoTCoreClient.publish(telemetry, null, callback);
        }.bindenv(this));
    }

    function testEnableCfgReceiving() {
        return Promise(function (resolve, reject) {
            local callback = function (err) {
                if (err == 0) {
                    return resolve();
                }
                return reject("Can't enable configuration receiving");
            }.bindenv(this);
            _googleIoTCoreClient.enableCfgReceiving(function (cfg) {}, callback);
        }.bindenv(this));
    }

    function testReportState() {
        return Promise(function (resolve, reject) {
            local state = blob();
            state.writestring("test");
            local callback = function (data, err) {
                if (data.tostring() != state.tostring()) {
                    return reject("The returned data is not equal to the original data passed in to the method");
                }
                if (err == 0) {
                    return resolve();
                }
                return reject("Can't report state: " + err);
            }.bindenv(this);
            _googleIoTCoreClient.reportState(state, callback);
        }.bindenv(this));
    }

    function _connect() {
        return Promise(function (resolve, reject) {
            local onConnected = function (err) {
                if (err == 0) {
                    return resolve();
                }
                return reject("Can't connect: " + err);
            }.bindenv(this);
            local options = {
                "maxPendingSetStateRequests": 1,
                "maxPendingPublishTelemetryRequests" : 1
            };
            _googleIoTCoreClient = GoogleIoTCore.Client(GOOGLE_IOT_CORE_PROJECT_ID,
                                                        GOOGLE_IOT_CORE_CLOUD_REGION,
                                                        GOOGLE_IOT_CORE_REGISTRY_ID,
                                                        GOOGLE_IOT_CORE_DEVICE_ID,
                                                        GOOGLE_IOT_CORE_PRIVATE_KEY,
                                                        onConnected,
                                                        null,
                                                        GoogleIoTCore.MqttTransport(),
                                                        options);
            _googleIoTCoreClient.connect();
        }.bindenv(this));
    }

    function _disconnect() {
        return Promise(function (resolve, reject) {
            local onDisconnected = function (reason) {
                if (reason == 0) {
                    return resolve();
                }
                return reject(reason);
            }.bindenv(this);
            _googleIoTCoreClient.setOnDisconnected(onDisconnected);
            _googleIoTCoreClient.disconnect();
        }.bindenv(this));
    }
}