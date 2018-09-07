# Test Instructions

The tests in the current directory are intended to check the behavior of the GoogleIoTCore library.

They are written for and should be used with [impt](https://github.com/electricimp/imp-central-impt). See [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for the details of how to configure and run the tests.

The tests for the GoogleIoTCore library require pre-setup described below.

## Configure Google IoT Core

1. [Login To Google IoT Core](../examples/README.md#login-to-google-iot-core)

2. [Create IoT Core Project](../examples/README.md#create-iot-core-project)

3. [Create Device Registry](../examples/README.md#create-device-registry)

4. [Create Device](../examples/README.md#create-device)

5. [Setup Google Service Accounts](../examples/README.md#setup-google-service-accounts)

## Set Environment Variables

- Set *GOOGLE_IOT_CORE_PROJECT_ID* environment variable to the value of ** your Project ID** obtained in the [step 2](../examples/README.md##create-iot-core-project).\
The value should look like `example-project-256256`.
- Set *GOOGLE_IOT_CORE_CLOUD_REGION* environment variable to the value of **your Cloud Region** set in the [step 3](../examples/README.md##create-device-registry).\
The value should look like `us-central1`.
- Set *GOOGLE_IOT_CORE_REGISTRY_ID* environment variable to the value of **your Registry ID** set in the [step 3](../examples/README.md##create-device-registry).\
The value should look like `example-registry`.
- Set *GOOGLE_IOT_CORE_DEVICE_ID* environment variable to the value of **your Device ID** set in the [step 4](../examples/README.md##create-device).\
The value should look like `example-device_2`.
- Set *GOOGLE_IOT_CORE_PUBLIC_KEY* environment variable to the value of **your Public Key** set in the [step 4](../examples/README.md##create-device).\
The value should look like\
`-----BEGIN CERTIFICATE-----\nMIIC+DCCAeCg...neGy5zYVE=\n-----END CERTIFICATE-----` or\
`-----BEGIN PUBLIC KEY-----MIIBIjANBgk...vWZTtQIDAQAB-----END PUBLIC KEY-----`.\
**Please note** that all line breaks in the **Public Key** should be replaced with `\n` symbol.
If you use the key pair provided with [examples](../examples), you can just copy the **Public Key** from the [Keys section](#keys) of this instruction.
- Set *GOOGLE_IOT_CORE_PRIVATE_KEY* environment variable to the value of **your Private Key** which is paired with the **Public Key** set in the [step 4](../examples/README.md##create-device).\
The value should look like\
`-----BEGIN PRIVATE KEY-----\nMIIEvAIBAG9w...rxmClmOG==\n-----END PRIVATE KEY-----`.\
**Please note** that all line breaks in the **Private Key** should be replaced with `\n` symbol.
If you use the key pair provided with [examples](../examples), you can just copy the **Private Key** from the [Keys section](#keys) of this instruction.
- Set *GOOGLE_ISS* environment variable to the value of **your client_email** from the [step 5](../examples/README.md#setup-google-service-accounts).\
The value should look like `example-serv-acc@example-project-256256.iam.gserviceaccount.com`.
- Set *GOOGLE_SECRET_KEY* environment variable to the value of **your private_key** from the [step 5](../examples/README.md#setup-google-service-accounts).\
The value should look like `-----BEGIN PRIVATE KEY-----\nMII ..... QbDgw==\n-----END PRIVATE KEY-----\n`.
- For integration with [Travis](https://travis-ci.org) set *EI_LOGIN_KEY* environment variable to the valid impCentral login key.

## Run Tests

- See [impt Testing Guide](https://github.com/electricimp/imp-central-impt/blob/master/TestingGuide.md) for the details of how to configure and run the tests.
- Run [impt](https://github.com/electricimp/imp-central-impt) commands from the root directory of the lib. It contains a default test configuration file which should be updated by *impt* commands for your testing environment (at least the Device Group must be updated).

## Keys

<details><summary>Public Key (click to show)</summary>
<p>

`-----BEGIN CERTIFICATE-----\nMIIDGTCCAgGgAwIBAgIJAK5EhkcHwWb1MA0GCSqGSIb3DQEBBQUAMBExDzANBgNV\nBAMTBnVudXNlZDAgFw0xODA5MDcxMTM3MDFaGA8yMTk4MDIxMTExMzcwMVowETEP\nMA0GA1UEAxMGdW51c2VkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA\nycEcxh8hLVIx6yUOVBhEicLV89bmLkezclrn0shRquQZYrvRnIFLKHEUE5k5H7J5\nsv9ddGI37h9sk1mVzDCsa3AQG0VwOqVh5r2zXUVCWJdh/PHJWDMyySVh0/IHxzYF\nqI1pkYjIRbvfJmcPQdG2kjI7QbMSOHxPN2X4tg3Zeobgm+bSMI0eAS+z+7E31YI5\nfkO/GAZEPujVa9E+O7OMenczvCc+ojUs7FsXfXln1ri6eIkiLz7FkzT38R1+YlGQ\n4mCAayJ68TbsQY0hTtJmX0ltRD4SY9Ntzm+LXU+6dIViiTJpou2kjvZlaxN8WcoN\nFOmWxu/tmdayif+NOt7TMwIDAQABo3IwcDAdBgNVHQ4EFgQUjy8ENT3Mwss6VKM6\n/SGaeh2Rv6cwQQYDVR0jBDowOIAUjy8ENT3Mwss6VKM6/SGaeh2Rv6ehFaQTMBEx\nDzANBgNVBAMTBnVudXNlZIIJAK5EhkcHwWb1MAwGA1UdEwQFMAMBAf8wDQYJKoZI\nhvcNAQEFBQADggEBADRlA4zYb/5jytJcFZrClW1LWnbJAH8j/g+a4skgHhG7x9GB\n7MUjd4reORmJZJe1GktQx5rcJPJKGYlDaOxwra8l+neA8asWcfJlYQte4sYd1OXf\nGx2Qw8h/rdt1WU95ftCSXu4UKI0dcubtiO35t+bcTLTf7464o9OAQbVLf9TESygD\nlOeEUfmVgebxzEef1+UYM5FRqMyQaS8vv1/HW/01Yc2+U/98kHkq3OWrLmDhKC7G\nKCWVJaf1rJJPDLYeEculd7KkVM+U7OU47pDT65qFrIVGWmfkAR7/O3hhYx7ndmUH\ny424YCQhMXKHN61vVGPf3cjOuUH3STsSlq9L4KY=\n-----END CERTIFICATE-----`

</p>
</details>

<details><summary>Private Key (click to show)</summary>
<p>

`-----BEGIN RSA PRIVATE KEY-----\nMIIEpQIBAAKCAQEAycEcxh8hLVIx6yUOVBhEicLV89bmLkezclrn0shRquQZYrvR\nnIFLKHEUE5k5H7J5sv9ddGI37h9sk1mVzDCsa3AQG0VwOqVh5r2zXUVCWJdh/PHJ\nWDMyySVh0/IHxzYFqI1pkYjIRbvfJmcPQdG2kjI7QbMSOHxPN2X4tg3Zeobgm+bS\nMI0eAS+z+7E31YI5fkO/GAZEPujVa9E+O7OMenczvCc+ojUs7FsXfXln1ri6eIki\nLz7FkzT38R1+YlGQ4mCAayJ68TbsQY0hTtJmX0ltRD4SY9Ntzm+LXU+6dIViiTJp\nou2kjvZlaxN8WcoNFOmWxu/tmdayif+NOt7TMwIDAQABAoIBAQC1X/NjNTcZTExu\nLdkMxuhOxKadWLOEJZdwFcNVHhs1O2yK83iEb0PG7qly2QuesE9yGNrGN0o6u2tb\nqGzfrV5EE/GW4rz7LBSwYBgwoIP9qtI/mIo+zYA5jm69IFfXwnwhxEeEu2f4MOZy\n2rG/pS2xjpDxBnA58Z8xmW2XFSpPV/sX6clQcYv9mVFb9s4mGxVcjT2Smpp9LsOb\nEBVwJ7kTHSJUsCi2s/tUtE1yVlocrfMTSlRcvtRkzR7nJytX2fTCzyTFJmDUnBUd\nolAaAX7pghkp9ASWajOEaQrs5DdmgWRnPszG8dz2OXIjBAhQq+yu7u32Zh6Cnxcp\nuKl6qq7xAoGBAOsMLwcq5OfmxpiQSTMC9lwZCl1drgHiDy/KbQFiurN4vn6+2kjr\nc/fqVpyER0N3i3czqQe8mLH/EdcwFvmQYDV4qghf6mfIs+OloOxmGFw5TM4nrp0n\nogOaxQVNZLFMBQ66wOhowZawW8OOIx/XscKSpaM3JhKtHtAgpjRG1hY5AoGBANu9\nLCmUPfM8YRK9vabILHCtqJtiN34R0EngNKKOd0wzRIn3EDNaoIF3LiUTqItCWMnl\nfXeAiOp64ZwKYiaAQg9rEaBjAtSCvhNziZmoTcGAsenTRDqdEnt/Oq8N2Wbwiqxm\ncDN/ucCjsh/obTY/Hli45wBng3F7vkJ17uRKVNTLAoGBALZ5KPFJjZezAy5hpVIi\n1Js/HVrKZVI061FQtztCKGs4K7s98zx0/fzTQhYUYzavUehihLDq6ygUOwdx4AQy\n313jpS0HOXUEzRLH/JxJzlOacFQDXn3GzPI7bwTkxm0V9T8wIJ7M5K1VkIfKit4n\nl2rUah7Bq58II0m0bxNags2RAoGBAIcmDqd0GbYkiL/yG1cc/tg+ttj6y46qfiUx\n1K22WgFv9tO0NS6gqt914dfEA4HDSMDEeSqqz4sIEQLcEAoGEJtTCwBOZUs3Lpjg\nEt2C+m/tK3/ZBLnYKanzUrCgH/qEL4ZhatkB0cl95OxjE+itYYjIEKva/qkpppdR\n2aBnZ02JAoGAJjMK6sAJB/jaenGsaPmJYDC+UKz27wqG0Z4yn3NFUZi/U4gJuAo1\nGyhqdn8jPQfc5/tJ8eBQK9b2hxPP8QtBB88Xc8wFXXnn9mtLcvD+o01+VdXpGIa7\n5zM/fh/dVNzsFmcWyZhpMoYj+trkWrlECz0EIVQWM7LqcHuC02C0qYo=\n-----END RSA PRIVATE KEY-----`

</p>
</details>
