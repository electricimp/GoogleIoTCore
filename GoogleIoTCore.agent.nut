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


// GoogleIoTCore is an Electric Imp agent-side library which allows your agent code to work with Google IoT Core.

const GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED           = 1000;
const GOOGLE_IOT_CORE_ERROR_ALREADY_CONNECTED       = 1001;
const GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW      = 1002;
const GOOGLE_IOT_CORE_ERROR_TOKEN_REFRESHING        = 1003;
const GOOGLE_IOT_CORE_ERROR_ALREADY_REGISTERED      = 1004;
const GOOGLE_IOT_CORE_ERROR_GENERAL                 = 1010;

class GoogleIoTCore {

    static VERSION = "1.0.0";

}

class GoogleIoTCore.Client extends GoogleIoTCore {

    _debug              = false;

    _projectId          = null;
    _cloudRegion        = null;
    _registryId         = null;
    _deviceId           = null;
    _privateKey         = null;

    _onConnectedCb      = null;
    _onDisconnectedCb   = null;

    _options            = null;
    _topics             = null;

    _transport          = null;
    _defaultTransport   = null;

    // GoogleIoTCore Client class constructor.
    //
    // Parameters:
    //     projectId : String           Project ID.
    //     cloudRegion : String         Cloud region.
    //     registryId : String          Registry ID.
    //     deviceId : String            Device ID.
    //     privateKey : String          Private key.
    //     onConnected : Function       Callback called every time the client is connected.
    //          (optional)              The callback signature:
    //                                  onConnected(error), where
    //                                      error : Integer     0 if the connection is successful, an error code otherwise.
    //     onDisconnected : Function    Callback called every time the client is disconnected.
    //          (optional)              The callback signature:
    //                                  onDisconnected(error), where
    //                                      error : Integer     0 if the disconnection was caused by the disconnect() method,
    //                                                          an error code which explains a reason of the disconnection otherwise.
    //     options : Table              Key-value table with optional settings.
    //          (optional)
    //
    // Returns:                         GoogleIoTCore.Client instance created.
    constructor(projectId,
                cloudRegion,
                registryId,
                deviceId,
                privateKey,
                onConnected = null,
                onDisconnected = null,
                options = null) {
        const DEFAULT_SET_STATE_PARAL_REQS      = 3;
        const DEFAULT_PUB_TELEMETRY_PARAL_REQS  = 3;
        const DEFAULT_TOKEN_TTL                 = 3600;

        _projectId          = projectId;
        _cloudRegion        = cloudRegion;
        _registryId         = registryId;
        _deviceId           = deviceId;
        _privateKey         = privateKey;
        _onConnectedCb      = onConnected;
        _onDisconnectedCb   = onDisconnected;

        _options = {
            "maxPendingSetStateRequests" : DEFAULT_SET_STATE_PARAL_REQS,
            "maxPendingPublishTelemetryRequests" : DEFAULT_PUB_TELEMETRY_PARAL_REQS,
            "tokenTTL" : DEFAULT_TOKEN_TTL
        };

        if (options != null) {
            foreach (optName, optVal in options) {
                _options[optName] <- optVal;
            }
        }
    }

    // Registers a device in Google IoT Core.
    //
    // Parameters:
    //     iss : String                 JWT issuer.
    //     secret : String              JWT sign secret key.
    //     publicKey : String           Public key for a new device.
    //     onRegistered : Function      Callback called when the operation is completed or an error occurs.
    //          (optional)              The callback signature:
    //                                  onRegistered(error), where
    //                                      error : Integer     0 if the operation is completed successfully, an error code otherwise.
    //
    // Returns:                         Nothing.
    function register(iss, secret, publicKey, onRegistered = null) {
        local token = null;

        local getDeviceDone = function (err, respBody) {
            if (err != 0) {
                _logError("Can't get device data. Code = " + err + ". Body = " + respBody);
                onRegistered && onRegistered(GOOGLE_IOT_CORE_ERROR_GENERAL);
                return;
            }

            if (respBody == null) {
                // Device is not found
                _log("Creating device...");

                local created = function (err, respBody) {
                    if (err == 0) {
                        _log("Device has been created successfully");
                        onRegistered && onRegistered(0);
                    } else {
                        _logError("Can't create device. Code = " + err + ". Body = " + respBody);
                        onRegistered && onRegistered(GOOGLE_IOT_CORE_ERROR_GENERAL);
                    }
                }.bindenv(this);

                _createDevice(publicKey, token, created);
            } else {
                // Device is found. Now we should compare its public keys with our key
                foreach (cred in respBody.credentials) {
                    if (strip(publicKey) == strip(cred.publicKey.key)) {
                        // We've found a key equal to our key, so this is that device we wanted to register
                        onRegistered && onRegistered(0);
                        return;
                    }
                }
                // We've found a device but this device is not that we wanted to register
                onRegistered && onRegistered(GOOGLE_IOT_CORE_ERROR_ALREADY_REGISTERED);
            }
        }.bindenv(this);

        local getTokenDone = function (err, oatoken) {
            if (err != 0) {
                onRegistered && onRegistered(GOOGLE_IOT_CORE_ERROR_GENERAL);
                return;
            }
            token = oatoken;
            _getDevice(token, getDeviceDone);
        }.bindenv(this);

        _getOAuthToken(iss, secret, getTokenDone);
    }

    // Opens a connection to Google IoT Core.
    //
    // Parameters:
    //     transport :                  Instance of GoogleIoTCore.*Transport class.
    //              GoogleIoTCore.*Transport
    //          (optional)
    //
    // Returns:                         Nothing.
    function connect(transport = null) {
        if (isConnected()) {
            _onConnectedCb && _onConnectedCb(GOOGLE_IOT_CORE_ERROR_ALREADY_CONNECTED);
            return;
        }

        if (transport == null) {
            _defaultTransport = _defaultTransport != null ? _defaultTransport : GoogleIoTCore.MqttTransport();
            _transport = _defaultTransport;
        } else {
            _transport = transport;
        }

        _transport._setClient(this);
        _transport._setTokenMaker(_makeJwtToken.bindenv(this));
        _transport._setOnConnected(_onConnected.bindenv(this));
        _transport._setOnDisconnected(_onDisconnected.bindenv(this));
        _transport._setDebug(_debug);
        _transport._connect();
    }

    // Closes the connection to Google IoT Core. Does nothing if the connection is already closed.
    //
    // Returns:                         Nothing.
    function disconnect() {
        _transport || _logError("Client is not connected");
        _transport && _transport._disconnect();
    }

    // Checks if the client is connected to Google IoT Core.
    //
    // Returns:                         Boolean: true if the client is connected, false otherwise.
    function isConnected() {
        return _transport && _transport._isConnected();
    }

    // Publishes a telemetry event to Google IoT Core.
    //
    // Parameters:
    //     data : String or Blob        Application specific data.
    //     subfolder : String           The subfolder can be used as an event category or classification.
    //          (optional)
    //     onPublished : Function       Callback called when the operation is completed or an error occurs.
    //          (optional)              The callback signature:
    //                                  onPublished(data, error), where
    //                                      data :              The original data passed in to the publishTelemetry() method.
    //                                          String or Blob
    //                                      error : Integer     0 if the operation is completed successfully, an error code otherwise.
    //
    // Returns:                         Nothing.
    function publish(data, subfolder = null, onPublished = null) {
        if (_transport == null) {
            onPublished && onPublished(data, GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED);
            return;
        }
        _transport._publish(data, subfolder, onPublished);
    }

    // Enables configuration receiving from Google IoT Core.
    //
    // Parameters:
    //     onReceive : Function         Callback called every time a configuration is received from Google IoT Core. null disables the feature.
    //                                  The callback signature:
    //                                  onReceive(configuration), where
    //                                      configuration :     Configuration. An arbitrary user-defined blob.
    //                                          Blob
    //     onDone : Function            Callback called when the operation is completed or an error occurs.
    //          (optional)              The callback signature:
    //                                  onDone(error), where
    //                                      error : Integer     0 if the operation is completed successfully, an error code otherwise.
    //
    // Returns:                         Nothing.
    function enableCfgReceiving(onReceive, onDone = null) {
        if (_transport == null) {
            onDone && onDone(GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED);
            return;
        }
        _transport._enableCfgReceiving(onReceive, onDone);
    }

    // Reports a device state to Google IoT Core.
    //
    // Parameters:
    //     state : String or Blob       Device state. Application specific data.
    //     onReported : Function        Callback called when the operation is completed or an error occurs.
    //          (optional)              The callback signature:
    //                                  onReported(state, error), where
    //                                      state :             The original state passed in to the reportDeviceState() method.
    //                                          String or Blob
    //                                      error : Integer     0 if the operation is completed successfully, an error code otherwise.
    //
    // Returns:                         Nothing.
    function reportState(state, onReported = null) {
        if (_transport == null) {
            onReported && onReported(data, GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED);
            return;
        }
        _transport._reportState(state, onReported);
    }

    // Sets onConnected callback.
    //
    // Parameters:
    //     onConnected : Function       Callback called every time the client is connected.
    //                                  The callback signature:
    //                                  onConnected(error), where
    //                                      error : Integer     0 if the connection is successful, an error code otherwise.
    //
    // Returns:                         Nothing.
    function setOnConnected(callback) {
        _onConnectedCb = callback;
    }

    // Sets onDisconnected callback.
    //
    // Parameters:
    //     onDisconnected : Function    Callback called every time the client is disconnected.
    //                                  The callback signature:
    //                                  onDisconnected(error), where
    //                                      error : Integer     0 if the disconnection was caused by the disconnect() method,
    //                                                          an error code which explains a reason of the disconnection otherwise.
    //
    // Returns:                         Nothing.
    function setOnDisconnected(callback) {
        _onDisconnectedCb = callback;
    }

    function setDebug(value) {
        _debug = value;
        _transport && _transport._setDebug(_debug);
    }
    // -------------------- PRIVATE METHODS -------------------- //

    function _onConnected(err) {
        _onConnectedCb && _onConnectedCb(err);
    }

    function _onDisconnected(reason) {
        _onDisconnectedCb && _onDisconnectedCb(reason);
    }

    function _getOAuthToken(iss, secret, callback) {
        local config = {
            "iss"         : iss,
            "jwtSignKey"  : secret,
            "scope"       : "https://www.googleapis.com/auth/cloud-platform"
        };
        // Initializing client with provided Google Firebase config
        local client = OAuth2.JWTProfile.Client(OAuth2.DeviceFlow.GOOGLE, config);

        // TODO: Fix it in the OAuth lib and remove this line
        // TODO: Also remove direct "server.log" calls in that lib
        client._debug = false;

        // Starting procedure of access token acquisition
        client.acquireAccessToken(
            function(resp, err) {
                if (err) {
                    _logError("OAuth token acquisition error: " + err);
                    callback(GOOGLE_IOT_CORE_ERROR_GENERAL, null);
                } else {
                    callback(0, resp);
                }
            }.bindenv(this)
        );
    }

    function _getDevice(oatoken, callback) {
        local headers = {
            "authorization" : "Bearer " + oatoken,
            "content-type" : "application/json",
            "cache-control" : "no-cache"
        };

        local url = "https://cloudiot.googleapis.com/v1/";
        url += format("projects/%s/locations/%s/registries/%s/devices/%s", _projectId, _cloudRegion, _registryId, _deviceId);

        local req = http.get(url, headers);

        local sent = function (resp) {
            if (resp.statuscode == 404) {
                callback(0, null);
            } else if (resp.statuscode == 200) {
                callback(0, http.jsondecode(resp.body));
            } else {
                callback(resp.statuscode, resp.body);
            }
        }.bindenv(this);

        req.sendasync(sent);
    }

    function _createDevice(publicKey, oatoken, callback) {
        local headers = {
            "authorization" : "Bearer " + oatoken,
            "content-type" : "application/json",
            "cache-control" : "no-cache"
        };

        local url = "https://cloudiot.googleapis.com/v1/";
        url += format("projects/%s/locations/%s/registries/%s/devices", _projectId, _cloudRegion, _registryId);

        local deviceDesc = {
            "id": _deviceId,
            "credentials": [
                {
                    "public_key": {
                        // TODO: should we allow for another RSA format?
                        "format": "RSA_X509_PEM",
                        "key": publicKey
                    }
                }
            ]
        };
        local data = http.jsonencode(deviceDesc);

        local req = http.post(url, headers, data);

        local sent = function (resp) {
            if (resp.statuscode == 200) {
                callback(0, null);
            } else {
                callback(resp.statuscode, resp.body);
            }
        }.bindenv(this);

        req.sendasync(sent);
    }

    function _makeJwtToken(tokenReadyCb) {
        local header = http.base64encode("{\"alg\":\"RS256\",\"typ\":\"JWT\"}");
        local curTime = time();
        local expTime = curTime + _options.tokenTTL;
        local claimset = {
            "aud"   : _projectId,
            "exp"   : expTime,
            "iat"   : curTime
        };
        local body = http.base64encode(http.jsonencode(claimset));

        crypto.sign(crypto.RSASSA_PKCS1_SHA256, header + "." + body, _decodePem(_privateKey),
            function(err, sig) {
                if (err) {
                    server.error(err);
                    return;
                }

                local signature = http.base64encode(sig);

                tokenReadyCb({
                    "jwtToken" : (header + "." + body + "." + signature),
                    "jwtExpiresAt" : expTime});

            }.bindenv(this)
        );
    }

    // Remove the armor, concatenate the lines, and base64 decode the text.
    function _decodePem(str) {
        local lines = split(str, "\n");
        // We really ought to iterate over the array until we find a starting line,
        // and then look for the matching ending line.
        if ((lines[0] == "-----BEGIN PRIVATE KEY-----"
                && lines[lines.len() - 1] == "-----END PRIVATE KEY-----") ||
            (lines[0] == "-----BEGIN RSA PRIVATE KEY-----"
                && lines[lines.len() - 1] == "-----END RSA PRIVATE KEY-----") ||
            (lines[0] == "-----BEGIN PUBLIC KEY-----"
                && lines[lines.len() - 1] == "-----END PUBLIC KEY-----"))
        {
            local all = lines.slice(1, lines.len() - 1).reduce(@(a, b) a + b);
            return http.base64decode(all);
        }
        return null;
    }

    // Information level logger
    function _log(txt) {
        if (_debug) {
            server.log("[" + (typeof this) + "] " + txt);
        }
    }

    // Error level logger
    function _logError(txt) {
        // TODO: use this method only for critical errors
        if (_debug) {
            server.error("[" + (typeof this) + "] " + txt);
        }
    }

    function _typeof() {
        return "GoogleIoTCore.Client";
    }
}

class GoogleIoTCore.MqttTransport {

    _debug                  = false;

    // TODO: replace these flags with enum
    _stateDisconnected      = true;
    _stateDisconnecting     = false;
    _stateConnected         = false;
    _stateConnecting        = false;
    // Indicates that we are subscribing to configurtion updates
    _stateSubscribing       = false;
    _stateRefreshingToken   = false;

    _mqttclient             = null;
    _mqttClientId           = null;
    _mqttCreds              = null;
    _msgOptions             = null;

    _options                = null;

    _client                 = null;

    // Function. Should return a table with jwtToken and expiresAt fields
    _makeToken              = null;

    _jwtToken               = null;
    _jwtExpiresAt           = null;

    _onConnectedCb          = null;
    _onDisconnectedCb       = null;
    _onConfigCb             = null;
    _onConfigEnabledCb      = null;

    _topics                 = null;
    _pubTelemetryReqs       = null;
    _reportStateReqs        = null;

    _refreshTokenTimer      = null;
    _reqNum                 = 0;

    // Array of calls made while refreshing token
    _pendingCalls           = null;
    _refreshingPaused       = false;

    constructor(options = {}) {
        const DEFAULT_URL           = "ssl://mqtt.googleapis.com:8883";
        const DEFAULT_QOS           = 0;
        const DEFAULT_KEEP_ALIVE    = 60;

        const DATA_INDEX            = 0;
        const CALLBACK_INDEX        = 1;

        _pubTelemetryReqs = {};
        _reportStateReqs = {};
        _pendingCalls = [];

        _options = {
            "url" : DEFAULT_URL,
            "qos" : DEFAULT_QOS,
            "keepAlive" : DEFAULT_KEEP_ALIVE
        };

        foreach (optName, optVal in options) {
            _options[optName] <- optVal;
        }

        _msgOptions = {
            "qos" : _options.qos
        };

        _mqttclient = mqtt.createclient();
        _mqttclient.onconnect(_onConnected.bindenv(this));
        _mqttclient.onconnectionlost(_onDisconnected.bindenv(this));
        _mqttclient.onmessage(_onMessage.bindenv(this));
    }

    // -------------------- PRIVATE METHODS -------------------- //

    function _initTopics() {
        _topics = {};
        _topics.pubTelemetry <- format("/devices/%s/events", _client._deviceId);
        _topics.configuration <- format("/devices/%s/config", _client._deviceId);
        _topics.reportState <- format("/devices/%s/state", _client._deviceId);
    }

    function _connect() {
        if (_client == null) {
            throw "Client instance is not set";
        }
        if (_onConnectedCb == null) {
            throw "onConnected callback is not set";
        }

        if (_stateConnected || _stateConnecting) {
            _onConnectedCb(_stateConnected ? GOOGLE_IOT_CORE_ERROR_ALREADY_CONNECTED : GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW);
            return;
        }

        _log("Connecting...");
        _stateConnecting = true;

        local tokenReady = function () {
            _mqttCreds = {
                "username" : "useless",
                "password" : _jwtToken,
                "keepalive" : _options.keepAlive
            };
            _mqttclient.connect(_options.url, _mqttClientId, _mqttCreds);
        }.bindenv(this);
        _updateToken(tokenReady);
    }

    function _disconnect(reason = null) {
        if ((!_stateDisconnected || _stateConnecting) && !_stateDisconnecting) {
            _stateDisconnecting = true;
            _mqttclient.disconnect(function() {_onDisconnected(reason);}.bindenv(this));
        } else {
            _logError("Client is already disconnected or disconnecting");
        }
    }

    function _isConnected() {
        return _stateConnected;
    }

    function _publish(data, subfolder, onPublished) {
        if (!_stateConnected || _stateDisconnecting) {
            onPublished && onPublished(data, _stateConnected ? GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW : GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED);
            return;
        }

        if (_stateRefreshingToken) {
            _pendingCalls.append(@() _publish(data, subfolder, onPublished));
            return;
        }

        local tooManyRequests = _pubTelemetryReqs.len() >= _client._options.maxPendingPublishTelemetryRequests;

        if (tooManyRequests) {
            onPublished && onPublished(data, GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW);
            return;
        }

        local reqId = _reqNum++;
        local topic = _topics.pubTelemetry + (subfolder != null ? "/" + subfolder : "");
        local mqttMsg = _mqttclient.createmessage(topic, data, _msgOptions);

        local msgSentCb = function (err) {
            if (reqId in _pubTelemetryReqs) {
                delete _pubTelemetryReqs[reqId];
                _refreshingPaused && _continueRefreshing();
                onPublished && onPublished(data, err);
            }
        }.bindenv(this);

        _pubTelemetryReqs[reqId] <- [data, onPublished];
        mqttMsg.sendasync(msgSentCb);
    }

    // TODO: rename to subscribeXXXXXXXXX?
    function _enableCfgReceiving(onReceive, onDone) {
        local enabled = _onConfigCb != null;
        local disable = onReceive == null;

        if (!_readyToEnable(_stateSubscribing, enabled, disable, onDone)) {
            return;
        }

        if (enabled && !disable) {
            _onConfigCb = onReceive;
            onDone && onDone(0);
            return;
        }

        if (_stateRefreshingToken) {
            _pendingCalls.append(@() _enableCfgReceiving(onReceive, onDone));
            return;
        }

        local doneCb = function (err) {
            if (_stateSubscribing) {
                _onConfigEnabledCb = null;
                _stateSubscribing = false;
                if (err == 0) {
                    _onConfigCb = onReceive;
                }
                _refreshingPaused && _continueRefreshing();
                onDone && onDone(err);
            }
        }.bindenv(this);

        local topic = _topics.configuration;
        _onConfigEnabledCb = onDone;
        _stateSubscribing = true;

        if (disable) {
            _mqttclient.unsubscribe(topic, doneCb);
        } else {
            local subscribedCb = function (err, qos) {
                doneCb(err);
            }.bindenv(this);

            _mqttclient.subscribe(topic, _options.qos, subscribedCb);
        }
    }

    function _reportState(state, onReported) {
        if (!_stateConnected || _stateDisconnecting) {
            onReported && onReported(state, _stateConnected ? GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW : GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED);
            return;
        }

        if (_stateRefreshingToken) {
            _pendingCalls.append(@() _reportState(state, onReported));
            return;
        }

        local tooManyRequests = _reportStateReqs.len() >= _client._options.maxPendingSetStateRequests;

        if (tooManyRequests) {
            onReported && onReported(state, GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW);
            return;
        }

        local reqId = _reqNum++;
        local topic = _topics.reportState;
        local mqttMsg = _mqttclient.createmessage(topic, state, _msgOptions);

        local msgSentCb = function (err) {
            if (reqId in _reportStateReqs) {
                delete _reportStateReqs[reqId];
                _refreshingPaused && _continueRefreshing();
                onReported && onReported(state, err);
            }
        }.bindenv(this);

        _reportStateReqs[reqId] <- [state, onReported];
        mqttMsg.sendasync(msgSentCb);
    }

    function _setOnConnected(callback) {
        _onConnectedCb = callback;
    }

    function _setOnDisconnected(callback) {
        _onDisconnectedCb = callback;
    }

    function _onConnected(err) {
        if (_stateRefreshingToken) {
            if (err == 0) {
                _log("Reconnected with new token!");
                local resubscribed = function (err) {
                    _stateRefreshingToken = false;
                    if (err == 0) {
                        _refreshTokenTimer = imp.wakeup(_timeBeforeRefreshing(), _refreshToken.bindenv(this));
                        _runPendingCalls();
                    } else {
                        _disconnect(GOOGLE_IOT_CORE_ERROR_TOKEN_REFRESHING);
                    }
                }.bindenv(this);
                _resubscribe(resubscribed);
            } else {
                _stateRefreshingToken = false;
                _logError("Can't connect while refreshing token. Return code: " + err);
                _onDisconnected(GOOGLE_IOT_CORE_ERROR_TOKEN_REFRESHING);
            }
            return
        }

        if (err == 0) {
            _log("Connected!");
            _stateConnected = true;
            _stateDisconnected = false;
            _refreshTokenTimer = imp.wakeup(_timeBeforeRefreshing(), _refreshToken.bindenv(this));
        }

        _stateConnecting = false;
        _onConnectedCb(err);
    }

    function _onDisconnected(reason = null) {
        if (_onDisconnectedCb == null) {
            throw "onDisconnected callback is not set";
        }
        if (reason == null) {
            reason = _stateDisconnecting ? 0 : GOOGLE_IOT_CORE_ERROR_GENERAL;
            _log(reason == 0 ? "Disconnected!" : "Connection lost!");
        }
        _cleanup();
        _onDisconnectedCb(reason);
    }

    function _refreshToken() {
        _refreshingPaused = false;
        if (!_stateConnected || _stateDisconnecting) {
            _refreshTokenTimer = null;
            return;
        }

        if (_isBusy()) {
            _refreshingPaused = true;
            _log("MQTT Transport is busy now. Refresh token later.");
            return;
        }

        _log("Refreshing token...");
        _stateRefreshingToken = true;

        local disconnected = function () {
            _log("Disconnected");
            _mqttclient.connect(_options.url, _mqttClientId, _mqttCreds);
        }.bindenv(this);

        local tokenReady = function () {
            _mqttCreds.password = _jwtToken;
            _mqttclient.disconnect(disconnected);
        }.bindenv(this);

        _updateToken(tokenReady);
    }

    function _continueRefreshing() {
        if (!_isBusy()) {
            _refreshToken();
        }
    }

    function _isBusy() {
        if (_pubTelemetryReqs.len() > 0 || _reportStateReqs.len() > 0 || _stateSubscribing || _stateRefreshingToken) {
            return true;
        }
        return false;
    }

    function _resubscribe(callback) {
        if (_onConfigCb == null) {
            callback(0);
            return;
        }

        local topic = _topics.configuration;

        local subscribedCb = function (err, qos) {
            if (err == 0) {
                _log("Resubscribed");
            }
            callback(err);
        }.bindenv(this);

        _mqttclient.subscribe(topic, _options.qos, subscribedCb);
    }

    function _runPendingCalls() {
        foreach (call in _pendingCalls) {
            call();
        }
        _pendingCalls = [];
    }

    function _timeBeforeRefreshing() {
        local refreshAfter = _jwtExpiresAt - time();
        return refreshAfter > 0 ? refreshAfter : 0;
    }

    function _readyToEnable(isEnabling, enabled, disable, callback) {
        if (!_stateConnected || _stateDisconnecting) {
            callback && callback(_stateConnected ? GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW : GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED);
            return false;
        }

        if (isEnabling) {
            callback && callback(GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW);
            return false;
        }

        if (disable && !enabled) {
            // It is OK to disable a disabled feature
            callback && callback(0);
            return false;
        }

        return true;
    }

    function _cleanup() {
        _stateDisconnected      = true;
        _stateDisconnecting     = false;
        _stateConnected         = false;
        _stateConnecting        = false;
        _stateSubscribing       = false;
        _stateRefreshingToken   = false;

        _refreshingPaused       = false;

        _onConfigCb             = null;

        if (_refreshTokenTimer != null) {
            imp.cancelwakeup(_refreshTokenTimer);
            _refreshTokenTimer = null;
        }

        foreach (reqId, arr in _pubTelemetryReqs) {
            local data = arr[DATA_INDEX];
            local cb = arr[CALLBACK_INDEX];
            cb && cb(data, GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED);
        }
        _pubTelemetryReqs = {};

        foreach (reqId, arr in _reportStateReqs) {
            local data = arr[DATA_INDEX];
            local cb = arr[CALLBACK_INDEX];
            cb && cb(data, GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED);
        }
        _reportStateReqs = {};

        if (_onConfigEnabledCb != null) {
            _onConfigEnabledCb(GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED);
            _onConfigEnabledCb = null;
        }

        _runPendingCalls();
    }

    function _onMessage(msg) {
        local message = null;
        local topic = null;
        try {
            message = msg["message"];
            topic = msg["topic"];
            if (_debug) {
                _log(format("_onMessage: topic=%s | body=%s", topic, message.tostring()));
            }
        } catch (e) {
            _logError("Could not read message: " + e);
            return;
        }

        // Configuration received
        if (topic.find(_topics.configuration) != null) {
            _handleConfiguration(message, topic);
        }
    }

    function _handleConfiguration(message, topic) {
        _onConfigCb && _onConfigCb(message);
    }

    function _setDebug(value) {
        _debug = value;
    }

    function _setClient(client) {
        _client = client;
        _initTopics();
        _mqttClientId = format("projects/%s/locations/%s/registries/%s/devices/%s",
                                client._projectId, client._cloudRegion,
                                client._registryId, client._deviceId);
    }

    function _setTokenMaker(maker) {
        _makeToken = maker;
    }

    function _updateToken(callback) {
        if (_makeToken == null) {
            throw "Token maker is not set";
        }

        local tokenMade = function (token) {
            _jwtToken = token.jwtToken;
            _jwtExpiresAt = token.jwtExpiresAt;
            callback();
        }.bindenv(this);
        _makeToken(tokenMade);
    }

    function _logMsg(message, topic) {
        local text = format("===BEGIN MQTT MESSAGE===\nTopic: %s\nMessage: %s\n===END MQTT MESSAGE===", topic, message);
        _log(text);
    }

    // Information level logger
    function _log(txt) {
        if (_debug) {
            server.log("[" + (typeof this) + "] " + txt);
        }
    }

    // Error level logger
    function _logError(txt) {
        // TODO: use this method only for critical errors
        if (_debug) {
            server.error("[" + (typeof this) + "] " + txt);
        }
    }

    function _typeof() {
        return "GoogleIoTCore.MqttTransport";
    }
}
