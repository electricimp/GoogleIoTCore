# GoogleIoTCore #

This library allows your agent code to work with [Google IoT Core](https://cloud.google.com/iot-core/).

This version of the library supports the following functionality:
- [Registering a device](https://cloud.google.com/iot/docs/how-tos/getting-started#device_registration) in Google IoT Core (optional feature).
- [Connecting and disconnecting](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge) to/from Google IoT Core.
- [Publishing telemetry events](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#publishing_telemetry_events) to Google IoT Core.
- [Receiving configurations](https://cloud.google.com/iot/docs/how-tos/config/configuring-devices) from Google IoT Core.
- [Reporting a device state](https://cloud.google.com/iot/docs/how-tos/config/getting-state#reporting_device_state) to Google IoT Core.

The library is designed to work with [different types of transports (HTTP or MQTT)](https://cloud.google.com/iot/docs/concepts/protocols), but only [MQTT transport](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge) is implemented at this point.

**To add this library to your project, add** `#require "GoogleIoTCore.agent.lib.nut:1.0.0"` **to the top of your agent code**.

## Library Usage ##

The library API specification is described [here](#api-specification).

The [working examples](./examples) are provided together with the library and described [here](./examples/README.md).

Below sections explain the main usage steps and recommendations.

### Prerequisites ###

Before using the library you need to have an account in [Google IoT Core](https://cloud.google.com/iot-core/), setup it for your project and obtain the following information:
- Project ID.
- [Cloud region](https://cloud.google.com/iot/docs/requirements#cloud_regions).
- [Registry ID](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements).

Google IoT Core setup is described in the [instruction](./examples/README.md) for the examples.

Project ID, Cloud region and Registry ID may be identical for all your devices and be pre-hardcoded in your application or obtained, eg. from your server/cloud, after the first start of the application.

Also, for every device you need to have:
- [Device ID](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements).
- Public/private keys pair.

Registry ID / Device ID combination must be unique for every device in your project. More information about public/private keys and Device ID see in the [Authentication and Registration](#authentication-and-registration) section.

Finally, you should decide which transport your application/device is going to use for communication with Google IoT Core. By default, MQTT transport with default [MQTT options](#options) is used. If you want to use non-default MQTT options, you need to create an instance of the [GoogleIoTCore.MqttTransport](#googleiotcoremqtttransport-class) class.

### Instantiation ###

To start working with the library you should create an instance of the [GoogleIoTCore.Client](#googleiotcoreclient-class) class. All settings mentioned in the [Prerequisites](#prerequisites) section are passed to the client's constructor. Also, the constructor has additional options which control the behavior of the library.

It is possible to instantiate several clients but note that Google IoT Core supports only one [connection](#connection) per device.

#### Example ####
```squirrel
#require "GoogleIoTCore.agent.lib.nut:1.0.0"

const GOOGLE_IOT_CORE_PROJECT_ID    = "<YOUR_GOOGLE_IOT_CORE_PROJECT_ID>";
const GOOGLE_IOT_CORE_CLOUD_REGION  = "<YOUR_GOOGLE_IOT_CORE_CLOUD_REGION>";
const GOOGLE_IOT_CORE_REGISTRY_ID   = "<YOUR_GOOGLE_IOT_CORE_REGISTRY_ID>";
const GOOGLE_IOT_CORE_DEVICE_ID     = "<YOUR_GOOGLE_IOT_CORE_DEVICE_ID>";
const GOOGLE_IOT_CORE_PRIVATE_KEY   = "<YOUR_GOOGLE_IOT_CORE_PRIVATE_KEY>";

// Instantiate a client
client <- GoogleIoTCore.Client(GOOGLE_IOT_CORE_PROJECT_ID,
                               GOOGLE_IOT_CORE_CLOUD_REGION,
                               GOOGLE_IOT_CORE_REGISTRY_ID,
                               GOOGLE_IOT_CORE_DEVICE_ID,
                               GOOGLE_IOT_CORE_PRIVATE_KEY);
```

### Authentication and Registration ###

Google IoT Core security is described [here](https://cloud.google.com/iot/docs/concepts/device-security).
A public/private RSA key pair(s) must exist for every device and the device must be registered in the Google IoT Core platform. Note, Elliptic Curve (ES) keys are also supported by Google IoT Core, but not supported by imp.

Public key is saved inside the Google IoT Core platform, so it is used only when registering a device in Google IoT Core.

Private key is used on the client's (device) side to create [JSON Web Tokens](https://cloud.google.com/iot/docs/how-tos/credentials/jwts) which are required to authenticate the device to Google IoT Core.

Example of how public/private RSA key pair can be created is described [here](https://cloud.google.com/iot/docs/how-tos/credentials/keys).

It is recommended that every device should have its own public/private key pair. Moreover, several key pairs may exist for the same device and be rotated periodically. Also, a key pair may have an expiration time. These and other security recommendations from Google are described [here](https://cloud.google.com/iot/docs/concepts/device-security#device_security_recommendations).

Assuming your project has a server/cloud, a device initialization process may look like this:
1. When your application on the device starts for the first time it connects to your server and, optionally, passes the Device ID (eg. it can be generated from imp-agent ID or any other unique ID in accordance with the Google [requirements](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements); note, the first character must be a letter).
1. If the Device ID is not received from the device, the server generates a unique Device ID.
1. The server creates public/private RSA key pair(s) for the device.
1. The server registers the device in Google IoT Core.
1. The server passes the private key(s), the Device ID (if it was not received from the device), as well as other settings mentioned in the [Prerequisites](#prerequisites) section and which are not pre-hardcoded, to your application.
1. The application initializes the library by passing the settings to the [GoogleIoTCore.Client constructor](#constructor-googleiotcoreclientprojectid-cloudregion-registryid-deviceid-privatekey-onconnected-ondisconnected-transport-options).
1. The settings must be passed to the library after every restart of the application. For all non-hardcoded settings you may decide either to obtain them from the server after every restart, or save them locally in a non-volatile memory.
1. New private key should be obtained from the server, if the existing key has an expiration time and is about to expire.

The GoogleIoTCore.Client constructor accepts only one private key. At any time your application can call [setPrivateKey()](#setprivatekeyprivatekey) method to change the current private key, eg. for a rotation purpose or when the key is expired.

See also [Automatic JWT Refreshing](#automatic-jwt-refreshing) section.

#### Device Self-Registration ####

The library includes a complementary [register()](#registeriss-secret-publickey-onregistered-name-keyformat) method to self-register a device in Google IoT Core. It may be used for quick prorotypes, Proof of Concepts and demos. It is not recommended for production-oriented applications.

The [register()](#registeriss-secret-publickey-onregistered-name-keyformat) method requires additional settings to be pre-hardcoded or obtained by an application, eg. from your server/cloud:
- [JWT issuer](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#jwt-auth).
- [JWT sign secret key](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#jwt-auth).
- Public key.

The [register()](#registeriss-secret-publickey-onregistered-name-keyformat) method does not require the library to be [connected](#connection) to Google IoT Core.

The [register()](#registeriss-secret-publickey-onregistered-name-keyformat) method requires [OAuth 2.0 library](https://github.com/electricimp/OAuth-2.0).

#### Example ####
```squirrel
const GOOGLE_ISS = "<YOUR_GOOGLE_ISS>";
const GOOGLE_SECRET_KEY = "<YOUR_GOOGLE_SECRET_KEY>";
const GOOGLE_IOT_CORE_PUBLIC_KEY = "<YOUR_GOOGLE_IOT_CORE_PUBLIC_KEY>";

function onRegistered(err) {
    if (err != 0) {
        server.error("Registration error: code = " + err);
        return;
    }
    server.log("Successfully registered!");
    client.connect();
}

client.register(GOOGLE_ISS, GOOGLE_SECRET_KEY, GOOGLE_IOT_CORE_PUBLIC_KEY, onRegistered);
```

### Connection ###

[Telemetry Publishing](#telemetry-publishing), [State Reporting](#state-reporting) and [Configuration Receiving](#configuration-receiving) functionalities require the library to be connected to Google IoT Core.

To connect the newly instantiated [GoogleIoTCore.Client](#googleiotcoreclient-class) call the [connect()](#connect) method. Google IoT Core supports only one connection per device.

Your application can monitor a connection state using the [isConnected()](#isconnected) method or the optional [onConnected()](#callback-onconnectederror) and [onDisconnected()](#callback-ondisconnectederror) callbacks. The callbacks may be specified in the [GoogleIoTCore.Client constructor](#constructor-googleiotcoreclientprojectid-cloudregion-registryid-deviceid-privatekey-onconnected-ondisconnected-transport-options) or set/reset later using the [setOnConnected()](#setonconnectedcallback), [setOnDisconnected()](#setondisconnectedcallback) methods.

At any time you can disconnect from Google IoT Core by calling the [disconnect()](#disconnect) method and reconnect by calling the [connect()](#connect) method again.

Note, Google IoT Core can disconnect your device. Eg. due to the JSON Web Token expiration - see [Automatic JWT Refreshing](#automatic-jwt-refreshing) section.

#### Example ####
```squirrel
const GOOGLE_IOT_CORE_PROJECT_ID    = "<YOUR_GOOGLE_IOT_CORE_PROJECT_ID>";
const GOOGLE_IOT_CORE_CLOUD_REGION  = "<YOUR_GOOGLE_IOT_CORE_CLOUD_REGION>";
const GOOGLE_IOT_CORE_REGISTRY_ID   = "<YOUR_GOOGLE_IOT_CORE_REGISTRY_ID>";
const GOOGLE_IOT_CORE_DEVICE_ID     = "<YOUR_GOOGLE_IOT_CORE_DEVICE_ID>";
const GOOGLE_IOT_CORE_PRIVATE_KEY   = "<YOUR_GOOGLE_IOT_CORE_PRIVATE_KEY>";

function onConnected(err) {
    if (err != 0) {
        server.error("Connect failed: " + err);
        return;
    }
    server.log("Connected");
    // Here is a good place to enable configuration receiving
}

function onDisconnected(err) {
    if (err != 0) {
        server.error("Disconnected unexpectedly with code: " + err);
        // Reconnect if disconnection is not initiated by application
        client.connect();
    } else {
        server.log("Disconnected by application");
    }
}

// Instantiate and connect a client
client <- GoogleIoTCore.Client(GOOGLE_IOT_CORE_PROJECT_ID,
                               GOOGLE_IOT_CORE_CLOUD_REGION,
                               GOOGLE_IOT_CORE_REGISTRY_ID,
                               GOOGLE_IOT_CORE_DEVICE_ID,
                               GOOGLE_IOT_CORE_PRIVATE_KEY,
                               onConnected,
                               onDisconnected);
client.connect();
```

### Automatic JWT Refreshing ###

[JSON Web Token](https://cloud.google.com/iot/docs/how-tos/credentials/jwts) always has an expiration time (do not mess it with a private/public key expiration time). If the token is expired, Google IoT Core disconnects the device. To prevent the disconnection the token must be updated before its expiration.

The library implements the token updating algorithm. It is enabled by default.

For MQTT Transport the token updating algorithm is the following:
1. Using a timer wakes up when the current token is near to expiration.
1. Waits for all current MQTT operations to be finished.
1. Calculates a new token using the current private key.
1. Disconnects from the MQTT broker.
1. Connects to the MQTT broker again using the new token as an MQTT client's password.
1. Subscribes to the topics which were subscribed to before the reconnection.
1. Sets the timer for the new token expiration.

The library does all these operations automatically and invisibly to an application. The [onDisconnected()](#callback-ondisconnectederror) and [onConnected()](#callback-onconnectederror) callbacks are not called. All the API calls, made by the application at the time of updating, are scheduled in a queue and processed right after the token updating algorithm is successfuly finished. If the token update fails, the [onDisconnected()](#callback-ondisconnectederror) callback is called (if the callback has been set).

To calculate a new token the library uses the current private key provided to the client. At any time the key can be updated by an application by calling the [setPrivateKey()](#setprivatekeyprivatekey) method. The new key will be used during the next updating of the token.

To disable the automatic token updating algorithm you can set the `tokenAutoRefresh` [client's option](#options-1) in the [GoogleIoTCore.Client constructor](#constructor-googleiotcoreclientprojectid-cloudregion-registryid-deviceid-privatekey-onconnected-ondisconnected-transport-options) to `False`.
You may need this, eg. to rotate the private key with every token update. In this case, your application may implement the following logic:
1. Set [onConnected()](#callback-onconnectederror) and [onDisconnected()](#callback-ondisconnectederror) callbacks.
1. When the current JSON Web token is expired, Google IoT Core disconnects the device.
1. The [onDisconnected()](#callback-ondisconnectederror) callback is called by the library.
1. Call the [setPrivateKey()](#setprivatekeyprivatekey) method to change the current private key.
1. Call the [connect()](#connect) method.
1. When the device is connected, the [onConnected()](#callback-onconnectederror) callback is called by the library.
1. Re-enable [Configuration Receiving](#configuration-receiving) functionality, if needed.

### Telemetry Publishing ###

[Telemetry Publishing](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#publishing_telemetry_events) functionality is available right after the client is successfully [connected](#connection).

Call the [publish()](#publishdata-subfolder-onpublished) method to send any application-specific data to Google IoT Core.

#### Example ####
```squirrel
// Publish a telemetry event without a callback
client.publish("some data", null);

function onPublished(data, err) {
    if (err != 0) {
        server.error("Publish telemetry error: code = " + err);
        // For example simplicity trying to publish again in case of any error
        client.publish("some data", null, onPublished);
        return;
    }
    server.log("Telemetry has been published. Data = " + data);
}

// Publish a telemetry event with a callback
client.publish("some data", null, onPublished);
```

### State Reporting ###

[State Reporting](https://cloud.google.com/iot/docs/how-tos/config/getting-state#reporting_device_state) functionality is available right after the client is successfully [connected](#connection).

Call the [reportState()](#reportstatestate-onreported) method to send an application-specific state of the device to Google IoT Core.

This functionality may work in a pair with [Configuration Receiving](#configuration-receiving) functionality or be totally independent from it.

#### Example ####
```squirrel
client.reportState("some state", onReported);

function onReported(state, err) {
    if (err != 0) {
        server.error("Report state error: code = " + err);
        return;
    }
    server.log("State has been reported!");
}
```

### Configuration Receiving ###

[Configuration Receiving](https://cloud.google.com/iot/docs/how-tos/config/configuring-devices) functionality is disabled by default and should be re-enabled every time after the client is successfully [connected](#connection).

Call the [enableCfgReceiving()](#enablecfgreceivingonreceive-ondone) method to enable/re-enable/disable it.

Configuration Receiving functionality may be used to pass an application-specific data from Google IoT Core to a device, eg.:
- a new configuration (settings, firmware, etc.);
- a command to execute (reboot, etc.);
- any other data (messages, etc.).

If a request (eg. a configuration or a command) from Google IoT Core assumes an answer from a device, then, usually, [State Reporting](#state-reporting) functionality is used to provide an answer. But this is fully application-specific.

#### Example ####
```squirrel
function onConfigReceived(config) {
    server.log("Configuration received: " + config.tostring());
}

function onDone(err) {
    if (err != 0) {
        server.error("Enabling configuration receiving failed: " + err);
    } else {
        server.log("Configuration receiving enabled successfully");
    }
}

client.enableCfgReceiving(onConfigReceived, onDone);
```

### Pending Requests ###

[Telemetry Publishing](#telemetry-publishing) and [State Reporting](#state-reporting) requests are made asynchronously, so several operations can be processed concurrently. But only limited number of pending operations of the same type is allowed. This number can be changed in [the client's options](#options-1) of the GoogleIoTCore.Client constructor. If you exceed this number, the `GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW` error will be returned in response to your call.

### Errors Processing ###

The most of methods of the library return results via callbacks. And every callback include the `error` parameter which indicates if the operation has been executed successfully (`error` is `0`) or has been failed. Different [error codes](#error-codes) include errors returned by the transports and the errors from the library.

## API Specification ##

### GoogleIoTCore.MqttTransport Class ###

#### Constructor: GoogleIoTCore.MqttTransport(*[options]*) ####

This method returns a new GoogleIoTCore.MqttTransport instance.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *options* | Table | Optional | Key-value table with the [transport's settings](#options). |

##### Options #####

These settings affect the transport's behavior and the operations. Every setting is optional and has a default.

| Key (String) | Value Type | Default | Description |
| --- | --- | --- | --- |
| "url" | String | `ssl://mqtt.googleapis.com:8883` | MQTT broker URL formatted as `ssl://<hostname>:<port>`. |
| "qos" | Integer | 0 | MQTT QoS. [Google IoT Core supports QoS 0 and 1 only](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#quality_of_service_qos). |
| "keepAlive" | Integer | 60 | Keep-alive MQTT parameter, in seconds. For more information, see [here](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#keep-alive). |

Note, Google IoT Core does not support the `retain` MQTT flag.

### GoogleIoTCore.Client Class ###

#### Constructor: GoogleIoTCore.Client(*projectId, cloudRegion, registryId, deviceId, privateKey[, onConnected[, onDisconnected[, transport[, options]]]]*) ####

This method returns a new GoogleIoTCore.Client instance.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *projectId* | String | Yes | Project ID. |
| *cloudRegion* | String | Yes | [Cloud region](https://cloud.google.com/iot/docs/requirements#cloud_regions). |
| *registryId* | String | Yes | [Registry ID](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements). |
| *deviceId* | String | Yes | [Device ID](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements). |
| *privateKey* | String | Yes | [Private key](https://cloud.google.com/iot/docs/how-tos/credentials/keys). |
| *onConnected* | Function | Optional | [Callback](#callback-onconnectederror) called every time the client is connected. |
| *onDisconnected* | Function | Optional | [Callback](#callback-ondisconnectederror) called every time the client is disconnected. |
| *transport* | GoogleIoTCore.\*Transport  | Optional | Instance of GoogleIoTCore.\*Transport class. Default transport is [GoogleIoTCore.MqttTransport](#googleiotcoremqtttransport-class) with default [MQTT options](#options). |
| *options* | Table | Optional | Key-value table with additional [settings](#options-1). |

##### Callback: onConnected(*error*) #####

This callback is called every time the client is connected.

This is a good place to call the [enableCfgReceiving()](#enablecfgreceivingonreceive-ondone) method, if this functionality is needed.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the connection is successful, an [error code](#error-codes) otherwise. |

##### Callback: onDisconnected(*error*) #####

This callback is called every time the client is disconnected.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the disconnection was caused by the [disconnect()](#disconnect) method, an [error code](#error-codes) which explains a reason of the disconnection otherwise. |

##### Options #####

These additional settings affect the client's behavior and the operations. Every setting is optional and has a default.

| Key (String) | Value Type | Default | Description |
| --- | --- | --- | --- |
| "maxPendingSetStateRequests" | Integer | 3 | Maximum amount of pending [State Reporting operations](#reportstatestate-onreported). |
| "maxPendingPublishTelemetryRequests" | Integer | 3 | Maximum amount of pending [Telemetry Publishing operations](#publishdata-subfolder-onpublished). |
| "tokenTTL" | Integer | 3600 | [JWT token's time to live](https://cloud.google.com/iot/docs/how-tos/credentials/jwts#required_claims), in seconds. |
| "tokenAutoRefresh" | Boolean | True | Enable [Automatic JWT Refreshing](#automatic-jwt-refreshing). |

#### setOnConnected(*callback*) ####

This method sets [*onConnected*](#callback-onconnectederror) callback. The method returns nothing.

#### setOnDisconnected(*callback*) ####

This method sets [*onDisconnected*](#callback-ondisconnectederror) callback. The method returns nothing.

#### setPrivateKey(*privateKey*) ####

This method sets [Private key](https://cloud.google.com/iot/docs/how-tos/credentials/keys). The method returns nothing.

#### register(*iss, secret, publicKey[, onRegistered[, name[, keyFormat]]]*) ####

This complementary method registers the device in Google IoT Core.

It makes the minimal required registration - only one private-public key pair, without expiration setting, is registered.

First, the method attempts to find already existing device with the device ID specified in the client’s constructor and compare that device's public key with the key passed in. And then:
- If no device found, the method tries to register the new one.
- Else if a device is found and the keys are identical, the method succeeds, assuming the device is already registered.
- Otherwise it is assumed that **another** device is registered with the same ID and the method returns the `GOOGLE_IOT_CORE_ERROR_ALREADY_REGISTERED` error.

**If you are going to use this method, add** `#require "OAuth2.agent.lib.nut:2.0.0"` **to the top of your agent code**.

The method returns nothing. A result of the operation may be obtained via the [*onRegistered*](#callback-onregisterederror) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *iss* | String  | Yes | [JWT issuer](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#jwt-auth). |
| *secret* | String  | Yes | [JWT sign secret key](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#jwt-auth). |
| *publicKey* | String  | Yes | [Public key](https://cloud.google.com/iot/docs/how-tos/credentials/keys) for the device. It must correspond to the private key set for the client. |
| *onRegistered* | Function  | Optional | [Callback](#callback-onregisterederror) called when the operation is completed or an error occurs. |
| *name* | String | Optional | [Device name](https://cloud.google.com/iot/docs/reference/cloudiot/rest/v1/projects.locations.registries.devices#resource-device). |
| *keyFormat* | String | Optional | [Public key format](https://cloud.google.com/iot/docs/reference/cloudiot/rest/v1/projects.locations.registries.devices#publickeyformat). If not specified or `null`, `RSA_X509_PEM` is applied. |

##### Callback: onRegistered(*error*) ######

This callback is called when the device is registered.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the operation is completed successfully, an [error code](#error-codes) otherwise. |

#### connect() ####

This method opens a connection to Google IoT Core.

If already connected, the [*onConnected*](#callback-onconnectederror) callback will be called with the `GOOGLE_IOT_CORE_ERROR_ALREADY_CONNECTED` error.

Google IoT Core supports only one connection per device.

The method returns nothing. A result of the operation may be obtained via the [*onConnected*](#callback-onconnectederror) callback specified in the client's constructor or set by calling [setOnConnected()](#setonconnectedcallback) method.

#### disconnect() ####

This method closes the connection to Google IoT Core. Does nothing if the connection is already closed.

The method returns nothing. When the disconnection is completed the [*onDisconnected*](#callback-ondisconnectederror) callback is called, if specified in the client's constructor or set by calling [setOnDisconnected()](#setondisconnectedcallback) method.

#### isConnected() ####

This method checks if the client is connected to Google IoT Core.

The method returns Boolean: `true` if the client is connected, `false` otherwise.

#### publish(*data[, subfolder[, onPublished]]*) ####

This method [publishes a telemetry event to Google IoT Core](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#publishing_telemetry_events).

The method returns nothing. A result of the operation may be obtained via the [*onPublished*](#callback-onpublisheddata-error) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *data* | String or Blob  | Yes | Application specific data. Application can use the [Serializer](https://developer.electricimp.com/libraries/utilities/serializer) library to convert Squirrel objects to Blobs. |
| *subfolder* | String  | Optional | The subfolder can be used as an event category or classification. For more information, see [here](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#publishing_telemetry_events_to_separate_pubsub_topics). |
| *onPublished* | Function  | Optional | [Callback](#callback-onpublisheddata-error) called when the operation is completed or an error occurs. |

##### Callback: onPublished(*data, error*) ######

This callback is called when the data is considered as published or an error occurs.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *data* | String or Blob | The original *data* passed in to the [publish()](#publishdata-subfolder-onpublished) method. |
| *error* | Integer | `0` if the operation is completed successfully, an [error code](#error-codes) otherwise. |

#### enableCfgReceiving(*onReceive[, onDone]*) ####

This method enables/disables [configuration receiving from Google IoT Core](https://cloud.google.com/iot/docs/how-tos/config/configuring-devices).

Disabled by default and after every successful [connect()](#connecttransport) method call. 

To enable the feature, specify the [*onReceive*](#callback-onreceiveconfiguration) callback. To disable the feature, specify `null` as that callback.

The method returns nothing. A result of the operation may be obtained via the [*onDone*](#callback-ondoneerror) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *onReceive* | Function  | Yes | [Callback](#callback-onreceiveconfiguration) called every time a configuration is received from Google IoT Core. `null` disables the feature. |
| *onDone* | Function  | Optional | [Callback](#callback-ondoneerror) called when the operation is completed or an error occurs. |

##### Callback: onReceive(*configuration*) #####

This callback is called every time [a configuration](https://cloud.google.com/iot/docs/concepts/devices#device_configuration) is received.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *configuration* | Blob | [Configuration](https://cloud.google.com/iot/docs/concepts/devices#device_configuration). An arbitrary user-defined blob. Application can use the [Serializer](https://developer.electricimp.com/libraries/utilities/serializer) library to convert Blobs to Squirrel objects. |

##### Callback: onDone(*error*) #####

This callback is called when the method is completed.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the operation is completed successfully, an [error code](#error-codes) otherwise. |

#### reportState(*state[, onReported]*) ####

This method [reports a device state to Google IoT Core](https://cloud.google.com/iot/docs/how-tos/config/getting-state#reporting_device_state).

The method returns nothing. A result of the operation may be obtained via the [*onReported*](#callback-onreportedstate-error) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *state* | String or Blob  | Yes | [Device state](https://cloud.google.com/iot/docs/concepts/devices#device_state). Application specific data. Application can use the [Serializer](https://developer.electricimp.com/libraries/utilities/serializer) library to convert Squirrel objects to Blobs. |
| *onReported* | Function  | Optional | [Callback](#callback-onreportedstate-error) called when the operation is completed or an error occurs. |

##### Callback: onReported(*state, error*) #####

This callback is called when the state is considered as reported or an error occurs.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *state* | String or Blob | The original *state* passed in to the [reportState()](#reportstatestate-onreported) method. |
| *error* | Integer | `0` if the operation is completed successfully, an [error code](#error-codes) otherwise. |

#### setDebug(*value*) ####

This method enables (*value* is `true`) or disables (*value* is `false`) the client debug output (including error logging). It is disabled by default. The method returns nothing.

### Error Codes ###

An *Integer* error code which specifies a concrete error (if any) happened during an operation.

| Error Code | Error Name | Description |
| --- | --- | --- |
| -99..-1 and 128 | | [MQTT-specific](https://developer.electricimp.com/api/mqtt) errors. |
| 1000 | GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED | The client is not connected. |
| 1001 | GOOGLE_IOT_CORE_ERROR_ALREADY_CONNECTED | The client is already connected. |
| 1002 | GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW | The operation is not allowed now. E.g. the same operation is already in process. |
| 1003 | GOOGLE_IOT_CORE_ERROR_TOKEN_REFRESHING | An error occured while [refreshing the token](#automatic-jwt-refreshing). This error code can only be passed in to the [*onDisconnected*](#callback-ondisconnectederror) callback. |
| 1004 | GOOGLE_IOT_CORE_ERROR_ALREADY_REGISTERED | Another device is already registered with the same Device ID. |
| 1010 | GOOGLE_IOT_CORE_ERROR_GENERAL | General error. |

## Examples ##

Working examples are provided in the [examples](./examples) directory and described [here](./examples/README.md).

## Testing ##

Tests for the library are provided in the [tests](./tests) directory and described [here](./tests/README.md).

## License ##

The GoogleIoTCore library is licensed under the [MIT License](./LICENSE).
