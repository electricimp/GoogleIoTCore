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

`-----BEGIN CERTIFICATE-----\nMIIDFzCCAf+gAwIBAgIJALowvBjh6589MA0GCSqGSIb3DQEBBQUAMBExDzANBgNV\nBAMTBnVudXNlZDAeFw0xODA5MDIxNzUzNDBaFw0xODEwMDIxNzUzNDBaMBExDzAN\nBgNVBAMTBnVudXNlZDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALBp\nv1Y/xwdmyZPRCDosWboJ2K3RPMhQkC8BHqYEvDY5qRDc7zluUaJA260TzVFWI79Z\n98NAOH+Bx3j/7cVnuniRSbSInIg25GDCLHrP9dWBoIytxiekaR/C5aP5HDhaf5Ik\nTHbxhy7C8s8IY1sV+h0dXSliNz2hVcJ35nJbNTzP41AAErc6l+owY/jogsApb2ze\n68siSFekYe1SQKENUMlwWQAG8xtv7zXar6GCf+14I/bdQPGu9+7pIS2ys6XrMRV9\n3F2JApORuIgENYpczkvnQp/reUv5oOiiUwHnuLDKuIKWUzJCVUh0rnHI6L7D7Udh\nggkgD/2JAANQhB3KXtsCAwEAAaNyMHAwHQYDVR0OBBYEFIhBqwJH1m1cKf53Z9Cp\n5X4cdTRIMEEGA1UdIwQ6MDiAFIhBqwJH1m1cKf53Z9Cp5X4cdTRIoRWkEzARMQ8w\nDQYDVQQDEwZ1bnVzZWSCCQC6MLwY4eufPTAMBgNVHRMEBTADAQH/MA0GCSqGSIb3\nDQEBBQUAA4IBAQCsl+6wFvszKoh9dCfznFExLJZfS74VW1acD2f4gtETd02oGAOp\nQZ+wwyobDB1bcBpx7MJZkiDKpAVK/N7SPr1zJdLgHAPbI5sNu4ybRO4xkTo0UVpo\nooAN9xHd+3xrp9T+TGbAJTZSekQ7FFjW3plonxpzhMnP8baRvHPUyq1TRAc3MZV7\ncIguFK6rkr63RW4ZKeH4TUYjpOrx7DehZdLDT9zXREORLE1RGUSYvPHXTYdyBw87\nkiaJqUqS8cC3ipCGcZLyYWHT6nyOBZLxrwXslgw8XOnP+NsFZzz6ROhQmrKq1GuM\nJoBd+YLRFPWjclUMDYJyQUnUaihZ9OUE8BPy\n-----END CERTIFICATE-----`

</p>
</details>

<details><summary>Private Key (click to show)</summary>
<p>

`-----BEGIN RSA PRIVATE KEY-----\nMIIEogIBAAKCAQEAsGm/Vj/HB2bJk9EIOixZugnYrdE8yFCQLwEepgS8NjmpENzv\nOW5RokDbrRPNUVYjv1n3w0A4f4HHeP/txWe6eJFJtIiciDbkYMIses/11YGgjK3G\nJ6RpH8Llo/kcOFp/kiRMdvGHLsLyzwhjWxX6HR1dKWI3PaFVwnfmcls1PM/jUAAS\ntzqX6jBj+OiCwClvbN7ryyJIV6Rh7VJAoQ1QyXBZAAbzG2/vNdqvoYJ/7Xgj9t1A\n8a737ukhLbKzpesxFX3cXYkCk5G4iAQ1ilzOS+dCn+t5S/mg6KJTAee4sMq4gpZT\nMkJVSHSuccjovsPtR2GCCSAP/YkAA1CEHcpe2wIDAQABAoIBAFCjdd+x9YNPm9Li\nmPUmcrlUaORDIZqbIN0rkNvojDPpNXvM0dkZsV0Ocpvx0kdcrah5MoTgpTK7mveX\nXROAL7+PAfbw/0RQeyIzf+t/herbfwzvHgXe5GKtTxUd+KVV0Lx3tTAlhVp9qEm0\nlt369MI8OuqAx6l3RuFGt2MMiBBMYE+4P6blRSAO+YuzxkcE/oUYLiN34DMl83vl\nwKLJ/tb8qdb4Tdu77Sf+LIwKL2LTCDgXOfVaXI/or+9ojh33ENl73Y2SBzqQHQOX\nInRJYuU59lm1pOB0gCTkdq0FdYNzXFw3IcYqdooFHDF2txy24uF2/riaFv0FzwPK\nqOpxkvECgYEA2biS5KD1nEN6S3Wtc2i7+N0oK5asnvf2ObfG1jU4REX+6LTtixz7\nDrdlcmRtmnp9faVdnxoEY1SV92tY5vtpuBdEvdqmOEIT0icFUY4I7mhJGeeEyFHS\ndgxsCVmGsbM4BW6WEKbz+bd/kEPQp1O9a2Mkn1z+0SFyezJER7G1S1kCgYEAz23x\nAnGHRVqjP2F0sQaTVSFb2XXKXBZZcHad/284LBkbLCdtwtmrbtAS8X0dr6EE5T0J\nYMV8tWGhnxbWNcoSUmNR3euHtpTe6+kQ0Z4a/C2mPy5QKP+/Q96o0b3yaKITmkqA\nItiXHgZ/FaELmzp8jQyQxGyp13UMDNcMsQI5WVMCgYBatqatj8sGAq9vxWYxkc/Q\nDwVvs+XUjmgPAF1eXupEuA1PlCLtNXP9W7hvAx0Poj2rHj11zvdJE7MwVY/DHbmc\ntEU1/WYIRq/PfeafZlieTOE4Y9hVRpI0EVTqSFzwqUWMLdlkssswnp4N09OaBDAG\nEFbv92VMaW0zm2wLmyV4cQKBgDecP/rpuNxNGmsJk6FKJAG0uc0pGSFrFHtkMaOj\ni6m26WQDBhgxBxbkTc/UPTsyrf9PR85b4700+YGPO8qb7CGOYwpd9LpsWv9gMpQg\nERf+nQ1fOzpipkJp1VS12eFXYm4A/y1YZ9sy3qtLy7LIEVA3SDCA+V+8D4j5tntW\nH03lAoGAPlS+p6LPw2zlAYPszqjdCyhiMkWQOT3XsOjgRve9BtBSWoILTHvCsiPt\n8VWdxbO8hXbxsCJQO3vgRr5IkADr8ttiBStycpq5g6vFrJ33tR5YjNTl77yWtArg\nyyxSTL9CjcQ27q2GKnco9P+9Y4C8awFGWloIcXoDUjwmZbSIAT4=\n-----END RSA PRIVATE KEY-----`

</p>
</details>
