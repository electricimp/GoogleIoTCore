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

The library API specification is described [here](#googleiotcore-library-specification), and a set of [working examples](./examples) are provided to help you make use of the library.

### Prerequisites ###

Before using the library you need to have a [Google IoT Core](https://cloud.google.com/iot-core/) account and the following information:

- A Project ID.
- A [Cloud Region](https://cloud.google.com/iot/docs/requirements#cloud_regions).
- A [Registry ID](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements).

Google IoT Core setup is described in the [instructions](./examples/README.md) for the examples.

The Project ID, Cloud Region and Registry ID may be the same for all of your devices and be hardcoded into your application. Alternatively, you may choose to obtain them &mdash; for example, from your own server &mdash; when the application is first used.

For every device you also need to have:

- A [Device ID](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements).
- At least one public/private key pair.

The Registry ID-Device ID combination must be unique for every device in your Project. For more information on public/private keys and Device IDs, please see the [Authentication And Registration](#authentication-and-registration) section.

Finally, you should decide which transport your application/device is going to use for communication with Google IoT Core. By default, MQTT (Message Queuing Telemetry Transport) with default options is used. If you want to configure MQTT yourself, you need to create an instance of the [GoogleIoTCore.MqttTransport](#googleiotcoremqtttransport-class-usage) class.

### Instantiation ###

To start working with the library, you should create an instance of the [GoogleIoTCore.Client](#googleiotcoreclient-class-usage) class. All of the settings discussed in the [Prerequisites](#prerequisites) section above are passed into the client's constructor. In addition, the constructor has further options which control the behavior of the library.

It is possible to instantiate several clients but note that Google IoT Core supports only one connection per device.

#### Example ####

```squirrel
#require "GoogleIoTCore.agent.lib.nut:1.0.0"

const GOOGLE_IOT_CORE_PROJECT_ID   = "<YOUR_GOOGLE_IOT_CORE_PROJECT_ID>";
const GOOGLE_IOT_CORE_CLOUD_REGION = "<YOUR_GOOGLE_IOT_CORE_CLOUD_REGION>";
const GOOGLE_IOT_CORE_REGISTRY_ID  = "<YOUR_GOOGLE_IOT_CORE_REGISTRY_ID>";
const GOOGLE_IOT_CORE_DEVICE_ID    = "<YOUR_GOOGLE_IOT_CORE_DEVICE_ID>";
const GOOGLE_IOT_CORE_PRIVATE_KEY  = "<YOUR_GOOGLE_IOT_CORE_PRIVATE_KEY>";

// Instantiate a client
client <- GoogleIoTCore.Client(GOOGLE_IOT_CORE_PROJECT_ID,
                               GOOGLE_IOT_CORE_CLOUD_REGION,
                               GOOGLE_IOT_CORE_REGISTRY_ID,
                               GOOGLE_IOT_CORE_DEVICE_ID,
                               GOOGLE_IOT_CORE_PRIVATE_KEY);
```

### Authentication And Registration ###

Google IoT Core security is described [here](https://cloud.google.com/iot/docs/concepts/device-security). A public/private RSA key pair must exist for every device, and the device must be registered with Google IoT Core. Elliptic Curve (ES) keys are also supported by Google IoT Core, but are not supported by the library.

The public key is saved inside Google IoT Core, so it is used only when registering a device.

The private key is used on the client side to create [JSON Web Tokens](https://cloud.google.com/iot/docs/how-tos/credentials/jwts) which are required to authenticate the device to Google IoT Core.

An example of how a public/private RSA key pair can be created is described [here](https://cloud.google.com/iot/docs/how-tos/credentials/keys).

It is recommended that every device should have its own public/private key pair. Moreover, several key pairs may exist for the same device and be rotated periodically. A key pair may have an expiration time. These and other security recommendations from Google are described [here](https://cloud.google.com/iot/docs/concepts/device-security#device_security_recommendations).

Assuming your project has a server, a device initialization process may look like this:

1. When your application starts for the first time it connects to your server and, optionally, passes the Device ID. It can be generated from the agent ID or any other unique ID in accordance with Google‘s [requirements](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements). The first character of the Device ID must be a letter.
1. If a Device ID is not received from the device's agent, the server generates the Device ID.
1. The server creates one or more public/private RSA key pairs for the device.
1. The server registers the device with Google IoT Core.
1. The server passes the private key(s), the Device ID (if it was not received from the device), as well as other settings mentioned in the [Prerequisites](#prerequisites) section and which are not hardcoded, to your application.
1. The application initializes the library by passing the settings to the [GoogleIoTCore.Client constructor](#constructor-googleiotcoreclientprojectid-cloudregion-registryid-deviceid-privatekey-onconnected-ondisconnected-transport-options).
1. The settings must be passed to the library every time the application restarts. For all non-hardcoded settings, you may decide either to obtain them from the server after every restart, or save them locally in agent persistent storage or device-side non-volatile memory.
1. A new private key should be obtained from the server if the existing key has an expiration time and is about to expire.

The GoogleIoTCore.Client constructor accepts only one private key. At any time your application can call [*setPrivateKey()*](#setprivatekeyprivatekey) to change the current private key, eg. for rotation, or when the key has expired.

See also the [Refreshing JSON Web Tokens Automatically](#refreshing-json-web-tokens-automatically) section.

#### Device Self-Registration ####

The library includes a [*register()*](#registeriss-secret-publickey-onregistered-name-keyformat) method to self-register a device with Google IoT Core. It may be used for quick prototypes, proof-of-concepts and demos. It is not recommended for production applications.

The [*register()*](#registeriss-secret-publickey-onregistered-name-keyformat) method requires additional settings to be hardcoded or obtained by an application, eg. from your server:

- A [JWT issuer](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#jwt-auth).
- A [JWT sign secret key](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#jwt-auth).
- The public key.

[*register()*](#registeriss-secret-publickey-onregistered-name-keyformat) does not require the library to be [connected](#connection) to Google IoT Core. It requires the [OAuth 2.0 library](https://developer.electricimp.com/libraries/utilities/oauth2).

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

    server.log("Successfully registered");
    client.connect();
}

client.register(GOOGLE_ISS, GOOGLE_SECRET_KEY, GOOGLE_IOT_CORE_PUBLIC_KEY, onRegistered);
```

### Connection ###

Tasks such as [publishing telemetry data](#publishing-telemetry), [reporting device state](#reporting-state) and [receiving device configurations](#configuration-reception) require the library to be connected to Google IoT Core.

To connect a [GoogleIoTCore.Client](#googleiotcoreclient-class-usage) instance, call the [*connect()*](#connect) method. Google IoT Core supports only one connection per device.

Your application can monitor a connection state using the [*isConnected()*](#isconnected) method, or the optional [*onConneced*](#callbacks) and [*onDisconnected*](#callbacks) callbacks. The callbacks may be specified in the [GoogleIoTCore.Client constructor](#constructor-googleiotcoreclientprojectid-cloudregion-registryid-deviceid-privatekey-onconnected-ondisconnected-transport-options) or set/reset later using the [*setOnConnected()*](#setonconnectedcallback) and/or [*setOnDisconnected()*](#setondisconnectedcallback) methods.

You can disconnect from Google IoT Core at any time by calling the [*disconnect()*](#disconnect) method, and reconnect by calling [*connect()*](#connect) again.

**Note** Google IoT Core can autonomously disconnect your device: for example, if the JSON Web Token expires (see [Refreshing JSON Web Tokens Automatically](#refreshing-json-web-tokens-automatically)).

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
    // Here is a good place to enable configuration reception
}

function onDisconnected(err) {
    if (err != 0) {
        server.error("Disconnected unexpectedly with code: " + err);
        
        // Reconnect if disconnection was not initiated by the application
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

### Refreshing JSON Web Tokens Automatically ###

A [JSON Web Token](https://cloud.google.com/iot/docs/how-tos/credentials/jwts) always has an expiration time, which is not the same as a private/public key expiration time. If the token has expired, Google IoT Core will disconnect the device. To prevent the disconnection, the token must be updated before its expiration.

The library implements token updating, which is enabled by default. For MQTT connections, the token is updated as follows:

1. A timer fires when the current token is near to expiration.
1. The library waits for all current MQTT operations to be completed.
1. The library generates a new token using the current private key.
1. The library disconnects from the MQTT broker.
1. The library re-connects to the MQTT broker using the new token as thee MQTT client's password.
1. The library subscribes to the topics to which it was subscribed before the reconnection.
1. The library sets a new timer to fire just before the new token is due to expire.

The library performs all these operations automatically and invisibly to an application. The [*onDisconnected*](#callbacks) and [*onConnected*](#callbacks) callbacks are not called. Any API calls made by the application during the update process are retained in a queue and processed once the token has been successfully updated. If the token can’t be updated, the [*onDisconnected*](#callbacks) callback is executed if set.

To generate a new token, the library uses the private key provided to the client. At any time the key can be updated by an application by calling the [*setPrivateKey()*](#setprivatekeyprivatekey) method. The new key will be used the next time the token needs to be updated.

To stop the token being updated automatically, you can set the *tokenAutoRefresh* option in the [GoogleIoTCore.Client constructor](#constructor-googleiotcoreclientprojectid-cloudregion-registryid-deviceid-privatekey-onconnected-ondisconnected-transport-options) to `false`. You may need to do this  if you wish to, for example, rotate the private key with every token update. In this case, your application may implement the following logic:

1. Set [*onConnected*](#callbacks) and [*onDisconnected()*](#callbacks) callbacks.
1. When the current JSON Web token has expired, Google IoT Core disconnects the device.
1. The [*onDisconnected()*](#callbacks) callback is executed by the library.
1. Call [*setPrivateKey()*](#setprivatekeyprivatekey) to change the current private key.
1. Call [*connect()*](#connect).
1. When the device is connected, the [*onConnected*](#callbacks) callback is executed by the library.
1. Re-enable [configuration reception](#configuration-reception), if needed.

### Publishing Telemetry ###

[Telemetry events](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#publishing_telemetry_events) can be published as soon as the client has successfully [connected](#connection).

Call [*publish()*](#publishdata-subfolder-onpublished) to send any application-specific data to Google IoT Core.

#### Example ####

```squirrel
// Publish a telemetry event without a callback
client.publish("some data", null);

function onPublished(data, err) {
    if (err != 0) {
        server.error("Publish telemetry error: code = " + err);
        
        // Trying to publish again in case of any error
        client.publish("some data", null, onPublished);
        return;
    }

    server.log("Telemetry has been published. Data = " + data);
}

// Publish a telemetry event with a callback
client.publish("some data", null, onPublished);
```

### Reporting State ###

A [device’s state](https://cloud.google.com/iot/docs/how-tos/config/getting-state#reporting_device_state) can be reported as soon as the client has successfully [connected](#connection).

Call [*reportState()*](#reportstatestate-onreported) to send an application-specific device state message to Google IoT Core.

This functionality may work with [configuration reception](#configuration-reception) or be used independently.

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

### Configuration Reception ###

[Receiving configuration information](https://cloud.google.com/iot/docs/how-tos/config/configuring-devices) is disabled by default and should be enabled every time that the client has successfully [connected](#connection). Call [*enableCfgReceiving()*](#enablecfgreceivingonreceive-ondone) to do this, or to disable the functionality manually.

Configuration reception may be used to transfer application-specific data from Google IoT Core to a device. For example:

- A new configuration (settings, firmware, etc.);
- A command to execute (reboot, etc.);
- Any other data (messages, etc.).

If a request (eg. a configuration or a command) from Google IoT Core expects an answer from a device, then [device state reports](#reporting-state) can be used to send the response. However, this is entirely application-specific.

#### Example ####

```squirrel
function onConfigReceived(config) {
    server.log("Configuration received: " + config.tostring());
}

function onDone(err) {
    if (err != 0) {
        server.error("Enabling configuration receiving failed: " + err);
    } else {
        server.log("Configuration reception enabled successfully");
    }
}

client.enableCfgReceiving(onConfigReceived, onDone);
```

### Pending Requests ###

[Telemetry data](#publishing-telemetry) and [device state report](#reporting-state) requests are made asynchronously, so several operations can be processed concurrently. But only limited number of pending operations of the same type is allowed. This number can be changed in the GoogleIoTCore.Client constructor's options. If you exceed this limit, the *GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW* error will be returned in response to your call.

### Error Processing ###

Most of the library’s methods return results via callbacks. Every callback includes an *error* parameter which indicates if the operation has been executed successfully (*error* is `0`) or has failed. An error code indicates the reason for the failure:

| Error Code | Error Name | Description |
| --- | --- | --- |
| -99..-1 and 128 | N/A | [MQTT-specific](https://developer.electricimp.com/api/mqtt) errors |
| 1000 | *GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED* | The client is not connected |
| 1001 | *GOOGLE_IOT_CORE_ERROR_ALREADY_CONNECTED* | The client is already connected |
| 1002 | *GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW* | The operation is not allowed now. For example, the same operation is already in flight |
| 1003 | *GOOGLE_IOT_CORE_ERROR_TOKEN_REFRESHING* | An error occurred while [refreshing the token](#refreshing-json-web-tokens-automatically). This error code can only be passed into the *onDisconnected* callback |
| 1004 | *GOOGLE_IOT_CORE_ERROR_ALREADY_REGISTERED* | Another device is already registered with the same Device ID |
| 1010 | *GOOGLE_IOT_CORE_ERROR_GENERAL* | A general error |

# GoogleIoTCore Library Specification #

## GoogleIoTCore.Client Class Usage ##

### Constructor: GoogleIoTCore.Client(*projectId, cloudRegion, registryId, deviceId, privateKey[, onConnected][, onDisconnected][, transport][, options]*) ###

This method returns a new GoogleIoTCore.Client instance.

#### Parameters ####

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *projectId* | String | Yes | The Project ID |
| *cloudRegion* | String | Yes | The [Cloud region](https://cloud.google.com/iot/docs/requirements#cloud_regions) |
| *registryId* | String | Yes | The [Registry ID](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements) |
| *deviceId* | String | Yes | The [Device ID](https://cloud.google.com/iot/docs/requirements#permitted_characters_and_size_requirements) |
| *privateKey* | String | Yes | The [private key](https://cloud.google.com/iot/docs/how-tos/credentials/keys) |
| *onConnected* | Function | Optional | A [callback](#callbacks) executed every time the client is connected. It is a good place to call [*enableCfgReceiving()*](#enablecfgreceivingonreceive-ondone) if this functionality is needed |
| *onDisconnected* | Function | Optional | A [callback](#callbacks) executed every time the client is disconnected |
| *transport* | GoogleIoTCore.&#42;Transport<br />instance | Optional | The default transport is a [GoogleIoTCore.MqttTransport](#googleiotcoremqtttransport-class) instance with default MQTT options |
| *options* | Table | Optional | Additional instance settings *(see below)* |

#### Options Table Keys ####

These additional settings affect the client's behavior and therefore the operations it is asked to perform. Every setting listed below is optional and has a default value.

| Key | Value Type | Description |
| --- | --- | --- |
| *maxPendingSetStateRequests* | Integer | Maximum number of pending [state report operations](#reporting-state) allowed. Default: 3 |
| *maxPendingPublishTelemetryRequests* | Integer | Maximum amount of pending [telemetry publishing operations](#publishing-telemetry) allowed. Default: 3 |
| *tokenTTL* | Integer | A [JWT token's lifetime](https://cloud.google.com/iot/docs/how-tos/credentials/jwts#required_claims) in seconds. Default: 3600 |
| *tokenAutoRefresh* | Boolean | Enable [automatic JWT refreshing](#refreshing-json-web-tokens-automatically). Default: `true` |

#### Callbacks ####

The callbacks that may be passed into *onConnected* and/or *onDisconnect* have one parameter of their own:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the operation completed successfully, otherwise an [error code](#error-processing) |

## GoogleIoTCore.Client Class Methods ##

### setOnConnected(*callback*) ###

This method sets the [*onConnected*](#callbacks) callback.

#### Parameters ####

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | The function to be called when the client has connected |

#### Return Value ####

Nothing.

### setOnDisconnected(*callback*) ###

This method sets the [*onDisconnected*](#callbacks) callback.

#### Parameters ####

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *callback* | Function | Yes | The function to be called when the client has disconnected |

#### Return Value ####

Nothing.

### setPrivateKey(*privateKey*) ###

This method sets the [private key](https://cloud.google.com/iot/docs/how-tos/credentials/keys).

#### Parameters ####

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *privateKey* | String | Yes | The private key value |

#### Return Value ####

Nothing.

### register(*iss, secret, publicKey[, onRegistered][, name][, keyFormat]*) ###

This method registers the device in Google IoT Core. It performs a minimal registration: only one private-public key pair, without expiration, is registered.

The method attempts to see if there is a device with the same ID as the one specified in the client’s constructor. If it finds a match, it compares the device's public key with the supplied key. If the keys match, the methods succeeds &mdash; it is assumed that the specified device has already been registered. Otherwise, it is assumed that *another* device is registered with the same ID, and the method returns the *GOOGLE_IOT_CORE_ERROR_ALREADY_REGISTERED* error.

If no device match is found, the method tries to register a new device.

**Important** If you intend to use this method, you **must** add `#require "OAuth2.agent.lib.nut:2.0.0"` to the top of your agent code.

#### Parameters ####

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *iss* | String | Yes | The [JWT issuer](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#jwt-auth) |
| *secret* | String | Yes | The [JWT sign secret key](https://developers.google.com/identity/protocols/OAuth2ServiceAccount#jwt-auth) |
| *publicKey* | String | Yes | The device's [public key](https://cloud.google.com/iot/docs/how-tos/credentials/keys). It must correspond to the private key set for the client |
| *onRegistered* | Function | Optional | The [callback](#onregistered) executed when the device is registered or an error occurs |
| *name* | String | Optional | The [device's name](https://cloud.google.com/iot/docs/reference/cloudiot/rest/v1/projects.locations.registries.devices#resource-device) |
| *keyFormat* | String | Optional | The [public key format](https://cloud.google.com/iot/docs/reference/cloudiot/rest/v1/projects.locations.registries.devices#publickeyformat). Default: `"RSA_X509_PEM"` |

#### onRegistered ####

The *onRegistered* parameter takes a function that has one parameter of its own:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the operation completed successfully, otherwise an [error code](#error-processing) |

#### Return Value ####

Nothing. The result of the operation may be obtained via the [*onRegistered* callback](#onregistered), if specified.

### connect() ###

This method opens a connection to Google IoT Core.

If the client is already connected, the [*onConnected*](#callbacks) callback will be called with the *GOOGLE_IOT_CORE_ERROR_ALREADY_CONNECTED* error.

Google IoT Core supports only one connection per device.

#### Return Value ####

Nothing. The result of the operation may be obtained via the [*onConnected* callback](#callbacks) specified in the client's constructor or set by calling [*setOnConnected()*](#setonconnectedcallback).

### disconnect() ###

This method closes the connection to Google IoT Core. It does nothing if the connection is already closed.

#### Return Value ####

Nothing. When the disconnection is completed, the [*onDisconnected*](#callbacks) callback is called, if specified in the client's constructor or set by calling [*setOnDisconnected()*](#setondisconnectedcallback).

### isConnected() ###

This method checks if the client is connected to Google IoT Core.

#### Return Value ####

Boolean &mdash; `true` if the client is connected, otherwise `false`.

### publish(*data[, subfolder][, onPublished]*) ###

This method [publishes a telemetry event to Google IoT Core](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#publishing_telemetry_events).

#### Parameters ####

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *data* | String or blob | Yes | Application-specific data. The application can use the [Serializer](https://developer.electricimp.com/libraries/utilities/serializer) library to convert Squirrel objects to blobs |
| *subfolder* | String | Optional | The sub-folder can be used as an event category or classification. For more information, please see [here](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#publishing_telemetry_events_to_separate_pubsub_topics) |
| *onPublished* | Function | Optional | A [callback](#onpublished) executed when the data is considered as published or an error occurs |

#### onPublished ####

The *onPublished* parameter takes a function that has two parameters of its own:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *data* | String or blob | The original *data* passed into *publish()* |
| *error* | Integer | `0` if the operation completed successfully, otherwise an [error code](#error-processing) |

#### Return Value ####

Nothing. The result of the operation may be obtained via the *onPublished* callback, if specified.

### enableCfgReceiving(*onReceive[, onDone]*) ###

This method enables/disables [the reception of configuration data from Google IoT Core](https://cloud.google.com/iot/docs/how-tos/config/configuring-devices). It is disabled by default and after every successful call to [*connect()*](#connect). 

To enable the feature, specify the [*onReceive*](#onreceive) callback. To disable the feature, pass `null` as that callback.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *onReceive* | Function  | Yes | A [Callback](#onreceive) called every time [a configuration](https://cloud.google.com/iot/docs/concepts/devices#device_configuration) is received from Google IoT Core |
| *onDone* | Function  | Optional | A [Callback](#ondone) called when the operation is complete or an error occurs |

#### onReceive ####

The *onReceive* parameter takes a function that has one parameter of its own:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *configuration* | Blob | The [configuration](https://cloud.google.com/iot/docs/concepts/devices#device_configuration) received. The application can use the [Serializer](https://developer.electricimp.com/libraries/utilities/serializer) library to convert blobs to Squirrel objects |

#### onDone ####

The *onDone* parameter takes a function that has one parameter of its own:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the operation completed successfully, otherwise an [error code](#error-processing) |

#### Return Value ####

Nothing. The result of the operation may be obtained via the [*onDone* callback](#ondone), if specified.

### reportState(*state[, onReported]*) ###

This method [reports a device's state](https://cloud.google.com/iot/docs/how-tos/config/getting-state#reporting_device_state) to Google IoT Core.

#### Parameters ####

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *state* | String or blob | Yes | A [device state](https://cloud.google.com/iot/docs/concepts/devices#device_state) record. The application can use the [Serializer](https://developer.electricimp.com/libraries/utilities/serializer) library to convert Squirrel objects to blobs |
| *onReported* | Function  | Optional | A [callback](#onreported) executed when the operation is completed or an error occurs |

#### onReported ####

The *onReported* parameter takes a function that has two parameter of its own:

| Parameter | Data Type | Description |
| --- | --- | --- |
| *state* | String or blob | The original *state* passed into *reportState()* |
| *error* | Integer | `0` if the operation completed successfully, otherwise an [error code](#error-processing) |

#### Return Value ####

Nothing. The result of the operation may be obtained via the [*onReported* callback](#onreported), if specified.

#### setDebug(*value*) ####

This method enables (*value* is `true`) or disables (*value* is `false`) the client debug output (including error logging). It is disabled by default. 

#### Return Value ####

Nothing.

## GoogleIoTCore.MqttTransport Class Usage ##

### Constructor: GoogleIoTCore.MqttTransport(*[options]*) ###

This method returns a new GoogleIoTCore.MqttTransport instance.

#### Parameters ####

| Parameter | Data Type | Required | Description |
| --- | --- | --- | --- |
| *options* | Table | Optional | Instance settings |

#### Options ####

These settings affect the transport's behavior and the operations. Every setting is optional and has a default value.

| Key | Value Type | Description |
| --- | --- | --- |
| *url* | String | MQTT broker URL formatted as `ssl://<hostname>:<port>`. Default: `"ssl://mqtt.googleapis.com:8883"` |
| *qos* | Integer | The MQTT quality of service setting. Google IoT Core supports [QoS 0 and 1 only](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#quality_of_service_qos). Default: 0 |
| *keepAlive* | Integer | The MQTT keep-alive time in seconds. For more information, please see [here](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge#keep-alive). Default: 60 |

**Note** Google IoT Core does not support the `retain` MQTT flag.

## Examples ##

Working examples are provided in the [examples](./examples) directory.

## Testing ##

Tests for the library are provided in the [tests](./tests) directory.

## License ##

This library is licensed under the [MIT License](./LICENSE).
