# oxd Node Express

The following documentation demonstrates how to use Gluu's commercial OAuth 2.0 client software, [oxd](http://oxd.gluu.org), to send users from a Node Express application to an OpenID Connect Provider (OP) for login. You can send users to any standard OpenID Connect Provider (OP) for login, including Google. In these docs we use the [free open source Gluu Server](http://gluu.org/gluu-server) as the OpenID Connect Provider (OP).


!!! Note:
    You can also refer to the [oxd-node library docs](../../languages/node/index.md) for more details on node classes.


## Installation Guides

- [Github oxd-node](https://github.com/GluuFederation/oxd-node)
- [Gluu Server](https://gluu.org/docs/ce/3.1.1/installation-guide/install/)
- [oxd-server](../../../install/index.md)


## Prerequisites

- Ubuntu / Debian / CentOS / RHEL / Windows Server 2008 or higher
- Node 6.11.0
- npm 3.10.10
- oxd-node 3.1.2

To use the oxd-node library, you will need:

- A valid OpenID Connect Provider (OP), like the [Gluu Server](https://gluu.org/gluu-server) or Google.    
- An active installation of the [oxd-server](../../../install/index.md) running on the same server as the client application.
- An active installation of the [oxd-https-extension](../../../install/index.md) if oxd-https-extension connection is used. In this case, client applications can be on different servers but will be able to access oxd-https-extension.
- A Windows server or Windows installed machine / Linux server or Linux installed machine.


## Configuring oxd-server

- Edit the file `/opt/oxd-server/conf/oxd-conf.json` 

    Change the OP HOST name to your OpenID Connect Provider (OP) domain at the line `"op_host": "https://<idp-hostname>"`

- Edit the file `/opt/oxd-server/conf/oxd-default-site-config.json`

    Change the `response_types` line to `"response_types": ["code"]`

- Start oxd-server, as described [here](../../../install/index.md):
<!--
- To start oxd-server, run the following command:

```bash
/etc/init.d/oxd-server start
```
-->


## Demosite Deployment

OpenID Connect only works with HTTPS connections. Enter the following to prepare the SSL certificates:

```bash
mkdir /etc/certs
cd /etc/certs
openssl genrsa -des3 -out demosite.key 2048
openssl rsa -in demosite.key -out demosite.key.insecure
mv demosite.key.insecure demosite.key
openssl req -new -key demosite.key -out demosite.csr
openssl x509 -req -days 365 -in demosite.csr -signkey demosite.key -out demosite.crt
```

Enable SSL by setting the valid certificate and key in your application "index.js" file:

```javascript
var options = {
    key: fs.readFileSync(__dirname + '/<key file name>.pem'),
    cert: fs.readFileSync(__dirname + '/<certificate file name>.pem')
};
```

The client hostname should be a valid `hostname`(FQDN), not a localhost or an IP Address. 
You can configure the hostname by adding the following entry in your host file:

**Linux**

Host file location `/etc/host` :

`127.0.0.1  client.example.com`  
    
**Windows**

Host file location `C:\Windows\System32\drivers\etc\host` :

`127.0.0.1  client.example.com`

To install dependencies for this application navigate to the "oxd-node-demo" folder in terminal(linux)/command prompt(windows) and run:

```shell
npm install
```
Open the downloaded [Sample Project](https://github.com/GluuFederation/oxd-node/archive/3.1.1.zip) and navigate to `oxd-node-demo` directory inside the project.

The port number for this application to run can be set in "properties.js" file, which you can use to run this application in any free port. By default the port number is set to "5053" which we will assume is the port number of this application for this example.

From the same folder (i.e. "oxd-node-demo"), run this project with "Node.js" with the following command:

```shell
node index.js
```

With the oxd-server running, navigate to the URL's below to run the sample client application. To register a client in the oxd-server use the Setup Client URL. Upon successful registration of the client application, an oxd ID will be displayed in the UI. Next, navigate to the Login URL for authentication.

    - Setup Client URL: https://client.example.com:5053/settings
    - Login URL: https://client.example.com:5053/login
    - UMA URL: https://client.example.com:5053/uma


This oxd Node.js library uses two configuration files (`settings.json` and `parameters.json`) to specify information needed by the OpenID Connect dynamic client registration. To save information that is returned (oxd_id, client_id, client_secret, etc.) the configuration file needs to be writable by the client application.