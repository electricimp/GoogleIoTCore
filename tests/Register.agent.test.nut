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
const GOOGLE_IOT_CORE_DEVICE_ID = "@{GOOGLE_IOT_CORE_DEVICE_ID}";
const GOOGLE_IOT_CORE_PUBLIC_KEY = "@{GOOGLE_IOT_CORE_PUBLIC_KEY}";
const GOOGLE_ISS = "@{GOOGLE_ISS}";
const GOOGLE_SECRET_KEY = "@{GOOGLE_SECRET_KEY}";

class RegisterTestCase extends ImpTestCase {
    _googleIoTCoreClient = null;

    function setUp() {
        _googleIoTCoreClient = GoogleIoTCore.Client(GOOGLE_IOT_CORE_PROJECT_ID,
                                                    GOOGLE_IOT_CORE_CLOUD_REGION,
                                                    GOOGLE_IOT_CORE_REGISTRY_ID,
                                                    "TestGoogleIoTDevice",
                                                    "privKey");
    }

    function tearDown() {
        // TODO: remove the device created
    }

    function testRegister() {
        return Promise(function (resolve, reject) {
            local callback = function (err) {
                if (err == 0) {
                    return resolve();
                }
                return reject("Can't register device: " + err);
            }.bindenv(this);
            _googleIoTCoreClient.register(GOOGLE_ISS, GOOGLE_SECRET_KEY, GOOGLE_IOT_CORE_PUBLIC_KEY, callback);
        }.bindenv(this));
    }
}