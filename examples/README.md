# Google IoT Core Examples #

This document describes the example applications provided with the [GoogleIoTCore library](../README.md).

## Telemetry Example ##

This application is an example of a quick prototype, POC or a simple demo. For an example of a more production-oriented application see [Configuration And State Example](#configuration-and-state-example).

The example:
- Downloads public and private keys using the provided URLs. All other configuration settings are hardcoded in the example's code. 
- Registers a device (if not registered yet) in the Google IoT Core platform using the optional `register()` method of the library.
- Connects to the Google IoT Core.
- Sends Telemetry events to the Google IoT Core every 8 sec. Each event contains the current timestamp.

Source code: [Telemetry.agent.nut](./Telemetry.agent.nut)

See [Telemetry Example Setup and Run](#telemetry-example-setup-and-run).

## Configuration And State Example ##

This is an example of a more production-oriented application. It has a design which may be used in a real production code, includes additional comments with production-related hints.

This application:
- Assumes a device is already registered in the Google IoT Core platform, eg. by a production server.
- Uses the minimum settings required for the application initialization.
- After the first start, downloads the application settings, eg. from the production server, which URL is pre-hardcoded in the application (for the simplicity, only a private key is downloaded from the URL but all other settings are hardcoded). After the first initialization, all settings may be stored in the imp-agent and after the application restart downloaded from the store (not implemented for the simplicity).
- Connects to the Google IoT Core.
- Enables "Configuration updates receiving" feature.
- When a new Configuration is received from the Google IoT Core, sends it to the imp-device and waits for a new state from the imp-device. When the new state is received from the imp-device, reports it as the device state to the Google IoT Core (for the simplicity, a real communication with the imp-device is not implemented).
- Logs all errors and other significant events to the production server or other logging utility (for the simplicity, logs to the imp log stream). Signals some of the errors to the imp-device, eg. to display them (a real communication with the imp-device is not implemented).

This application does not demonstrate sending Telemetry events to the Google IoT Core. [Telemetry Example](#telemetry-example) demonstrates that feature.

Source code: [CfgState.agent.nut](./CfgState.agent.nut)

See [Configuration And State Example Setup and Run](#configuration-and-state-example-setup-and-run).

## Example Setup and Run ##

### Telemetry Example Setup and Run ###

1. [Login To Google IoT Core](#login-to-google-iot-core)

2. [Create IoT Core Project](#create-iot-core-project) (if not created yet)

3. [Create Device Registry](#create-device-registry)

4. [Setup Google Service Accounts](#setup-google-service-accounts)

5. [Set up your Imp device](https://developer.electricimp.com/gettingstarted)

6. In the [Electric Imp's IDE](https://impcentral.electricimp.com) create new Product and Development Device Group.

7. Assign a device to the newly created Device Group.

8. Copy the [Telemetry example source code](./Telemetry.agent.nut) and paste it into the IDE as the agent code.

9. Set constants in the agent example code:
 - *GOOGLE_IOT_CORE_PROJECT_ID*: set the value from the [step 2](#create-iot-core-project)
 - *GOOGLE_IOT_CORE_CLOUD_REGION*: `us-central1`
 - *GOOGLE_IOT_CORE_REGISTRY_ID*: `example-registry`
 - *GOOGLE_IOT_CORE_DEVICE_ID*: `example-device` (this ID will be used when creating a new device)
 - *GOOGLE_ISS* and *GOOGLE_SECRET_KEY*: set the values from the [step 4](#setup-google-service-accounts)
 - *PUBLIC_KEY_URL*: copy [this link](./keys/pub_key.pem?raw=true)
 - *PRIVATE_KEY_URL*: copy [this link](./keys/priv_key.pem?raw=true)
 
**Note**: You may use other names, ID's, etc. when following the instructions in Google IoT Console but make sure you set the constants in accordance with your data.

**Note**: You may generate and use your own public-private keys pair. Please read the [RSA Keys Generation](#rsa-keys-generation) section. After that, you should upload the keys somewhere and set the links to the keys as *\*_KEY_URL* variables.

![TelemetrySetConst](./example_imgs/TelemetrySetConst.png)

10. Click **Build and Force Restart**.

11. Check from the logs in the IDE that telemetry events are successfully periodically sent from the device.

![TelemetryLogs](./example_imgs/TelemetryRun.png)

### Configuration And State Example Setup and Run ###

1. [Login To Google IoT Core](#login-to-google-iot-core)

2. [Create IoT Core Project](#create-iot-core-project) (if not created yet)

3. [Create Device Registry](#create-device-registry)

4. Check if your device (`example-device`) is already registered. It may have been registered by the [Telemetry Example](#telemetry-example-setup-and-run). If not, [create device manually](#create-device).\
If you have a registered device but want to run this example with another device, [create it manually](#create-device) with another Device ID.

5. [Set up your Imp device](https://developer.electricimp.com/gettingstarted)

6. In the [Electric Imp's IDE](https://impcentral.electricimp.com) create new Product and Development Device Group.

7. Assign a device to the newly created Device Group.

8. Copy the [Configuration And State example source code](./CfgState.agent.nut) and paste it into the IDE as the agent code.

9. Set constants in the agent example code:
 - *GOOGLE_IOT_CORE_PROJECT_ID*: set the value from the [step 2](#create-iot-core-project)
 - *GOOGLE_IOT_CORE_CLOUD_REGION*: `us-central1`
 - *GOOGLE_IOT_CORE_REGISTRY_ID*: `example-registry`
 - *GOOGLE_IOT_CORE_DEVICE_ID*: set the value from the step 4
 - *PRIVATE_KEY_URL*: copy [this link](./keys/priv_key.pem?raw=true)
 
**Note**: You may use other names, ID's, etc. when following the instructions in Google IoT Console but make sure you set the constants in accordance with your data.

![CfgStateSetConst](./example_imgs/CfgStateSetConst.png)

10. Click **Build and Force Restart**.

11. Check from the logs in the IDE that connection is established and configuration updates receiving is enabled. Also, the current configuration may be received - it is empty by default.

![CfgStateLogs](./example_imgs/CfgStateRun.png)

12. [Update Device Configuration](#update-device-configuration) and check from the logs that new configuration is received

![CfgStateLogs](./example_imgs/CfgStateLogs.png)

13. [Check Device State](#check-device-state) and make sure that your device has set the latest STATE to the value you set in the previous step

![CfgStateState](./example_imgs/CfgStateState.png)

## Google IoT Core How To ##

### Login To Google IoT Core ###

Open [Google IoT Core](https://cloud.google.com/iot-core/) and click **Sign in**. Then log in.
If you are not registered, click **Create account** and follow the instructions.

After logging in click **VIEW CONSOLE** to open the IoT Core Console.

![View console](./example_imgs/ViewConsole.png)

**Note**: In the next steps you may be needed to use a free trial period of paid subscription.

### Create IoT Core Project ###

1. In the [Google Cloud Console](https://console.cloud.google.com/iot), click **Select a project > NEW PROJECT**:

![Create IoT Core Project](./example_imgs/CreateProject1.png)

![Create IoT Core Project](./example_imgs/CreateProject2.png)

2. On the **New project** page, enter the following information for your new project:

 - **Project name**: example-project

 - **Billing account**: choose your billing account
 
 - Make a note of **your project ID**. It will be needed to setup and run your application.
 
 - Click **Create**

![New project](./example_imgs/NewProject.png)

### Create Device Registry ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project and click **Enable API**:

![Enable API](./example_imgs/EnableAPI.png)

**Note**: If you are getting an error like *"Operation does not satisfy the following requirements: billing-enabled..."*, you probably need to get a paid subscription or free trial.

2. Click **Create a device registry**:

![Create a device registry](./example_imgs/CreateRegistry1.png)

3. Enter the following information for your new registry:

 - **Registry ID**: example-registry

 - **Region**: us-central1
 
 - **Default telemetry topic**: telemetry
 
 - **Default state topic**: state
 
 - Click **Create**
 
![Create a device registry](./example_imgs/CreateRegistry2.png)

### Setup Google Service Accounts ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project

2. Click **IAM & Admin**, then **Service Accounts** from the left side menu

![ServiceAccounts](./example_imgs/ServiceAccounts.png)

3. Click the **Create service account** button

![CreateServiceAccount](./example_imgs/CreateServiceAccount1.png)

4. Enter a new service account name in the corresponding field: example-serv-acc

5. From the **Role** drop-down menu, select **Cloud IoT Provisioner**

6. Check the **Furnish a new private key** button. Leave all other checkboxes untouched

7. Click the **Save** button

![CreateServiceAccount](./example_imgs/CreateServiceAccount2.png)

8. The file `<project name>-<random number>.json` will be downloaded to your computer. It will look something like this:

```json
{ "type": "service_account",
  "project_id": "test-project",
  "private_key_id": "27ed751da7f0cb605c02dafda6a5cf535e662aea",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMII ..... QbDgw==\n-----END PRIVATEKEY-----\n",
  "client_email": "test-account@test-project.iam.gserviceaccount.com",
  "client_id": "117467107027610486288",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://accounts.google.com/o/oauth2/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/test-account%40@test-project.iam.gserviceaccount.com" }
```

9. Make a note of **client_email** (it is *GOOGLE_ISS*) and **private_key** (it is *GOOGLE_SECRET_KEY*) from the downloaded JSON file. They will be needed to setup and run your application.

### Create Device ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project

2. Click on the registry you created in the previous steps

![OpenRegistry](./example_imgs/OpenRegistry.png)

3. Click **Create device** and enter the following information for your new device:

 - **Device ID**: example-device
 - **Public key format**: RS256_X509
 - **Public key value**: copy the public key from [here](./keys/pub_key.pem?raw=true)
 
**Note**: You may generate and use your own public-private keys pair. Please read the [RSA Keys Generation](#rsa-keys-generation) section.
 
4. Click **Create**.

![CreateDevice](./example_imgs/CreateDevice.png)

### Update Device Configuration ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project

2. Click on the registry you created in the previous steps

![OpenRegistry](./example_imgs/OpenRegistry.png)

3. Click on the device the configuration of which you want to update

![OpenDevice](./example_imgs/OpenDevice.png)

**Note**: If you don't have any devices, create one by running the [AutoRegister example](#autoregister-example) or [manually](#create-device).

4. Click **UPDATE CONFIG**, choose **Text** format and type your new configuration:

![UpdateConfig](./example_imgs/UpdateConfig.png)

5. Click **SEND TO DEVICE**.

### Check Device State ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project

2. Click on the registry you created in the previous steps

![OpenRegistry](./example_imgs/OpenRegistry.png)

3. Click on the device the state of which you want to check

![OpenDevice](./example_imgs/OpenDevice.png)

**Note**: If you don't have any devices, create one by running the [AutoRegister example](#autoregister-example) or [manually](#create-device).

4. Open the **Configuration and state history** tab. Here you can see all configuration and state updates.

![ConfStateHistory](./example_imgs/ConfStateHistory.png)

**Note**: By default, all items are shown in **Base64** format. You can click on each item and choose **Text** format.

### RSA Keys Generation ###

The Google IoT Core platform suggests [two formats of RSA public key](https://cloud.google.com/iot/docs/reference/cloudiot/rest/v1/projects.locations.registries.devices#publickeyformat):
 - `RSA_PEM`
 - `RSA_X509_PEM`

The `RSA_X509_PEM` format is used by default in the [GoogleIoTCore library](../README.md) and in these examples. Keep in mind that keys of this type always have an expiration date. [Here](https://cloud.google.com/iot/docs/how-tos/credentials/keys#generating_an_rs256_key_with_a_self-signed_x509_certificate) you can find an example of how to generate such key pair.

The `RSA_PEM` format is also supported by the [GoogleIoTCore library](../README.md). These keys don't have an expiration date. An example of how to generate is [here](https://cloud.google.com/iot/docs/how-tos/credentials/keys#generating_an_rs256_key).
