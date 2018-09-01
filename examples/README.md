# Google IoT Core Examples #

This document describes the example applications provided with the [GoogleIoTCore library](../README.md).

## AutoRegister example ##

The example:
- Downloads public and private keys using the provided URLs.
- Registers a device (if not registered yet) in the Google IoT Core platform using the provided credentials and the public key.
- Connects to Google IoT Core using the private key and the provided credentials.
- Starts to send telemetry events every 8 sec. The events contain the current timestamp.

Source code: [AutoRegister.agent.nut](./AutoRegister.agent.nut)

See [AutoRegister Example Setup and Run](#autoregister-example-setup-and-run).

## ManualRegister Example ##

This example:
- Downloads a private key using the provided URL.
- Connects to Google IoT Core using the private key and the other provided credentials.
- Enables Configuration updates receiving.
- Receives and logs notifications when Configuration is updated.
- Sends the Configuration value as a device state.

Source code: [ManualRegister.agent.nut](./ManualRegister.agent.nut)

See [ManualRegister Example Setup and Run](#manualregister-example-setup-and-run).

## Example Setup and Run ##

### AutoRegister Example Setup and Run ###

1. [Login To Google IoT Core](#login-to-google-iot-core)

2. [Create IoT Core Project](#create-iot-core-project) (if not created yet)

3. [Create Device Registry](#create-device-registry)

4. [Setup Google Service Accounts](#setup-google-service-accounts)

5. [Set up your Imp device](https://developer.electricimp.com/gettingstarted)

6. In the [Electric Imp's IDE](https://impcentral.electricimp.com) create new Product and Development Device Group.

7. Assign a device to the newly created Device Group.

8. Copy the [AutoRegister example source code](./AutoRegister.agent.nut) and paste it into the IDE as the agent code.

9. Set constants in the agent example code:
 - *GOOGLE_IOT_CORE_PROJECT_ID*: set the value from the step 2
 - *GOOGLE_IOT_CORE_CLOUD_REGION*: us-central1
 - *GOOGLE_IOT_CORE_REGISTRY_ID*: example-registry
 - *GOOGLE_IOT_CORE_DEVICE_ID*: example-device_1
 - *GOOGLE_ISS* and *GOOGLE_SECRET_KEY*: set the values from the step 4
 - *PUBLIC_KEY_URL*: TODO (temporary link: https://raw.githubusercontent.com/ragrus-nbl/GoogleIoTCore/master/pub_key.pem)
 - *PRIVATE_KEY_URL*: TODO (temporary link: https://raw.githubusercontent.com/ragrus-nbl/GoogleIoTCore/master/priv_key.pem)
 
 **Note**: You may use other names, ID's, etc. when following the instructions in Google IoT Console but make sure you set the constants in accordance to your data.

![AutoRegisterSetConst](./example_imgs/AutoRegisterSetConst.png)

10. Click **Build and Force Restart**.

11. Check from the logs in the IDE that telemetry events are successfully sent from the device (periodically)

![AutoRegisterLogs](./example_imgs/AutoRegisterRun.png)

### ManualRegister Example Setup and Run ###

TODO

## Google IoT Core How To ##

### Login To Google IoT Core ###

Open [Google IoT Core](https://cloud.google.com/iot-core/) and click **Sign in**. Then log in.
If you are not registered, click **Create account** and follow the instructions.

After logging in click **VIEW CONSOLE** to open the IoT Core Console.

![View console](./example_imgs/ViewConsole.png)

### Create IoT Core Project ###

1. In the [Google Cloud Console](https://console.cloud.google.com/iot), click **Select a project > NEW PROJECT**:

![Create IoT Core Project](./example_imgs/CreateProject1.png)

![Create IoT Core Project](./example_imgs/CreateProject2.png)

**Note**: In the next steps you may be needed to use a free trial period of paid subscription.

2. On the **New project** page, enter the following information for your new project:

 - **Project name**: example-project

 - **Billing account**: choose your billing account
 
 - Make a note of **your project ID**. It will be needed to setup and run your application.
 
 - Click **Create**

![New project](./example_imgs/NewProject.png)

### Create Device Registry ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project and click **Enable API**:

![Enable API](./example_imgs/EnableAPI.png)

**Note**: If you are getting an error like *"Operation does not satisfy the following requirements: billing-enabled..."*, you probably needed to get a paid subscription or free trial.

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

2. Click **IAM & Admin**, then **Service Accounts** from left side menu

![ServiceAccounts](./example_imgs/ServiceAccounts.png)

3. Click the **Create service account** button

![CreateServiceAccount](./example_imgs/CreateServiceAccount1.png)

4. Enter a new service account name in the corresponding field: example-serv-acc

5. From the **Role** dropdown menu, select **Cloud IoT Provisioner**

6. Check the **Furnish a new private key** button. Leave all other checkboxes untouched

7. Click the **Create** button

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

9. Make a note of **client_email** (it is *GOOGLE_ISS*) and **private_key** (it is *GOOGLE_SECRET_KEY*) from downloaded JSON file. They will be needed to setup and run your application.

### Create A Device ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project

2. Click on the registry you created in the previous steps

![OpenRegistry](./example_imgs/OpenRegistry.png)

3. Click **Create device** and enter the following information for your new device:

 - **Device ID**: example-device_2
 - **Public key format**: RS256_X509
 - **Public key value**: copy the public key from [here](https://raw.githubusercontent.com/ragrus-nbl/GoogleIoTCore/master/pub_key.pem)
 
4. Click **Create**.

![CreateDevice](./example_imgs/CreateDevice.png)

### Update Device Configuration ###

1. On the [Google Cloud Console page](https://console.cloud.google.com/iot), choose your project

2. Click on the registry you created in the previous steps

![OpenRegistry](./example_imgs/OpenRegistry.png)

3. Click on the device the configuration of which you want to update

![OpenDevice](./example_imgs/OpenDevice.png)

**Note**: If you don't have any devices, create one by running the [AutoRegister example](#autoregister-example) or manually.

4. Click **UPDATE CONFIG**, choose **Text** format and type your new configuration:

![UpdateConfig](./example_imgs/UpdateConfig.png)

5. Click **SEND TO DEVICE**.
