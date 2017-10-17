# oxd-https-extension installation

## Start oxd-https-extension
First make sure you have installed the oxd package as described [here](https://gluu.org/docs/oxd/3.1.1/install/).

After the package is successfully installed, start the `oxd-https-extension` service by executing the following command:

```
/etc/init.d/oxd-https-extension start
```

To stop the `oxd-https-extension`, run:

```
/etc/init.d/oxd-https-extension stop
```

## Manual installation

For manual installation `oxd-server` and `oxd-https-extension` have to be installed separately.

Install `oxd-server` manually as described [here](https://gluu.org/docs/oxd/3.1.1/install/#manual-installation).

Install `oxd-https-extension` following these steps:

* Download `oxd-https-extension` jar file from [maven repo](http://ox.gluu.org/maven/org/xdi/oxd-https-extension/3.1.1.Final/)
* Configure the server in `oxd-https.yml` file in the same directory. Configuration explained [here](https://gluu.org/docs/oxd/3.1.1/oxd-https/configuration/)
* Make sure `oxd-https.keystore` file exists and properly referenced in `oxd-https.yml` file.
* Run application with following command

```
java -jar oxd-https-extension-3.1.1.Final.jar server oxd-https.yml
```