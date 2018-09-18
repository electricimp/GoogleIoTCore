# Google IoT Core Examples #

This document describes the example applications provided with the [GoogleIoTCore library](../README.md).

**Note:** The Google IoT Core integration is currently in public Beta. Before proceeding, please sign up for access to the Google IoT Core integration using [this link](https://connect.electricimp.com/google-cloud-platform-integration-signup).

## Telemetry Example ##

This is a basic example of a quick prototype, proof-of-concept or demo application. For an example of a more production-oriented application, please see the [Configuration And State Example](#configuration-and-state-example), below.

This example:

- Downloads public and private keys using provided URLs. All other configuration settings are hardcoded into the example's code. 
- Registers a device (if not registered already) with Google IoT Core using the library's optional *register()* method.
- Connects to Google IoT Core.
- Sends telemetry events to Google IoT Core every eight seconds. Each event contains the current timestamp.

Source code: [Telemetry.agent.nut](./Telemetry.agent.nut)

### Telemetry Example Set Up And Run ###

1. [Login to Google IoT Core](#login-to-google-iot-core).
2. [Create an IoT Core Project](#create-an-iot-core-project) (if not created yet).
3. [Create a Device Registry](#create-a-device-registry).
4. [Set up Google Service Accounts](#set-up-google-service-accounts).
5. [Set up your imp-enabled device](https://developer.electricimp.com/gettingstarted).
6. In [Electric Imp's impCentral™ IDE](https://impcentral.electricimp.com) create a new Product and a new Development Device Group.
7. Assign your imp-enabled device to the newly created Development Device Group.
8. Copy the [example source code](./Telemetry.agent.nut) and paste it into impCentral’s code editor as the agent code.
9. Set the constants in the agent code:
    - *GOOGLE_IOT_CORE_PROJECT_ID*: set the value from the [step 2](#create-an-iot-core-project)
    - *GOOGLE_IOT_CORE_CLOUD_REGION*: `us-central1`
    - *GOOGLE_IOT_CORE_REGISTRY_ID*: `example-registry`
    - *GOOGLE_IOT_CORE_DEVICE_ID*: `example-device` (this ID will be used when creating a new device)
    - *GOOGLE_ISS* and *GOOGLE_SECRET_KEY*: set the values from the [step 4](#set-up-google-service-accounts)
    - *PUBLIC_KEY_URL*: copy [this link](./keys/pub_key.pem?raw=true)
    - *PRIVATE_KEY_URL*: copy [this link](./keys/priv_key.pem?raw=true)

    **Note** You may generate and use your own public-private keys pair. Please read the [RSA Key Generation](#rsa-key-generation) section, below. After that, you should upload the keys to your server and set the links to the keys as *&#42;_KEY_URL* variables.


    ![TelemetrySetConst](./example_imgs/TelemetrySetConst.png)

10. Click **Build and Force Restart** in impCentral.
11. Check the impCentral log that telemetry events are successfully being sent periodically from the device.

    ![TelemetryLogs](./example_imgs/TelemetryRun.png)

**Note**: If you are getting a device registration error, please read the **Note** in the [Setup Google Service Accounts](#set-up-google-service-accounts) section.

## Configuration And State Example ##

This is an example of a more production-oriented application. It has a design which may be used in real production code and includes additional comments with production-related hints.

This application:

- Assumes a device is already registered with Google IoT Core, eg. by a production server.
- Uses the minimum settings required for the application initialization.
- After the first start, downloads the application settings, eg. from a production server whose URL is hardcoded into the application (for simplicity, only a private key is downloaded from the URL; all other settings are hardcoded). After the first initialization, all settings may be stored by the device’s agent and then reloaded after the application is restarted. However, this has not been implemented here for simplicity.
- Connects to Google IoT Core.
- Enables the reception of Configuration data.
- When a new Configuration is received from Google IoT Core, sends it to the imp-enabled device and waits for a new state report from the device. When the new state is received, sends it to Google IoT Core (for simplicity, communication with the device is not implemented).
- Logs all errors and other significant events to the production server or other logging utility (for simplicity, the example only logs to impCentral). Signals some of the errors to the device, which can then display them (not implemented).

This application does not demonstrate sending telemetry events to Google IoT Core. Please see the [telemetry Example](#telemetry-example) to see that feature in operation.

Source code: [CfgState.agent.nut](./CfgState.agent.nut)

### Configuration And State Example Set Up And Run ###

1. [Login to Google IoT Core](#login-to-google-iot-core).
2. [Create an IoT Core Project](#create-an-iot-core-project) (if not created yet).
3. [Create a Device Registry](#create-a-device-registry).
4. Check if your device (`example-device`) is already registered. It may have been registered by the [Telemetry Example](#telemetry-example-set-up-and-run). If not, [create device manually](#create-a-device).\
 If you have a registered device but want to run this example with another device, [create it manually](#create-a-device) with another Device ID.
5. [Set up your imp-enabled device](https://developer.electricimp.com/gettingstarted).
6. In [Electric Imp's impCentral IDE](https://impcentral.electricimp.com) create a new Product and a new Development Device Group.
7. Assign your imp-enabled device to the newly created Development Device Group.
8. Copy the [example source code](./CfgState.agent.nut) and paste it into impCentral’s code editor as the agent code.
9. Set the constants in the agent code:
    - *GOOGLE_IOT_CORE_PROJECT_ID*: set the value from the [step 2](#create-an-iot-core-project)
    - *GOOGLE_IOT_CORE_CLOUD_REGION*: `us-central1`
    - *GOOGLE_IOT_CORE_REGISTRY_ID*: `example-registry`
    - *GOOGLE_IOT_CORE_DEVICE_ID*: set the value from the [step 4](#create-a-device)
    - *PRIVATE_KEY_URL*: copy [this link](./keys/priv_key.pem?raw=true)
 
    **Note** You may use other names, IDs, etc. when following the instructions in the Google IoT Console but make sure you set the constants to match your choices.

    ![CfgStateSetConst](./example_imgs/CfgStateSetConst.png)

10. Click **Build and Force Restart** in impCentral.
11. Check the impCentral log that connection is established and that receiving configuration updates is enabled, and that the current configuration has been received - it is empty by default.

    ![CfgStateLogs](./example_imgs/CfgStateRun.png)

12. [Update the Device Configuration](#update-the-device-configuration) and check from the logs that the new configuration has been received.

    ![CfgStateLogs](./example_imgs/CfgStateLogs.png)

13. [Check the Device State](#check-device-state) and make sure that your device has set the latest STATE to the value you set in the previous step

    ![CfgStateState](./example_imgs/CfgStateState.png)

## General Google IoT Core Instructions ##

### Login To Google IoT Core ###

Open [Google IoT Core](https://cloud.google.com/iot-core/) and click **Sign in**. Then log in.
If you have not yet created an account, do so now: click **Create account** and follow the instructions.

After logging in, click **VIEW CONSOLE** to open the IoT Core Console.

![View console](./example_imgs/ViewConsole.png)

**Note** In the next steps you may need to use the free trial period of a paid subscription.

### Create An IoT Core Project ###

1. In the [Google Cloud Console](https://console.cloud.google.com/iot), click **Select a project > NEW PROJECT**:

![Create IoT Core Project](./example_imgs/CreateProject1.png)

![Create IoT Core Project](./example_imgs/CreateProject2.png)

2. On the **New project** page, enter the following information for your new project:

    - **Project name**: `example-project`.
    - **Billing account**: choose your billing account.
    - Make a note of your **Project ID**. It will be needed to set up and run your application.
    - Click **Create**:

    ![New project](./example_imgs/NewProject.png)

### Create A Device Registry ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project and click **Enable API**:

    ![Enable API](./example_imgs/EnableAPI.png)

**Note** If you are getting an error such as `"Operation does not satisfy the following requirements: billing-enabled..."`, you will need to set up a paid subscription or free trial.

2. Click **Create a device registry**:

    ![Create a device registry](./example_imgs/CreateRegistry1.png)

3. Enter the following information for your new registry:

    - **Registry ID**: `example-registry`.
    - **Region**: `us-central1`.
    - **Default telemetry topic**: `telemetry`.
    - **Default state topic**: `state`.
    - Click **Create**:
 
    ![Create a device registry](./example_imgs/CreateRegistry2.png)

### Set Up Google Service Accounts ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project.
2. Click **IAM & Admin**, then **Service Accounts** from the left-hand side menu:

    ![ServiceAccounts](./example_imgs/ServiceAccounts.png)

3. Click the **Create service account** button:

    ![CreateServiceAccount](./example_imgs/CreateServiceAccount1.png)

4. Enter a new service account name in the corresponding field: `example-serv-acc`.
5. From the **Role** drop-down menu, select **Cloud IoT Provisioner**.
6. Check the **Furnish a new private key** button. Leave all other checkboxes untouched.
7. Click the **Save** button:

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

9. Make a note of **client_email** (it is *GOOGLE_ISS*) and **private_key** (it is *GOOGLE_SECRET_KEY*) from the downloaded JSON file. They will be needed to set up and run your application.

**Note**: If you are going to remove your service account and create it again **with the same name**, you should remove it from both **Service Accounts** and **IAM** tabs. And **only after that** you can create a new service account with the same name. Otherwise, you may face some errors during auto-registration of a device in the [Telemetry Example](#telemetry-example).

### Create A Device ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project.
2. Click on the registry you created in the previous steps:

    ![OpenRegistry](./example_imgs/OpenRegistry.png)

3. Click **Create device** and enter the following information for your new device:

    - **Device ID**: example-device
    - **Public key format**: `RS256_X509`.
    - **Public key value**: copy the public key from [here](./keys/pub_key.pem?raw=true).
 
    **Note** You may generate and use your own public-private keys pair. Please read the [RSA Key Generation](#rsa-key-generation) section for more information.
 
4. Click **Create**:

    ![CreateDevice](./example_imgs/CreateDevice.png)

### Update The Device Configuration ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project.
2. Click on the registry you created in the previous steps:

    ![OpenRegistry](./example_imgs/OpenRegistry.png)

3. Click on the device the configuration of which you want to update:

    ![OpenDevice](./example_imgs/OpenDevice.png)

    **Note** If you don't have any devices, create one [manually](#create-a-device).

4. Click **UPDATE CONFIG**, choose **Text** format and enter your new configuration:

    ![UpdateConfig](./example_imgs/UpdateConfig.png)

5. Click **SEND TO DEVICE**.

### Check Device State ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project.
2. Click on the registry you created in the previous steps:

    ![OpenRegistry](./example_imgs/OpenRegistry.png)

3. Click on the device the state of which you want to check:

    ![OpenDevice](./example_imgs/OpenDevice.png)

    **Note** If you don't have any devices, create one [manually](#create-a-device).

4. Open the **Configuration and state history** tab. Here you can see all the configuration and state updates:

    ![ConfStateHistory](./example_imgs/ConfStateHistory.png)

    **Note** By default, all items are shown in **Base64** format. You can also click on each item and choose **Text** format.

### RSA Key Generation ###

The Google IoT Core platform suggests [two formats of RSA public key](https://cloud.google.com/iot/docs/reference/cloudiot/rest/v1/projects.locations.registries.devices#publickeyformat):

 - `RSA_PEM`
 - `RSA_X509_PEM`

The `RSA_X509_PEM` format is used by default in the [GoogleIoTCore library](../README.md) and in these examples. Keep in mind that keys of this type always have an expiration date. You can find an example showing how to generate such a key pair [here](https://cloud.google.com/iot/docs/how-tos/credentials/keys#generating_an_rs256_key_with_a_self-signed_x509_certificate).

The `RSA_PEM` format is also supported by the [GoogleIoTCore library](../README.md). These keys don't have an expiration date. You can find an example showing how to generate such a key pair [here](https://cloud.google.com/iot/docs/how-tos/credentials/keys#generating_an_rs256_key).
