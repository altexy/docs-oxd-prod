# OpenID Connect & UMA Protocol Overview

oxd implements the [OpenID Connect](http://openid.net/specs/openid-connect-core-1_0.html) and [UMA 2.0](https://docs.kantarainitiative.org/uma/wg/oauth-uma-grant-2.0-05.html) profiles of OAuth 2.0. 

- The [oxd OpenID Connect APIs](#openid-connect-authentication) can be used to send a user to an OpenID Connect Provider (OP) for authentication and to gather identity information ("claims") about the user 

- The [oxd UMA APIs](#uma-2-authorization) can be used to send a user to an UMA Authorization Server (AS) for access policy enforcement, for example to centrally manage which people (or software clients) can access which web pages and APIs      

## OpenID Connect Authentication

OpenID Connect is a simple identity layer on top of OAuth 2.0. 

Technically OpenID Connect is not an authentication protocol--it enables a person to authorize the release of personal information from an "identity provider" to a separate application. In the process of authorizing the release of information, the person is authenticated (if no previous session exists).  

### Authentication Flow
oxd supports the OpenID Connect [Hybrid Flow](http://openid.net/specs/openid-connect-core-1_0.html#HybridFlowAuth) and [Authorization Code Flow](http://openid.net/specs/openid-connect-core-1_0.html#CodeFlowAuth) for authentication. 

Learn more about authentication flows in the [OpenID Connect spec](http://openid.net/specs/openid-connect-core-1_0.html). 

### oxd OpenID Connect APIs
`oxd-server` provides seven APIs for OpenID Connect authentication. In general,
you can think of the Authorization Code Flow as a three-step process: 

 1. Redirect a person to the authorization URL and obtain a code [/get-authorization-url](#get-authorization-url)
 1. Use the code to obtain tokens (access_token, id_token and refresh_token) [/get-tokens-id-access-by-code](#get-tokens-id-access-by-code)
 1. Use the access token to obtain user claims [/get-user-info](#get-user-info)

**IMPORTANT** : 

Before using the above workflow you will need to obtain an access token to secure the interaction with `oxd-server`. You can follow the two steps below. 

 - [Register site](#register-site) (returns `client_id` and `client_secret`. Make sure the `uma_protection` scope is present in the request)
 - [Get client token](#get-client-token) (pass `client_id` and `client_secret` to obtain `access_token`)
 
Pass the obtained access token in `Authorization: Bearer <access_token>` header in all future calls to the `oxd-server`.


#### Register Site 

[API Link](#operations-developers-register-site)

The client must first register itself with the `oxd-server`. 

If the registration is successful, oxd will dynamically register an OpenID Connect client and return an identifier for the application which must be presented in subsequent API calls. This is the `oxd_id` (not to be confused with the OpenID Connect Client ID).

`register_site` has many optional parameters. 

The only required parameter is the  `authorization_redirect_uri`. This is where the user will be redirected after successful authorization at the OpenID Connect Provider (OP).

The `op_host` parameter is optional, but it must be specified in either the [default configuration file](../configuration/#oxd-confjson) or the API call. This is the URL at the OP where users will be sent for authentication. 

!!! Note
    `op_host` must point to a valid OpenID Connect Provider (OP) that supports [Client Registration](http://openid.net/specs/openid-connect-registration-1_0.html#ClientRegistration).
    

#### Get Authorization URL

[API Link](#operations-developers-get-authorization-url)

Returns the URL at the OpenID Connect Provider (OP) to which your application must redirect the person to authorize the release of personal data (and perhaps be authenticated in the process if no previous session exists).

The response from the OpenID Connect Provider (OP) will include the code and state values, which should be used to subsequently obtain tokens.

After redirecting to the above URL, the OpenID Connect Provider (OP) will return a response to the URL your application registered as the redirect URI (parse out the code and state). It will look like this:

```language-http
HTTP/1.1 302 Found
Location: https://client.example.org/cb?code=SplxlOBeZQQYbYS6WxSbIA&state=af0ifjsldkj&scopes=openid%20profile
```

#### Get Tokens (ID & Access) by Code

[API Link](#operations-developers-get-tokens-by-code)

Use the code and state obtained in the previous step to call this API to retrieve tokens.


#### Get Access Token by Refresh Token

[API Link](#operations-developers-get-access-token-by-refresh-token)

A Refresh Token can be used to obtain a renewed Access Token. 

#### Get User Info

[API Link](#operations-developers-get-user-info)

Use the access token from the step above to retrieve a JSON object with the user claims.

#### Get Logout URI

The `get_logout_uri` command uses front-channel logout. A page is returned with iFrames, each of which contains the logout URL of the applications that have a session in that browser. 

These iFrames should be loaded automatically, enabling each application to get a notification of logout, and to hopefully clean up any cookies in the person's browser. If the person blocks [third-party cookies](https://en.wikipedia.org/wiki/HTTP_cookie#Third-party_cookie) in their browser, front-channel logout will not work.

#### Update Site

[API Link](#operations-developers-update-site)

#### Remove Site

[API Link](#operations-developers-remove-site)

## UMA 2 Authorization 
UMA 2 is a profile of OAuth 2.0 that defines RESTful, JSON-based, standardized flows and constructs for coordinating the protection of APIs and web resources. 

Using oxd, your application can delegate access management decisions, like who can access which resources, from what devices, to a central UMA Authorization Server (AS) like the [Gluu AS](https://gluu.org/docs/ce/admin-guide/uma/). 

### UMA 2 Resource Server API's

Your client, acting as an [OAuth2 Resource Server](https://tools.ietf.org/html/rfc6749#section-1.1), MUST:

- Register a protected resource (with the `uma_rs_protect` command)
- Intercept the HTTP call (before the actual REST resource call) and check the `uma_rs_check_access` command response to determine whether the requester is allowed to proceed or should be rejected:
    - Allow access: if the response from `uma_rs_check_access` is `allowed` or `not_protected`, an error is returned.
    - If `uma_rs_check_access` returns `denied` then return back HTTP response.
- client must have the `client_credentials` grant type. It's required for correct PAT obtaining.
        
The `uma_rs_check_access` operation checks access using the "or" rule when evaluating scopes.

For example, a resource like `/photo` protected with scopes `read`, `all` (by `uma_rs_protect` command) assumes that if either `read` or `all` is present, access is granted.

If the "and" rule is preferred, it can be achieved by adding an additional scope, for example:

`Resource1` scopes: `read`, `write` (follows the "or" rule).

`Resource2` scopes: `read_write` (and associate `read` *and* `write` policies with the `read_write` scope)

If access is not granted, an unauthorized HTTP code and registered ticket are returned. For example: 

```language-http
HTTP/1.1 401 Unauthorized
WWW-Authenticate: UMA realm="example",
      as_uri="https://as.example.com",
      ticket="016f84e8-f9b9-11e0-bd6f-0021cc6004de"
```

The `uma_rs_check_access` returns `denied` then returns back an HTTP response:

```language-http
HTTP/1.1 403 Forbidden
Warning: 199 - "UMA Authorization Server Unreachable"
```

#### UMA RS Protect Resources

[API Link](#operations-developers-uma-rs-protect)

It's important to have a single HTTP method mentioned only one time within a given path in JSON, otherwise the operation will fail.

Request:

```
POST /uma-rs-protect

{
        "oxd_id":"6F9619FF-8B86-D011-B42D-00CF4FC964FF",   <- REQUIRED
        "overwrite":false,                                 <- OPTIONAL oxd_id registers resource, if send uma_rs_protect second time with same oxd_id and overwrite=false then it will fail with error uma_protection_exists. overwrite=true means remove existing UMA Resource and register new based on JSON Document.
        "resources":[        <-  REQUIRED
            {
                "path":"/photo",
                "conditions":[
                    {
                        "httpMethods":["GET"],
                        "scopes":[
                            "http://photoz.example.com/dev/actions/view"
                        ]
                    },
                    {
                        "httpMethods":["PUT", "POST"],
                        "scopes":[
                            "http://photoz.example.com/dev/actions/all",
                            "http://photoz.example.com/dev/actions/add"
                        ],
                        "ticketScopes":[
                            "http://photoz.example.com/dev/actions/add"
                        ]
                    }
                ]
            },
            {
                "path":"/document",
                "conditions":[
                    {
                        "httpMethods":["GET"],
                        "scopes":[
                            "http://photoz.example.com/dev/actions/view"
                        ]
                    }
                ]
            }
        ]
}
```

Request with `scope_expression`. `scope_expression` is a Gluu-invented extension that allows a JsonLogic expression instead of a single list of scopes. Read more about `scope_expression` [here](https://gluu.org/docs/ce/admin-guide/uma).
```language-json
POST /uma-rs-protect

{
    "oxd_id": "6F9619FF-8B86-D011-B42D-00CF4FC964FF",  <-REQUIRED
    "overwrite":false,                                 <- OPTIONAL oxd_id registers resource, if send uma_rs_protect second time with same oxd_id and overwrite=false then it will fail with error uma_protection_exists. overwrite=true means remove existing UMA Resource and register new based on JSON Document.
    "resources": [  <-  REQUIRED
      {
        "path": "/photo",
        "conditions": [
          {
            "httpMethods": [
              "GET"
            ],
            "scope_expression": {
              "rule": {
                "and": [
                  {
                    "or": [
                      {
                        "var": 0
                      },
                      {
                        "var": 1
                      }
                    ]
                  },
                  {
                    "var": 2
                  }
                ]
              },
              "data": [
                "http://photoz.example.com/dev/actions/all",
                "http://photoz.example.com/dev/actions/add",
                "http://photoz.example.com/dev/actions/internalClient"
              ]
            }
          },
          {
            "httpMethods": [
              "PUT",
              "POST"
            ],
            "scope_expression": {
              "rule": {
                "and": [
                  {
                    "or": [
                      {
                        "var": 0
                      },
                      {
                        "var": 1
                      }
                    ]
                  },
                  {
                    "var": 2
                  }
                ]
              },
              "data": [
                "http://photoz.example.com/dev/actions/all",
                "http://photoz.example.com/dev/actions/add",
                "http://photoz.example.com/dev/actions/internalClient"
              ]
            }
          }
        ]
      }
    ]
}
```


#### UMA RS Check Access

[API Link](#operations-developers-uma-rs-check-access)

Operation to check whether access can be granted or not.

Request:

```language-json
POST /uma-rs-check-access
{
    "oxd_id":"6F9619FF-8B86-D011-B42D-00CF4FC964FF",
    "rpt":"eyJ0 ... NiJ9.eyJ1c ... I6IjIifX0.DeWt4Qu ... ZXso",    <-- REQUIRED - RPT or blank value if not sent by RP
    "path":"<path of resource>",                                   <-- REQUIRED - Resource Path (e.g. http://rs.com/phones), /phones should be passed
    "http_method":"<http method of RP request>"                    <-- REQUIRED - HTTP method of RP request (GET, POST, PUT, DELETE)
}
```

Sample of RP Request:
```language-http
GET /users/alice/album/photo HTTP/1.1
Authorization: Bearer vF9dft4qmT
Host: photoz.example.com
```

Parameters:
```language-yaml
rpt: 'vF9dft4qmT'
path: /users/alice/album/photo
http_method: GET
```

Access Granted Response:

```language-json
HTTP/1.1 200 OK
{
    "access":"granted"
}
```

Access Denied with Ticket Response:

```language-json
HTTP/1.1 200 OK
{
    "access":"denied"
    "www-authenticate_header":"UMA realm=\"example\",
                               as_uri=\"https://as.example.com\",
                               error=\"insufficient_scope\",
                               ticket=\"016f84e8-f9b9-11e0-bd6f-0021cc6004de\"",
    "ticket":"016f84e8-f9b9-11e0-bd6f-0021cc6004de"
}
```

Access Denied without Ticket Response:

```language-json
HTTP/1.1 200 OK
{
    "access":"denied"
}
```

Resource is not Protected Error Response:
```language-json
HTTP/1.1 400 Bad request
{
    "error":"invalid_request",
    "error_description":"Resource is not protected. Please protect your resource first with uma_rs_protect command."
}
```

#### UMA 2 Introspect RPT

[API Link](#operations-developers-introspect-rpt)

Example of successful response:

```language-json
HTTP/1.1 200 OK
{
        "active":true,
        "exp":1256953732,
        "iat":1256912345,
        "permissions":[  
            {  
                "resource_id":"112210f47de98100",
                "resource_scopes":[  
                    "view",
                    "http://photoz.example.com/dev/actions/print"
                ],
                "exp":1256953732
            }
        ]
}
```


### UMA 2 Client APIs

If your application is calling UMA 2 protected resources, use these APIs to obtain an RPT token.

#### UMA RP - Get RPT

[API Link](#operations-developers-uma-rp-get-rpt)


Successful Response:

```language-json
HTTP 1.1 200 OK
{
     "access_token":"SSJHBSUSSJHVhjsgvhsgvshgsv",
     "token_type":"Bearer",
     "pct":"c2F2ZWRjb25zZW50",
     "upgraded":true
}
```

Needs Info Error Response:
```language-json
HTTP 1.1 403 Forbidden
{
     "error":"need_info",
     "error_description":"The authorization server needs additional information in order to determine whether the client is authorized to have these permissions.",
     "details": {  
         "error":"need_info",
         "ticket":"ZXJyb3JfZGV0YWlscw==",
         "required_claims":[  
             {  
                 "claim_token_format":[  
                     "http://openid.net/specs/openid-connect-core-1_0.html#IDToken"
                 ],
                 "claim_type":"urn:oid:0.9.2342.19200300.100.1.3",
                 "friendly_name":"email",
                 "issuer":["https://example.com/idp"],
                 "name":"email23423453ou453"
            }
         ],
         "redirect_user":"https://as.example.com/rqp_claims?id=2346576421"
     }
}
```

#### UMA RP - Get Claims-Gathering URL

[API Link](#operations-developers-uma-rp-get-claims-gathering-url)

`ticket` parameter for this command MUST be newest, in 90% cases it is from `need_info` error.

After being redirected to the Claims Gathering URL, the user goes through the claims gathering flow. If successful, the user is redirected back to `claims_redirect_uri` with a new ticket which should be provided with the next `uma_rp_get_rpt` call.

Example of Response:

```
https://client.example.com/cb?ticket=e8e7bc0b-75de-4939-a9b1-2425dab3d5ec
```

## API References

oxd has defined swagger specification [here](https://github.com/GluuFederation/oxd/blob/version_4.0.beta/oxd-server/src/main/resources/swagger.yaml). It is possible to generated native library in your favorite language by [Swagger Code Generator](https://swagger.io/tools/swagger-codegen/)
Check our FAQ about easiest way to generate native client [here](https://gluu.org/docs/oxd/4.0.beta/faq/#what-is-the-easiest-way-to-generate-native-library-for-oxd).

<link rel="stylesheet" type="text/css" href="../../swagger/swagger-ui.css">

<div id="swagger-ui"></div>

<script src="../swagger/swagger-ui-bundle.js"></script>
<script src="../swagger/swagger-ui-standalone-preset.js"></script>

<script>

const DisableTryItOutPlugin = function() {
  return {
    statePlugins: {
      spec: {
        wrapSelectors: {
          allowTryItOutFor: () => () => false
        }
      }
    }
  }
}

function goToHash(){
	if(window.location.hash) {
	    //$(document).scrollTop( $('a[href$="'+window.location.hash+'"]').offset().top ); 	   
	}
}

function waitAndGoToHash() {
	window.setTimeout(goToHash,3000);
}

window.onload = function() {
  const ui = SwaggerUIBundle({
    url: "https://raw.githubusercontent.com/GluuFederation/oxd/version_4.0.beta/oxd-server/src/main/resources/swagger.yaml",
    dom_id: '#swagger-ui',
    docExpansion: 'full',
    deepLinking: true,
    defaultModelRendering: 'model',
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    plugins: [
        DisableTryItOutPlugin
    ],
    onComplete: waitAndGoToHash
  })

  window.ui = ui
}

$(document).ready(function () {
    $('html, body').animate({
        scrollTop: $(window.location.hash).offset().top
    }, 'slow');
});
</script>


## References

- [UMA 2.0 Grant for OAuth 2.0 Authorization Specification](https://docs.kantarainitiative.org/uma/ed/oauth-uma-grant-2.0-06.html)
- [Federated Authorization for UMA 2.0 Specification](https://docs.kantarainitiative.org/uma/ed/oauth-uma-federated-authz-2.0-07.html)
- [Java Resteasy HTTP interceptor of uma-rs](https://github.com/GluuFederation/uma-rs/blob/master/uma-rs-resteasy/src/main/java/org/xdi/oxd/rs/protect/resteasy/RptPreProcessInterceptor.java)