# Bearer Token Authentication Type

_This extension specification is currently incubating.  While incubating the version is 0._

## Introduction
Authentication is a necessary component to any real world application. A common mechanism for authenticating is using a bearer token. A bearer token can be presented as a means of obtaining access to a resource (i.e. session ids, OAuth 2 tokens, etc). This Authentication Type provides a standardized mechanism for including a bearer token in the Authentication Payload of the [Authentication Extension][a] using the Authentication Type of `bearer`.

[a]: Authentication.md

### Authentication Payload
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    | Bearer Token                                              ...
    +---------------+-----------------------------------------------+
```

* **Bearer Token**: The UTF-8 encoded bearer token.  The string MUST NOT be null terminated.
