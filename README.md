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

## GoogleIoTCore.MqttTransport Class ##

### Constructor: GoogleIoTCore.MqttTransport(*[configuration]*) ###

This method returns a new GoogleIoTCore.MqttTransport instance.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| [*configuration*](#configuration) | Table | Optional | Key-value table with settings. |

#### Configuration ####

These settings affect the transport's behavior and the operations.

| Key (String) | Value Type | Required? | Default | Description |
| --- | --- | --- | --- | --- |
| "url" | String | Optional | `ssl://mqtt.googleapis.com:8883` | MQTT broker URL formatted as `ssl://<hostname>:<port>`. |
| "qos" | Integer | Optional | 0 | MQTT QoS. [Google IoT Core supports QoS 0 and 1 only](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge?hl=ru#quality_of_service_qos). |
| "keepAlive" | Integer | Optional | 60 | Keep-alive MQTT parameter. For more information, see [here](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge?hl=ru#keep-alive). |

**Note**: TODO place some general info about MQTT in Google IoT Core?

## GoogleIoTCore.Client Class ##

### Constructor: GoogleIoTCore.Client(*projectId, cloudRegion, registryId, deviceId, privateKey[, configuration[, onConnected[, onDisconnected]]]*) ###

This method returns a new GoogleIoTCore.Client instance.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *projectId* | String | Yes | [Project ID](https://cloud.google.com/iot/docs/requirements?hl=ru#permitted_characters_and_size_requirements). |
| *cloudRegion* | String | Yes | [Cloud region](https://cloud.google.com/iot/docs/requirements?hl=ru#cloud_regions). |
| *registryId* | String | Yes | [Registry ID](https://cloud.google.com/iot/docs/requirements?hl=ru#permitted_characters_and_size_requirements). |
| *deviceId* | String | Yes | [Device ID](https://cloud.google.com/iot/docs/requirements?hl=ru#permitted_characters_and_size_requirements). |
| *privateKey* | String | Yes | [Private key](https://cloud.google.com/iot/docs/how-tos/credentials/keys?hl=ru). |
| [*configuration*](#configuration-1) | Table | Optional | Key-value table with settings. There are required and optional settings. |
| [*onConnected*](#callback-onconnectederror) | Function | Optional | Callback called every time the client is connected. |
| [*onDisconnected*](#callback-ondisconnectederror) | Function | Optional | Callback called every time the client is disconnected. |

#### Callback: onConnected(*error*) ####

This callback is called every time the client is connected.

TODO: should we say something about connectionless transports?

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the connection is successful, an [error code](TODO) otherwise. |

#### Callback: onDisconnected(*error*) ####

This callback is called every time the client is disconnected.

This is a good place to call the [connect()](#connect) method again if it was an unexpected disconnection.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *error* | Integer | `0` if the disconnection was caused by the disconnect() method, an [error code](TODO) which explains a reason of the disconnection otherwise. |

#### Configuration ####

These settings affect the client's behavior and the operations.

| Key (String) | Value Type | Required? | Default | Description |
| --- | --- | --- | --- | --- |
| "maxPendingSetStateRequests" | Integer | Optional | 3 | Maximum amount of pending [Set State operations](TODO). |
| "maxPendingPublishTelemetryRequests" | Integer | Optional | 3 | Maximum amount of pending [Publish Telemetry operations](TODO). |

#### Example ####

```squirrel
#require "GoogleIoTCore.agent.lib.nut:1.0.0"
```

### registerDevice(*iss, secret, publicKey[, onDone]*) ###

This method registers a device in Google IoT Core.

The method attempts to find already existing device with the device ID specified in the client’s constructor and compare that device’s public key with the key passed in. If no device found, the method tries to create one. If any device is found and keys are identical, the method succeeds. Otherwise, the method returns an error.

The method returns nothing. A result of the operation may be obtained via the [*onDone*](#callback-ondoneerror) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *iss* | String  | Yes | JWT issuer. |
| *secret* | String  | Yes | JWT sign secret key. |
| *publicKey* | String  | Yes | [Public key](https://cloud.google.com/iot/docs/how-tos/credentials/keys?hl=ru) for a new device. |
| *[onDone](#callback-ondoneerror)* | Function  | Optional | Callback called when the operation is completed or an error occurs. |

### connect(*[transport]*) ###

This method opens a connection to Google IoT Core.

For connectionless transports, like HTTP, immediately calls the onConnected callback (if specified in the client's constructor) with successful result.

Default transport is [GoogleIoTCore.MqttTransport](#googleiotcoremqtttransport-class) with default configuration.

Google IoT Core supports only one connection per device.

The method returns nothing. A result of the operation may be obtained via the [*onConnected*](#callback-onconnectederror) callback specified in the client's constructor or set by calling [setOnConnected()](#setonconnectedcallback) method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *transport* | GoogleIoTCore.\*Transport  | Optional | Instance of GoogleIoTCore.\*Transport class. |

### disconnect() ###

This method closes the connection to Google IoT Core. Does nothing if the connection is already closed.

For connectionless transports, like HTTP, immediately calls the [*onDisconnected*](#callback-ondisconnectederror) callback (if specified) with no errors.

The method returns nothing. When the disconnection is completed the [*onDisconnected*](#callback-ondisconnectederror) callback is called, if specified in the client's constructor or set by calling [setOnDisconnected()](#setondisconnectedcallback) method.

### isConnected() ###

This method checks if the client is connected to Google IoT Core.

The method returns Boolean: `true` if the client is connected, `false` otherwise.

TODO: should we say something about connectionless transports?

### publishTelemetry(*data[, subfolder[, onDone]]*) ###

This method [publishes a telemetry event to Google IoT Core](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge?hl=ru#publishing_telemetry_events).

The method returns nothing. A result of the operation may be obtained via the [*onDone*](#callback-ondoneerror) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *data* | Object  | Yes | Any serializable object. |
| *subfolder* | String  | Optional | The subfolder can be used as an event category or classification. For more information, see [here](https://cloud.google.com/iot/docs/how-tos/mqtt-bridge?hl=ru#publishing_telemetry_events_to_separate_pubsub_topics). |
| *[onDone](#callback-ondoneerror)* | Function  | Optional | Callback called when the operation is completed or an error occurs. |

### enableConfigurationReceiving(*onReceive[, onDone]*) ###

This method enables [configuration receiving from Google IoT Core](https://cloud.google.com/iot/docs/how-tos/config/configuring-devices?hl=ru).

The method works only for [MQTT transport](#googleiotcoremqtttransport-class).

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

#### Example ####

```squirrel
```

### reportDeviceState(*state[, onDone]*) ###

This method [reports a device state to Google IoT Core](https://cloud.google.com/iot/docs/how-tos/config/getting-state?hl=ru#reporting_device_state).

The method returns nothing. A result of the operation may be obtained via the [*onDone*](#callback-ondoneerror) callback if specified in this method.

| Parameter | Data Type | Required? | Description |
| --- | --- | --- | --- |
| *state* | Object  | Yes | [Device state](https://cloud.google.com/iot/docs/concepts/devices?hl=ru#device_state). Any serializable object. |
| *[onDone](#callback-ondoneerror)* | Function  | Optional | Callback called when the operation is completed or an error occurs. |

#### Example ####

```squirrel
```

### setOnConnected(*callback*) ###

This method sets [*onConnected*](#callback-onconnectederror) callback. The method returns nothing.

### setOnDisconnected(*callback*) ###

This method sets [*onDisconnected*](#callback-ondisconnectedreason) callback. The method returns nothing.

### setDebug(*value*) ###

This method enables (*value* is `true`) or disables (*value* is `false`) the client debug output (including error logging). It is disabled by default. The method returns nothing.

### Additional Info ###

#### Callback: onDone(*error*) #####

This callback is called when a method is completed. This is just a common description of the similar callbacks specified as an argument in several methods. An application may use different callbacks with the described signature for different methods. Or define one callback and pass it to different methods.

| Parameter | Data Type | Description |
| --- | --- | --- |
| *[error](#error-code)* | Integer | `0` if the operation is completed successfully, an [error code](#error-code) otherwise. |

### Error Codes ###

An *Integer* error code which specifies a concrete error (if any) happened during an operation.

| Error Code | Error Name | Description |
| --- | --- | --- |
| 1000 | GOOGLE_IOT_CORE_ERROR_NOT_CONNECTED | The client is not connected. |
| 1001 | GOOGLE_IOT_CORE_ERROR_ALREADY_CONNECTED | The client is already connected. |
| 1002 | GOOGLE_IOT_CORE_ERROR_NOT_ENABLED | The feature is not enabled. |
| 1003 | GOOGLE_IOT_CORE_ERROR_ALREADY_ENABLED | The feature is already enabled. |
| 1004 | GOOGLE_IOT_CORE_ERROR_OP_NOT_ALLOWED_NOW | The operation is not allowed now. E.g. the same operation is already in process. |
| 1005 | GOOGLE_IOT_CORE_ERROR_ALREADY_REGISTERED | Another device is already registered with the same Device ID. |
| 1010 | GOOGLE_IOT_CORE_ERROR_GENERAL | General error. |

## Examples ##

Working examples are provided in the [examples](./examples) directory and described [here](./examples/README.md).

## Testing ##

Tests for the library are provided in the [tests](./tests) directory and described [here](./tests/README.md).

## License ##

The GoogleIoTCore library is licensed under the [MIT License](./LICENSE).
