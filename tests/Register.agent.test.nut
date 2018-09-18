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


const GOOGLE_IOT_CORE_PROJECT_ID = "@{GOOGLE_IOT_CORE_PROJECT_ID}";
const GOOGLE_IOT_CORE_CLOUD_REGION = "@{GOOGLE_IOT_CORE_CLOUD_REGION}";
const GOOGLE_IOT_CORE_REGISTRY_ID = "@{GOOGLE_IOT_CORE_REGISTRY_ID}";
const GOOGLE_IOT_CORE_PUBLIC_KEY = "@{GOOGLE_IOT_CORE_PUBLIC_KEY}";
const GOOGLE_ISS = "@{GOOGLE_ISS}";
const GOOGLE_SECRET_KEY = "@{GOOGLE_SECRET_KEY}";

class RegisterTestCase extends ImpTestCase {
    _googleIoTCoreClient = null;
    _deviceId = null;
    _oatoken = null;

    function setUp() {
        return Promise(function (resolve, reject) {
            local getTokenDone = function (err, oatoken) {
                if (err != 0) {
                    return reject("Cannot get OAuth token. code = " + err);
                }
                _oatoken = oatoken;
                try {
                    _chooseDevId(oatoken);
                } catch (e) {
                    return reject(e);
                }
                _googleIoTCoreClient = GoogleIoTCore.Client(GOOGLE_IOT_CORE_PROJECT_ID,
                                                            GOOGLE_IOT_CORE_CLOUD_REGION,
                                                            GOOGLE_IOT_CORE_REGISTRY_ID,
                                                            _deviceId,
                                                            "privKey");
                return resolve();
            }.bindenv(this);

            _getOAuthToken(GOOGLE_ISS, GOOGLE_SECRET_KEY, getTokenDone);
        }.bindenv(this));
    }

    // Remove the device
    function tearDown() {
        return Promise(function (resolve, reject) {
            if (_oatoken == null) {
                return reject("OAuth token is null");
            }
            if (_deviceId == null) {
                return reject("Device ID is null");
            }
            local headers = {
                "authorization" : "Bearer " + _oatoken,
                "content-type" : "application/json",
                "cache-control" : "no-cache"
            };

            local url = "https://cloudiot.googleapis.com/v1/";
            url += format("projects/%s/locations/%s/registries/%s/devices/%s", GOOGLE_IOT_CORE_PROJECT_ID,
                                                                               GOOGLE_IOT_CORE_CLOUD_REGION,
                                                                               GOOGLE_IOT_CORE_REGISTRY_ID,
                                                                               _deviceId);

            local req = http.request("DELETE", url, headers, "");

            local sent = function (resp) {
                if (resp.statuscode / 100 == 2) {
                    return resolve();
                }
                reject("Cannot delete the device. code = " + resp.statuscode + " body = " + resp.body);
            }.bindenv(this);

            req.sendasync(sent);
        }.bindenv(this));
    }

    function testRegister1() {
        return _register();
    }

    // We should be able to "register" the device twice
    function testRegister2() {
        return _register();
    }

    function _register() {
        return Promise(function (resolve, reject) {
            if (_deviceId == null) {
                return reject("Device ID is null");
            }
            local callback = function (err) {
                if (err == 0) {
                    return resolve();
                }
                return reject("Can't register device: " + err);
            }.bindenv(this);
            _googleIoTCoreClient.register(GOOGLE_ISS, GOOGLE_SECRET_KEY, GOOGLE_IOT_CORE_PUBLIC_KEY, callback);
        }.bindenv(this));
    }

    function _chooseDevId(oatoken) {
        for (local i = 0; i < 16; i += 1) {
            local devId = _generateDevId();
            if (_isDevIdFree(oatoken, devId)) {
                _deviceId = devId;
                return;
            }
        }
        throw "Can't choose a Device ID which is free";
    }

    function _isDevIdFree(oatoken, deviceId) {
        local headers = {
            "authorization" : "Bearer " + oatoken,
            "content-type" : "application/json",
            "cache-control" : "no-cache"
        };

        local url = "https://cloudiot.googleapis.com/v1/";
        url += format("projects/%s/locations/%s/registries/%s/devices/%s", GOOGLE_IOT_CORE_PROJECT_ID,
                                                                           GOOGLE_IOT_CORE_CLOUD_REGION,
                                                                           GOOGLE_IOT_CORE_REGISTRY_ID,
                                                                           deviceId);

        local req = http.get(url, headers);

        local resp = req.sendsync();
        if (resp.statuscode == 404) {
            // We have not found any device, it is OK
            return true;
        } else if (resp.statuscode / 100 == 2) {
            return false;
        } else {
            throw "Can't check if the generated Device ID is free";
        }
    }

    function _generateDevId() {
        return "x" + math.rand() + math.rand() + math.rand();
    }

    function _getOAuthToken(iss, secret, callback) {
        local config = {
            "iss"         : iss,
            "jwtSignKey"  : secret,
            "scope"       : "https://www.googleapis.com/auth/cloud-platform"
        };
        local client = OAuth2.JWTProfile.Client(OAuth2.DeviceFlow.GOOGLE, config);
        client.acquireAccessToken(
            function(resp, err) {
                if (err) {
                    callback(err, null);
                } else {
                    callback(0, resp);
                }
            }.bindenv(this)
        );
    }
}