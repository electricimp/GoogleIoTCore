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

@include "github:electricimp/OAuth-2.0/OAuth2.agent.lib.nut@v2.0.0"


const GOOGLE_IOT_CORE_PRIVATE_KEY = "@{GOOGLE_IOT_CORE_PRIVATE_KEY}";
const GOOGLE_SECRET_KEY = "@{GOOGLE_SECRET_KEY}";

class DummyTestCase extends ImpTestCase {
    _googleIoTCoreClient = null;

    function setUp() {
        _googleIoTCoreClient = GoogleIoTCore.Client("projId", "cloudReg", "regId", "devId", GOOGLE_IOT_CORE_PRIVATE_KEY);
    }

    function tearDown() {
        _googleIoTCoreClient.disconnect();
    }

    function testRegister() {
        return Promise(function (resolve, reject) {
            _googleIoTCoreClient.register("iss", GOOGLE_SECRET_KEY, "pubKey");
            local callback = function (err) {
                if (err == GOOGLE_IOT_CORE_ERROR_GENERAL) {
                    return resolve();
                }
                return reject("GOOGLE_IOT_CORE_ERROR_GENERAL error was expected!");
            }.bindenv(this);
            _googleIoTCoreClient.register("iss", GOOGLE_SECRET_KEY, "pubKey", callback);
        }.bindenv(this));
    }

    function testConnect1() {
        return Promise(function (resolve, reject) {
            local callback = function (err) {
                if (err != 0) {
                    return resolve();
                }
                return reject("An error was expected!");
            }.bindenv(this);
            _googleIoTCoreClient.setOnConnected(callback);
            _googleIoTCoreClient.connect();
        }.bindenv(this));
    }

    function testIsConnected() {
        this.assertTrue(!_googleIoTCoreClient.isConnected());
    }

    function testPublish() {
        return Promise(function (resolve, reject) {
            _googleIoTCoreClient.publish(blob());
            local callback = function (data, err) {
                if (err == GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED) {
                    return resolve();
                }
                return reject("GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED error was expected!");
            }.bindenv(this);
            _googleIoTCoreClient.publish(blob(), null, callback);
        }.bindenv(this));
    }

    function testEnableCfgReceiving() {
        return Promise(function (resolve, reject) {
            _googleIoTCoreClient.enableCfgReceiving(function (cfg) {});
            local callback = function (err) {
                if (err == GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED) {
                    return resolve();
                }
                server.error(err);
                return reject("GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED error was expected!");
            }.bindenv(this);
            _googleIoTCoreClient.enableCfgReceiving(function (cfg) {}, callback);
        }.bindenv(this));
    }

    function testReportState() {
        return Promise(function (resolve, reject) {
            _googleIoTCoreClient.reportState(blob());
            local callback = function (data, err) {
                if (err == GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED) {
                    return resolve();
                }
                return reject("GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED error was expected!");
            }.bindenv(this);
            _googleIoTCoreClient.reportState(blob(), callback);
        }.bindenv(this));
    }

    function testSetOnDisconnected() {
        _googleIoTCoreClient.setOnDisconnected(function (err) {});
    }

    function testSetDebug() {
        _googleIoTCoreClient.setDebug(true);
        _googleIoTCoreClient.setDebug(false);
    }
}