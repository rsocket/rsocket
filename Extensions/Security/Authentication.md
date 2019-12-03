# Authentication Extension

_This extension specification is currently incubating.  While incubating the version is 0._

## Introduction
Authentication is a necessary component to any real world application. This extension specification provides a standardized mechanism for including both the type of credentials and the credentials in metadata payloads.

## Metadata Payload
This metadata type can be used in a per connection or per stream, and not individual payloads and as such it **MUST** only be used in frame types used to initiate interactions and payloads.  This includes [`SETUP`][s], [`REQUEST_FNF`][rf], [`REQUEST_RESPONSE`][rr], [`REQUEST_STREAM`][rs], [`REQUEST_CHANNEL`][rc], and [`PAYLOAD`][p].  The Metadata MIME Type is `message/x.rsocket.authentication.v0`.

[s]:  ../../Protocol.md#frame-setup
[p]:  ../../Protocol.md#frame-payload
[rc]: ../../Protocol.md#frame-request-channel
[rf]: ../../Protocol.md#frame-fnf
[rr]: ../../Protocol.md#frame-request-response
[rs]: ../../Protocol.md#frame-request-stream


### Metadata Contents
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |A| Auth ID/Len |   Authentication Type                        ...
    +---------------+---------------+---------------+---------------+
    |                     Authentication Payload                   ...
    +---------------+-----------------------------------------------+
```

* (**A**)uthentication Type: Authentication type is a well known value represented by a unique integer.
* **Auth ID/Length**: (7 bits = max value 2^7 = 128) Unsigned 7-bit integer.  If A flag is set, indicates a [Well-known Auth Type ID][wk].  If A flag is not set, indicates the Authentication Type Length in bytes.
* **Authentication Type**: the type of authentication encoding. This SHOULD be a US-ASCII string.  The string MUST NOT be null terminated.  (Not present if A flag is set)
* **Authentication Payload**: The authentication payload encoded as defined by the Authentication Encoding Type.

[wk]: WellKnownAuthTypes.md