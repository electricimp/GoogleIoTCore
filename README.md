# GoogleIoTCore #

This library allows your agent code to work with Google IoT Core.

This version of the library supports the following functionality:
- Registering a device in Google IoT Core (optional feature).
- Connecting and disconnecting to/from Google IoT Core.
- Publishing telemetry events to Google IoT Core.
- Receiving configurations from Google IoT Core.
- Reporting a device state to Google IoT Core.

The library provides an opportunity to work via [different transports](https://cloud.google.com/iot/docs/concepts/protocols?hl=ru), but currently supports only [MQTT transport](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge?hl=ru).

**To add this library to your project, add** `#require "GoogleIoTCore.agent.lib.nut:1.0.0"` **to the top of your agent code**.

## Library Usage ##

### Automatic JWT Token Refreshing ###

TODO

### Pending Requests ###

TODO

### Production Flow ###

TODO

## GoogleIoTCore.MqttTransport Class ##

### Constructor: GoogleIoTCore.MqttTransport(*[options]*) ###

This method returns a new GoogleIoTCore.MqttTransport instance.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| [*options*](#options) | Table | Optional | Key-value table with settings. |

#### Options ####

These settings affect the transport's behavior and the operations. Every setting is optional and has a default.

| Key (String) | Value Type | Default | Description |
| --- | --- | --- | --- |
| "url" | String | `ssl://mqtt.googleapis.com:8883` | MQTT broker URL formatted as `ssl://<hostname>:<port>`. |
| "qos" | Integer | 0 | MQTT QoS. [Google IoT Core supports QoS 0 and 1 only](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge?hl=ru#quality_of_service_qos). |
| "keepAlive" | Integer | 60 | Keep-alive MQTT parameter. For more information, see [here](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge?hl=ru#keep-alive). |

Google IoT Core does not support the `retain` MQTT flag, so this library does not support it too.

**Note**: TODO place some general info about MQTT in Google IoT Core?

## GoogleIoTCore.Client Class ##

### Constructor: GoogleIoTCore.Client(*projectId, cloudRegion, registryId, deviceId, privateKey[, onConnected[, onDisconnected[, options]]]*) ###

This method returns a new GoogleIoTCore.Client instance.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *projectId* | String | Yes | [Project ID](https://cloud.google.com/iot/docs/requirements?hl=ru#permitted_characters_and_size_requirements). |
| *cloudRegion* | String | Yes | [Cloud region](https://cloud.google.com/iot/docs/requirements?hl=ru#cloud_regions). |
| *registryId* | String | Yes | [Registry ID](https://cloud.google.com/iot/docs/requirements?hl=ru#permitted_characters_and_size_requirements). |
| *deviceId* | String | Yes | [Device ID](https://cloud.google.com/iot/docs/requirements?hl=ru#permitted_characters_and_size_requirements). |
| *privateKey* | String | Yes | [Private key](https://cloud.google.com/iot/docs/how-tos/credentials/keys?hl=ru). |
| [*onConnected*](#callback-onconnectederror) | Function | Optional | Callback called every time the client is connected. |
| [*onDisconnected*](#callback-ondisconnectederror) | Function | Optional | Callback called every time the client is disconnected. |
| [*options*](#options-1) | Table | Optional | Key-value table with settings. |

#### Callback: onConnected(*error*) ####

This callback is called every time the client is connected.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the connection is successful, an [error code](TODO) otherwise. |

#### Callback: onDisconnected(*error*) ####

This callback is called every time the client is disconnected.

This is a good place to call the [connect()](#connect) method again if it was an unexpected disconnection.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the disconnection was caused by the disconnect() method, an [error code](TODO) which explains a reason of the disconnection otherwise. |

#### Options ####

These settings affect the client's behavior and the operations. Every setting is optional and has a default.

| Key (String) | Value Type | Default | Description |
| --- | --- | --- | --- |
| "maxPendingSetStateRequests" | Integer | 3 | Maximum amount of pending [Set State operations](TODO). |
| "maxPendingPublishTelemetryRequests" | Integer | 3 | Maximum amount of pending [Publish Telemetry operations](TODO). |

#### Example ####

```squirrel
#require "GoogleIoTCore.agent.lib.nut:1.0.0"
```

### register(*iss, secret, publicKey[, onRegistered]*) ###

This method registers a device in Google IoT Core.

The method attempts to find already existing device with the device ID specified in the client’s constructor and compare that device’s public key with the key passed in. If no device found, the method tries to create one. If any device is found and keys are identical, the method succeeds. Otherwise, the method returns an error.

The method returns nothing. A result of the operation may be obtained via the [*onDone*](#callback-ondoneerror) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *iss* | String  | Yes | JWT issuer. |
| *secret* | String  | Yes | JWT sign secret key. |
| *publicKey* | String  | Yes | [Public key](https://cloud.google.com/iot/docs/how-tos/credentials/keys?hl=ru) for a new device. |
| *[onRegistered](#callback-onregisterederror)* | Function  | Optional | Callback called when the operation is completed or an error occurs. |

#### Callback: onRegistered(*error*) #####

This callback is called when the data is considered as sent or an error occurs.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *[error](#error-code)* | Integer | `0` if the operation is completed successfully, an [error code](#error-code) otherwise. |

### connect(*[transport]*) ###

This method opens a connection to Google IoT Core.

Default transport is [GoogleIoTCore.MqttTransport](#googleiotcoremqtttransport-class) with default configuration.

Google IoT Core supports only one connection per device.

The method returns nothing. A result of the operation may be obtained via the [*onConnected*](#callback-onconnectederror) callback specified in the client's constructor or set by calling [setOnConnected()](#setonconnectedcallback) method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *transport* | GoogleIoTCore.\*Transport  | Optional | Instance of GoogleIoTCore.\*Transport class. |

### disconnect() ###

This method closes the connection to Google IoT Core. Does nothing if the connection is already closed.

The method returns nothing. When the disconnection is completed the [*onDisconnected*](#callback-ondisconnectederror) callback is called, if specified in the client's constructor or set by calling [setOnDisconnected()](#setondisconnectedcallback) method.

### isConnected() ###

This method checks if the client is connected to Google IoT Core.

The method returns Boolean: `true` if the client is connected, `false` otherwise.

### publish(*data[, subfolder[, onPublished]]*) ###

This method [publishes a telemetry event to Google IoT Core](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge?hl=ru#publishing_telemetry_events).

The method returns nothing. A result of the operation may be obtained via the [*onDone*](#callback-ondoneerror) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *data* | String or Blob  | Yes | Application specific data. You can use the [Serializer](https://developer.electricimp.com/libraries/utilities/serializer) library to convert Squirrel objects to Blobs. |
| *subfolder* | String  | Optional | The subfolder can be used as an event category or classification. For more information, see [here](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge?hl=ru#publishing_telemetry_events_to_separate_pubsub_topics). |
| *[onPublished](#callback-onpublisheddata-error)* | Function  | Optional | Callback called when the operation is completed or an error occurs. |

#### Callback: onPublished(*data, error*) #####

This callback is called when the data is considered as sent or an error occurs.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *data* | String or Blob | The original *data* passed in to the [publish()](#publishdata-subfolder-onpublished) method. |
| *[error](#error-code)* | Integer | `0` if the operation is completed successfully, an [error code](#error-code) otherwise. |

### enableCfgReceiving(*onReceive[, onDone]*) ###

This method enables [configuration receiving from Google IoT Core](https://cloud.google.com/iot/docs/how-tos/config/configuring-devices?hl=ru).

To enable the feature, specify the [*onReceive*](TODO) callback. To disable the feature, specify `null` as that callback.

The method returns nothing. A result of the operation may be obtained via the [*onDone*](#callback-ondoneerror) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *onReceive* | Function  | Yes | [Callback](TODO) called every time a configuration is received from Google IoT Core. `null` disables the feature. |
| *[onDone](#callback-ondoneerror)* | Function  | Optional | [Callback](TODO) called when the operation is completed or an error occurs. |

#### Callback: onReceive(*configuration*) ####

This callback is called every time [a configuration](https://cloud.google.com/iot/docs/concepts/devices?hl=ru#device_configuration) is received.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *configuration* | Blob | [Configuration](https://cloud.google.com/iot/docs/concepts/devices?hl=ru#device_configuration). An arbitrary user-defined blob. |

#### Callback: onDone(*error*) #####

This callback is called when a method is completed.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *[error](#error-code)* | Integer | `0` if the operation is completed successfully, an [error code](#error-code) otherwise. |

#### Example ####

```squirrel
```

### reportState(*state[, onReported]*) ###

This method [reports a device state to Google IoT Core](https://cloud.google.com/iot/docs/how-tos/config/getting-state?hl=ru#reporting_device_state).

The method returns nothing. A result of the operation may be obtained via the [*onDone*](#callback-ondoneerror) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *state* | String or Blob  | Yes | [Device state](https://cloud.google.com/iot/docs/concepts/devices?hl=ru#device_state). Application specific data. You can use the [Serializer](https://developer.electricimp.com/libraries/utilities/serializer) library to convert Squirrel objects to Blobs. |
| *[onReported](#callback-onreportedstate-error)* | Function  | Optional | Callback called when the operation is completed or an error occurs. |

#### Callback: onReported(*state, error*) #####

This callback is called when the state is considered as sent or an error occurs.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *state* | String or Blob | The original *state* passed in to the [reportState()](#reportstatestate-onreported) method. |
| *[error](#error-code)* | Integer | `0` if the operation is completed successfully, an [error code](#error-code) otherwise. |

#### Example ####

```squirrel
```

### setOnConnected(*callback*) ###

This method sets [*onConnected*](#callback-onconnectederror) callback. The method returns nothing.

### setOnDisconnected(*callback*) ###

This method sets [*onDisconnected*](#callback-ondisconnectedreason) callback. The method returns nothing.

### setDebug(*value*) ###

This method enables (*value* is `true`) or disables (*value* is `false`) the client debug output (including error logging). It is disabled by default. The method returns nothing.

### Error Codes ###

An *Integer* error code which specifies a concrete error (if any) happened during an operation.

| Error Code | Error Name | Description |
| --- | --- | --- |
| 1000 | GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED | The client is not connected. |
| 1001 | GOOGLE_IOT_CORE_ERROR_ALREADY_CONNECTED | The client is already connected. |
| 1002 | GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW | The operation is not allowed now. E.g. the same operation is already in process. |
| 1003 | GOOGLE_IOT_CORE_ERROR_TOKEN_REFRESHING | An error occured while [refreshing the token](TODO). This error code can only be passed in to the [*onDisconnected*](TODO) callback. |
| 1004 | GOOGLE_IOT_CORE_ERROR_ALREADY_REGISTERED | Another device is already registered with the same Device ID. |
| 1010 | GOOGLE_IOT_CORE_ERROR_GENERAL | General error. |

## Examples ##

Working examples are provided in the [examples](./examples) directory and described [here](./examples/README.md).

## Testing ##

Tests for the library are provided in the [tests](./tests) directory and described [here](./tests/README.md).

## License ##

The GoogleIoTCore library is licensed under the [MIT License](./LICENSE).
