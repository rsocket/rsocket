# Basic Authentication Type

_This extension specification is currently incubating.  While incubating the version is 0._

## Introduction
Authentication is a necessary component to any real world application. The most "basic" mechanism for authenticating is leveraging a username and password for authentication. This Authentication Type provides a standardized mechanism for including a username and password in the Authentication Payload of the [Authentication Extension][a] using the Authentication Type of `basic`.

[a]: Authentication.md

## Authentication Payload
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |Username Length|     Username  |    Password              ...
    +---------------+-----------------------------------------------+
```

* **Username Length**: Username Length in bytes.
* **Username**:  The UTF-8 encoded username.  The string MUST NOT be null terminated.
* **Password**:  The UTF-8 encoded password.  The string MUST NOT be null terminated.

## Security Considerations
The Basic Authentication Type transmits the username and password in cleartext. Additionally, it does not protect the authenticity or confidentiality of the payload that is transmitted along with it. This means that the [Transport][t] that is used should provide both authenticity and confidentiality to protect both the username and password and corresponding payload. 

The use of the UTF-8 character encoding scheme and of normalization introduces additional security considerations; see [Section 10 of [RFC3629]](https://tools.ietf.org/html/rfc3629#section-10) and [Section 6 of [RFC5198]](https://tools.ietf.org/html/rfc5198#section-6) for more information.

[t]:  ../../Protocol.md#transport-protocol
