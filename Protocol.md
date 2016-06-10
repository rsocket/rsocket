## Status

This protocol is currently a draft for the final specifications. 
Current version of the protocol is __0.1__ (Major Version: 0, Minor Version: 1).

## Introduction

Specify an application protocol for [Reactive Streams](http://www.reactive-streams.org/) semantics across an asynchronous, binary
boundary. For more information, please see [Reactive Socket](http://reactivesocket.io/).

ReactiveSockets assumes an operating paradigm. These assumptions are:
- one-to-one communication
- non-proxied communication. Or if proxied, the ReactiveSocket semantics and assumptions are preserved across the proxy.
- no state preserved across [transport protocol](#transport-protocol) sessions by the protocol

Key words used by this document conform to the meanings in [RFC 2119](https://tools.ietf.org/html/rfc2119).

## Terminology

* __Frame__: A single message containing a request, response, or protocol processing.
* __Fragment__: A portion of an application message that has been partitioned for inclusion in a Frame.
See [Fragmentation and Reassembly](#fragmentation-and-reassembly).
* __Transport__: Protocol used to carry ReactiveSockets protocol. One of WebSockets, TCP, or Aeron. The transport MUST
provide capabilities mentioned in the [transport protocol](#transport-protocol) section.
* __Stream__: Unit of operation (request/response, etc.). See [Design Principles](DesignPrinciples.md).
* __Request__: A stream request. May be one of five types. As well as request for more items or cancellation of previous request.
* __Response__: A stream response. Contains data associated with previous request.
* __Client__: The side initiating a connection.
* __Server__: The side accepting connections from clients.
* __Connection__: The instance of a transport session between client and server.
* __Requester__: The side sending a request. A connection has at most 2 Requesters. One in each direction.
* __Responder__: The side receiving a request. A connection has at most 2 Responders. One in each direction.

## Data And Metadata

ReactiveSocket provides mechanisms for applications to distinguish payload into two types. Data and Metadata. The distinction
between the types in an application is left to the application.

The following are features of Data and Metadata.

- Metadata can be encoded differently than Data.
- Metadata can be "attached" (i.e. correlated) with the following entities:
    - Connection via Metadata Push and Stream ID of 0
    - Individual Request or Response

## Operation

### Frame Header Format

ReactiveSocket frames begin with a header. The general layout is given below. When used over
transport protocols that provide framing (WebSocket and Aeron), the Frame Length field MUST NOT be included.
For transports that do not provide framing, such as TCP, the Frame Length MUST be included.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+---------------------------+
    |         Frame Type            |I|M|        Flags              |
    +-------------------------------+-+-+---------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
                           Depends on Frame Type
```

* __Frame Length__: (31 = max 2,147,483,647 bytes) Length of Frame. Including header. Only used for specific transport
protocols. The __R__ bit is reserved and must be set to 0. The __R__ bit is considered part of the frame length and thus
is not present if the Frame Length is not used [see below](#frame-length).
* __Frame Type__: (16) Type of Frame.
* __Flags__: Any Flag bit not specifically indicated in the frame type should be set to 0 when sent and not interpreted on
reception. Flags generally depend on Frame Type, but all frame types must provide space for the following flags:
     * (__I__)gnore: Ignore frame if not understood
     * (__M__)etadata: Metadata present
* __Stream ID__: (32) Stream Identifier for this frame or 0 to indicate the entire connection.

__NOTE__: Byte ordering is assumed to be big endian.

#### Transport Protocol

The ReactiveSocket protocol uses a lower level transport protocol to carry ReactiveSocket frames. A transport protocol MUST provide the following:

1. Unicast [Reliable Delivery](https://en.wikipedia.org/wiki/Reliability_(computer_networking)).
1. [Connection-Oriented](https://en.wikipedia.org/wiki/Connection-oriented_communication) and preservation of frame ordering. Frame A sent before Frame B must arrive in source order. i.e. if Frame A is sent by the same source as Frame B, then Frame A will always arrive before Frame B. No assumptions about ordering across sources is assumed.
1. [FCS](https://en.wikipedia.org/wiki/Frame_check_sequence) is assumed to be in use either at the transport protocol or at each MAC layer hop. But no protection against malicious corruption is assumed.

An implementation MAY "close" a transport connection due to protocol processing. When this occurs, it is assumed that that connection will
have no further frames sent and all frames will be ignored.

ReactiveSocket as specified here only allows for TCP, WebSocket, and Aeron as transport protocols.

#### Frame Length

The presence of the Frame Length field (and corresponding __R__ bit) is determined by the transport protocol being used. The frame length field MUST be omitted if the transport protocol preserves message boundaries e.g. provides compatible framing. If, however, the transport protocol only provides a stream abstraction or can merge messages without preserving boundaries, or multiple transport protocols may be used, then the frame length field MUST be used.

|  Transport Protocol            | Frame Length Field Required |
|:-------------------------------|:----------------------------|
| TCP                            | __YES__ |
| WebSocket                      | __NO__  |
| Aeron                          | __NO__  |
| Other                          | __YES__ |

#### Handling Ignore Flag

The (__I__)gnore flag is used for extension of the protocol. A value of 0 in a frame for this flag indicates the protocol can't
ignore this frame. An implementation MAY send an ERROR frame (with CONNECTION_ERROR error code) and close the underlying transport
connection on reception of a frame that it does not understand with this bit not set.

#### Frame Validation

ReactiveSocket implementations may provide their own validation at the metadata level for specific frames. However, this is an application concern
and not necessary for protocol processing.

#### Metadata Optional Header

Specific Frame Types MAY contain an optional metadata header that provides metadata about a frame.
This metadata header is between the Frame Header and any payload.

Metadata Length MUST be less than or equal to the Frame Length minus the length of the Frame Header.
If Metadata Length is greater than this value, the entire frame MUST be ignored.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                       Metadata Length                       |
    +-+-------------------------------------------------------------+
    |                       Metadata Payload                       ...
    +---------------------------------------------------------------+
    |                       Payload of Frame                       ...
    +---------------------------------------------------------------+
```

* __Metadata Length__: (31 = max 2,147,483,647 bytes) Length of Metadata in bytes. Including Metadata header. The __R__ bit is reserved and must be set to 0.

### Stream Identifiers

#### Generation

Stream IDs are generated by a Requester. The lifetime of a Stream ID is determined by the request type and
the semantics of the stream based on its type.

Stream ID value of 0 is reserved for any operation involving the connection.

A stream ID must be locally unique for a Requester in a connection.

Stream ID generation follows general guidelines for [HTTP/2](https://tools.ietf.org/html/rfc7540) with respect
to odd/even values. In other words, a client MUST generate even Stream IDs and a server MUST generate odd Stream IDs.

### Frame Types

|  Type                          | Value  | Description |
|:-------------------------------|:-------|:------------|
| __RESERVED__                   | 0x0000 | __Reserved__ |
| __SETUP__                      | 0x0001 | __Setup__: Sent by client to initiate protocol processing. |
| __LEASE__                      | 0x0002 | __Lease__: Sent by Responder to grant the ability to send requests. |
| __KEEPALIVE__                  | 0x0003 | __Keepalive__: Connection keepalive. |
| __REQUEST_RESPONSE__           | 0x0004 | __Request Response__: Request single response. |
| __REQUEST_FNF__                | 0x0005 | __Fire And Forget__: A single one-way message. |
| __REQUEST_STREAM__             | 0x0006 | __Request Stream__: Request a completable stream. |
| __REQUEST_SUB__                | 0x0007 | __Request Subscription__: Request an infinite stream. |
| __REQUEST_CHANNEL__            | 0x0008 | __Request Channel__: Request a completable stream in both directions. |
| __REQUEST_N__                  | 0x0009 | __Request N__: Request N more items with ReactiveStreams semantics. |
| __CANCEL__                     | 0x000A | __Cancel Request__: Cancel outstanding request. |
| __RESPONSE__                   | 0x000B | __Response__: Response to a request. |
| __ERROR__                      | 0x000C | __Error__: Error at connection or application level. |
| __METADATA_PUSH__              | 0x000D | __Metadata__: Asynchronous Metadata frame |
| __EXT__                        | 0xFFFF | __Extension Header__: Used To Extend more frame types as well as extensions. |

### Setup Frame

Setup frames MUST always use Stream ID 0 as they pertain to the connection.

The SETUP frame is sent by the client to inform the server of the parameters under which it desires
to operate. The usage and message sequence used is shown in [Connection Establishment](#connection-establishment).

One of the important parameters for a connection is the format, layout, and any schema of the data and metadata for
frames. This is, for lack of a better term, referred to here as "MIME Type". An implementation MAY use typical MIME type
values or MAY decide to use specific non-MIME type values to indicate format, layout, and any schema
for data and metadata. The protocol implementation MUST NOT interpret the MIME type itself. This is an application
concern only.

The encoding format for Data and Metadata are included separately in the SETUP.

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+-+-+-----------------------+
    |     Frame Type = SETUP        |0|M|L|S|       Flags           |
    +-------------------------------+-+-+-+-+-----------------------+
    |                          Stream ID = 0                        |
    +-------------------------------+-------------------------------+
    |     Major Version             |         Minor Version         |
    +-------------------------------+-------------------------------+
    |                   Time Between KEEPALIVE Frames               |
    +---------------------------------------------------------------+
    |                         Max Lifetime                          |
    +---------------+-----------------------------------------------+
    |  MIME Length  |   Metadata Encoding MIME Type                ...
    +---------------+-----------------------------------------------+
    |  MIME Length  |     Data Encoding MIME Type                  ...
    +---------------+-----------------------------------------------+
                          Metadata & Setup Payload
```

* __Flags__:
     * (__M__)etadata: Metdadata present
     * (__L__)ease: Will honor LEASE (or not).
     * (__S__)trict: Adhere to strict interpretation of Data and Metadata.
* __Version__: Numeric Version of the protocol expressed as two numbers: 
     * Major Version: 16-bit major version number of the protocol.
     * Minor Version: 16-bit minor version number of the protocol.
See [Status](#Staus) for current version.
* __Time Between KEEPALIVE Frames__: Time (in milliseconds) between KEEPALIVE frames that the client will send.
* __Max Lifetime__: Time (in milliseconds) that a client will allow a server to not respond to a KEEPALIVE before
it is assumed to be dead.
* __MIME Length__: Encoding MIME Type Length in bytes.
* __Encoding MIME Type__: MIME Type for encoding of Data and Metadata. This MAY be a US-ASCII string
that includes the [Internet media type](https://en.wikipedia.org/wiki/Internet_media_type) specified
in [RFC 2045](https://tools.ietf.org/html/rfc2045). Many are registered with
[IANA](https://www.iana.org/assignments/media-types/media-types.xhtml) such as
[CBOR](https://www.iana.org/assignments/media-types/application/cbor).
[Suffix](http://www.iana.org/assignments/media-type-structured-suffix/media-type-structured-suffix.xml)
rules MAY be used for handling layout. For example, `application/x.netflix+cbor` or
`application/x.reactivesocket+cbor` or `application/x.netflix+json`. The string may or may not be null terminated.
* __Setup Data__: includes payload describing connection capabilities of the endpoint sending the
Setup header.

### Error Frame

Error frames are used for errors on individual requests/streams as well as connection errors and in response
to SETUP frames. The latter is referred to as SETUP_ERRORs.

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+---------------------------+
    |       Frame Type = ERROR      |0|M|        Flags              |
    +-------------------------------+-+-+---------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
    |                          Error Code                           |
    +---------------------------------------------------------------+
                        Metadata & Setup Error Data
```

* __Flags__:
     * (__M__)etadata: Metdadata present
* __Error Code__: Type of Error.
* __Setup Error Data__: includes payload describing error information. Error Data MUST be a UTF-8 encoded string. The string may or may not be null terminated.

A Stream ID of 0 means the error pertains to the connection. Including connection establishment. A non-0 Stream ID
means the error pertains to a given stream.

#### Error Codes

|  Type                          | Value      | Description |
|:-------------------------------|:-----------|:------------|
| __RESERVED__                   | 0x00000000 | __Reserved__ |
| __INVALID_SETUP__              | 0x00000001 | The Setup frame is invalid for the server (it could be that the client is too recent for the old server). Stream ID MUST be 0. |
| __UNSUPPORTED_SETUP__          | 0x00000002 | Some (or all) of the parameters specified by the client are unsupported by the server. Stream ID MUST be 0. |
| __REJECTED_SETUP__             | 0x00000003 | The server rejected the setup, it can specify the reason in the payload. Stream ID MUST be 0. |
| __CONNECTION_ERROR__           | 0x00000101 | The connection is being terminated. Stream ID MUST be 0. |
| __APPLICATION_ERROR__          | 0x00000201 | Application layer logic generating a Reactive Streams _onError_ event. Stream ID MUST be non-0. |
| __REJECTED__                   | 0x00000202 | Despite being a valid request, the Responder decided to reject it. The Responder guarantees that it didn't process the request. The reason for the rejection is explained in the metadata section. Stream ID MUST be non-0. |
| __CANCELED__                   | 0x00000203 | The responder canceled the request but potentially have started processing it (almost identical to REJECTED but doesn't garantee that no side-effect have been started). Stream ID MUST be non-0. |
| __INVALID__                    | 0x00000204 | The request is invalid. Stream ID MUST be non-0. |
| __RESERVED__                   | 0xFFFFFFFF | __Reserved for Extension Use__ |

__NOTE__: Values in the range of 0x0001 to 0x00FF are reserved for use as SETUP error codes. Values in the range of
0x00101 to 0x001FF are reserved for connection error codes. Values in the range of 0x00201 to 0xFFFFFFFE are reserved for application layer
errors.

### Lease Frame

Lease frames MUST always use Stream ID 0 as they pertain to the Connection.

Lease frames MAY be sent by the client-side or server-side Responders and inform the
Requester that it may send Requests for a period of time and how many it may send during that duration.
See [Lease Semantics](#lease-semantics) for more information.

The last received LEASE frame overrides all previous LEASE frame values.

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+---------------------------+
    |     Frame Type = LEASE        |0|M|        Flags              |
    +-------------------------------+-+-+---------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
    |                         Time-To-Live                          |
    +---------------------------------------------------------------+
    |                       Number of Requests                      |
    +---------------------------------------------------------------+
                                Metadata
```

* __Flags__:
     * (__M__)etadata: Metdadata present
* __Time-To-Live (TTL)__: Time (in milliseconds) for validity of LEASE from time of reception
* __Number of Requests__: Number of Requests that may be sent until next LEASE

A Responder implementation MAY stop all further requests by sending a LEASE with a value of 0 for __Number of Requests__ or __Time-To-Live__.

When a LEASE expires due to time, the value of the __Number of Requests__ that a Requester may make is implicitly 0.

### Keepalive Frame

KEEPALIVE frames MUST always use Stream ID 0 as they pertain to the Connection.

KEEPALIVE frames MUST be initiated by the client and sent periodically with the (__R__)espond flag set.
A reasonable time interval between client KEEPALIVE frames SHOULD be 500ms.

KEEPALIVE frames MAY be initiated by the server and sent upon application request with the (__R__)espond flag set.

Reception of a KEEPALIVE frame with the (__R__)espond flag set MUST cause a client or server to send
back a KEEPALIVE with the (__R__)espond flag __NOT__ set. The data in the received KEEPALIVE MUST be
echoed back in the generated KEEPALIVE.

Reception of a KEEPALIVE by a server indicates to the server that the client is alive.

Reception of a KEEPALIVE by a client indicates to the client that the server is alive.

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+-+-------------------------+
    |      Frame Type = KEEPALIVE   |0|0|R|      Flags              |
    +-------------------------------+-+-+-+-------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
                                  Data
```

* __Flags__:
     * (__M__)etadata: Metdadata __never__ present
     * (__R__)espond with KEEPALIVE or not
* __Data__: Data attached to a KEEPALIVE.

### Request Response Frame

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+-+-------------------------+
    | Frame Type = REQUEST_RESPONSE |0|M|F|      Flags              |
    +-------------------------------+-+-+-+-------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
                         Metadata & Request Data
```

* __Flags__:
    * (__M__)etadata: Metdadata present
    * (__F__)ollows: More Fragments Follow This Fragment.
* __Request Data__: identification of the service being requested along with parameters for the request.

### Request Fire-n-Forget Frame

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+-+-------------------------+
    |    Frame Type = REQUEST_FNF   |0|M|F|       Flags             |
    +-------------------------------+-+-+-+-------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
                          Metadata & Request Data
```

* __Flags__:
    * (__M__)etadata: Metdadata present
    * (__F__)ollows: More Fragments Follow This Fragment.
* __Request Data__: identification of the service being requested along with parameters for the request.

### Request Stream Frame

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+-+-------------------------+
    |  Frame Type = REQUEST_STREAM  |0|M|F|       Flags             |
    +-------------------------------+-+-+-+-------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
    |                      Initial Request N                        |
    +---------------------------------------------------------------+
                          Metadata & Request Data
```

* __Flags__:
    * (__M__)etadata: Metdadata present
    * (__F__)ollows: More Fragments Follow This Fragment.
* __Initial Request N__: initial request N value for stream.
* __Request Data__: identification of the service being requested along with parameters for the request.

### Request Subscription Frame

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+-+-------------------------+
    |     Frame Type = REQUEST_SUB  |0|M|F|       Flags             |
    +-------------------------------+-+-+-+-------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
    |                      Initial Request N                        |
    +---------------------------------------------------------------+
                           Metadata & Request Data
```

* __Flags__:
    * (__M__)etadata: Metdadata present
    * (__F__)ollows: More Fragments Follow This Fragment.
* __Initial Request N__: initial request N value for subscription.
* __Request Data__: identification of the service being requested along with parameters for the request.

### Request Channel Frame

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+-+-+-+---------------------+
    |  Frame Type = REQUEST_CHANNEL |0|M|F|C|N|      Flags          |
    +-------------------------------+-+-+-+-+-+---------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
    |              Initial Request N (only if N bit set)            |
    +---------------------------------------------------------------+
                           Metadata & Request Data
```

* __Flags__:
    * (__M__)etadata: Metdadata present
    * (__F__)ollows: More Fragments Follow This Fragment.
    * (__C__)omplete: bit to indicate COMPLETE.
    * (__N__): Is Initial Request N present or not
* __Initial Request N__: initial request N value for channel.
* __Request Data__: identification of the service being requested along with parameters for the request.

### Request N Frame

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+---------------------------+
    |      Frame Type = REQUEST_N   |0|0|        Flags              |
    +-------------------------------+-+-+---------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
    |                           Request N                           |
    +---------------------------------------------------------------+
```

* __Flags__:
     * (__M__)etadata: Metdadata __NOT__ present
* __Request N__: integer value of items to request.

### Cancel Frame

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+---------------------------+
    |       Frame Type = CANCEL     |0|M|        Flags              |
    +-------------------------------+-+-+---------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
                                Metadata
```

* __Flags__:
     * (__M__)etadata: Metdadata present

### Response Frame

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+-+-+-----------------------+
    |      Frame Type = RESPONSE    |0|M|F|C|        Flags          |
    +-------------------------------+-+-+-+-+-----------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
                         Metadata & Response Data
```

* __Flags__:
    * (__M__)etadata: Metadata Present.
    * (__F__)ollows: More fragments follow this fragment.
    * (__C__)omplete: bit to indicate COMPLETE.
* __Response Data__: payload for Reactive Streams onNext.

A Response is generally referred to as a NEXT.

A Response with the Complete Bit set is referred to as a COMPLETE.

### Metadata Push Frame

A Metadata Push frame can be used to send asynchronous metadata notifications from a Requester or
Responder to its peer. Metadata MUST be scoped to the connection by setting Stream ID to 0.

Metadata tied to a particular Request, Response, etc. uses the individual frames Metadata flag.

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+---------------------------+
    |   Frame Type = METADATA_PUSH  |0|1|        Flags              |
    +-------------------------------+-+-+---------------------------+
    |                           Stream ID                           |
    +---------------------------------------------------------------+
                                Metadata
```

* __Flags__:
     * (__M__)etadata: Metdadata _always_ present
* __Stream ID__: Must be 0 to pertain to the entire connection.

### Extension Frame

The general format for an extension frame is given below.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                    Frame Length (optional)                  |
    +-------------------------------+-+-+---------------------------+
    |       Frame Type = EXT        |I|M|        Flags              |
    +-------------------------------+-+-+---------------------------+
    |                        Extended Type                          |
    +---------------------------------------------------------------+
                          Depends on Extended Type...
```

* __Frame Type__: (16) 0xFFFF for Extension Header.
* __Flags__:
    * (__I__)gnore: Can be frame be ignored if not understood?
    * (__M__)etadata: Metadata Present.
* __Extended Type__: Extended type information

## Connection Establishment

__NOTE__: The semantics are similar to [TLS False Start](https://tools.ietf.org/html/draft-bmoeller-tls-falsestart-00).

The term SETUP_ERROR is used below to indicate an ERROR frame that has a Stream ID of 0 and an Error Code
that indicates a SETUP error.

Immediately upon successful connection, the client MUST send a SETUP frame with
Stream ID of 0. Any other frame received that is NOT a SETUP frame or a SETUP frame with
a non-0 Stream ID, MUST cause the server to send a SETUP_ERROR (with INVALID_SETUP) and close the connection.

The client-side Requester can inform the server-side Responder as to whether it will
honor LEASEs or not based on the presence of the __L__ flag in the SETUP frame.

The client-side Requester that has NOT set the __L__ flag in the SETUP frame may send
requests immediately if it so desires without waiting for a LEASE from the server.

The client-side Requester that has set the __L__ flag in the SETUP frame MUST wait
for the server-side Responder to send a LEASE frame before it can send Requests.

If the server accepts the contents of the SETUP frame, it MUST send a LEASE frame if
the SETUP frame set the __L__ flag. The server-side Requester may send requests
immediately upon receiving a SETUP frame that it accepts if the __L__ flag is not set in the SETUP frame.

If the server does NOT accept the contents of the SETUP frame, the server MUST send
back a SETUP_ERROR and then close the connection.

The __S__ flag of the SETUP indicates the client requires the server to adhere to strict interpretation
of the Data and Metadata of the SETUP. Anything in the Data and/or Metadata that is not understood or can
be provided by the server should require the SETUP to be rejected.

The server-side Requester mirrors the LEASE requests of the client-side Requester. If a client-side
Requester sets the __L__ flag in the SETUP frame, the server-side Requester MUST wait for a LEASE
frame from the client-side Responder before it can send a request. The client-side Responder MUST
send a LEASE frame after a SETUP frame with the __L__ flag set.

A client assumes a SETUP is accepted if it receives a response to a request, a LEASE
frame, or if it sees a REQUEST type.

A client assumes a SETUP is rejected if it receives a SETUP_ERROR.

Until connection establishment is complete, a Requester MUST NOT send any Request frames.

Until connection establishment is complete, a Responder MUST NOT emit any RESPONSE frames.

### Negotiation

The assumption is that the client will be dictating to the server what it desires to do. The server will decide to support
that SETUP (accept it) or not (reject it). The SETUP_ERROR error code indicates the reason for the rejection.

### Sequences without LEASE

The possible sequences without LEASE are below.

1. Client-side Request, Server-side __accepts__ SETUP
    * Client connects & sends SETUP & sends REQUEST
    * Server accepts SETUP, handles REQUEST, sends back normal sequence based on REQUEST type
1. Client-side Request, Server-side __rejects__ SETUP
    * Client connects & sends SETUP & sends REQUEST
    * Server rejects SETUP, sends back SETUP_ERROR, closes connection
1. Server-side Request, Server-side __accepts__ SETUP
    * Client connects & sends SETUP
    * Server accepts SETUP, sends back REQUEST type
1. Server-side Request, Server-side __rejects__ SETUP
    * Client connects & sends SETUP
    * Server rejects SETUP, sends back SETUP_ERROR, closes connection

### Sequences with LEASE

The possible sequences with LEASE are below.

1. Client-side Request, Server-side __accepts__ SETUP
    * Client connects & sends SETUP with __L__ flag
    * Server accepts SETUP, sends back LEASE frame
    * Client-side sends REQUEST
1. Client-side Request, Server-side __rejects__ SETUP
    * Client connects & sends SETUP with __L__ flag
    * Server rejects SETUP, sends back SETUP_ERROR, closes connection
1. Server-side Request, Server-side __accepts__ SETUP
    * Client connects & sends SETUP with __L__ flag
    * Server accepts SETUP, sends back LEASE frame
    * Client sends LEASE frame
    * Server sends REQUEST
1. Server-side Request, Server-side __rejects__ SETUP
    * Client connects & sends SETUP with __L__ flag
    * Server rejects SETUP, sends back SETUP_ERROR, closes connection

## Fragmentation And Reassembly

RESPONSE frames and all REQUEST frames may represent a large object and MAY need to be fragmented to fit within the Frame Data size. When this
occurs, the __F__ flag indicates if more fragments follow the current frame (or not).

## Stream Sequences and Lifetimes

Streams exists for a specific period of time. So an implementation may assume that Stream IDs are valid for a finite period of time. This period
of time is bound by, at most, the lifetime of the underlying transport protocol connection lifetime. Beyond that, each interaction pattern imposes
lifetime based on a sequence of interactions between Requester and Responder.

In the section below, "RQ -> RS" refers to Requester sending a frame to a Responder. And "RS -> RQ" refers to Responder sending
a frame to a Requester.

In the section below, "*" refers to 0 or more and "+" refers to 1 or more.

Once a stream has "terminated", the Stream ID can be "forgotten" by the Requester and Responder. An implementation MAY re-use an ID at this
time, but it is recommended that an implementation not aggressively re-use IDs.

### Request Response

1. RQ -> RS: REQUEST_RESPONSE
1. RS -> RQ: RESPONSE with COMPLETE

or

1. RQ -> RS: REQUEST_RESPONSE
1. RS -> RQ: ERROR

or

1. RQ -> RS: REQUEST_RESPONSE
1. RQ -> RS: CANCEL

Upon sending a response, the stream is terminated on the Responder.

Upon receiving a CANCEL, the stream is terminated on the Responder and the response SHOULD not be sent.

Upon sending a CANCEL, the stream is terminated on the Requester.

Upon receiving a COMPLETE or ERROR, the stream is terminated on the Requester.

### Request Fire-n-Forget

1. RQ -> RS: REQUEST_FNF

Upon reception, the stream is terminated by the Responder.

Upon being sent, the stream is terminated by the Requester.

REQUEST_FNF are assumed to be best effort and MAY not be processed due to: (1) SETUP rejection, (2) mis-formatting, (3) etc.

### Request Stream

1. RQ -> RS: REQUEST_STREAM
1. RS -> RQ: RESPONSE*
1. RS -> RQ: ERROR

or

1. RQ -> RS: REQUEST_STREAM
1. RS -> RQ: RESPONSE*
1. RS -> RQ: RESPONSE with COMPLETE

or

1. RQ -> RS: REQUEST_STREAM
1. RS -> RQ: RESPONSE*
1. RQ -> RS: CANCEL

At any time, a client may send REQUEST_N frames.

Upon receiving a CANCEL, the stream is terminated on the Responder.

Upon sending a CANCEL, the stream is terminated on the Requester.

Upon receiving a COMPLETE or ERROR, the stream is terminated on the Requester.

Upon sending a COMPLETE or ERROR, the stream is terminated on the Responder.

### Request Subscription

1. RQ -> RS: REQUEST_SUBSCRIPTION
1. RS -> RQ: RESPONSE*

or

1. RQ -> RS: REQUEST_SUBSCRIPTION
1. RS -> RQ: RESPONSE*
1. RS -> RQ: ERROR

or

1. RQ -> RS: REQUEST_SUBSCRIPTION
1. RS -> RQ: RESPONSE*
1. RQ -> RS: CANCEL

At any time, a client may send REQUEST_N frames.

Upon receiving a CANCEL, the stream is terminated on the Responder.

Upon sending a CANCEL, the stream is terminated on the Requester.

Upon receiving a ERROR, the stream is terminated on the Requester.

Upon sending a ERROR, the stream is terminated on the Responder.

### Request Channel

1. RQ -> RS: REQUEST_CHANNEL* intermixed with
1. RS -> RQ: RESPONSE*
1. RS -> RQ: COMPLETE | ERROR

or

1. RQ -> RS: REQUEST_CHANNEL* intermixed with
1. RS -> RQ: RESPONSE*
1. RQ -> RS: CANCEL

At any time, a Requester may send REQUEST_CHANNEL frames with F bit set to indicate fragmentation.

At any time, a Requester, as well as a Responder, may send REQUEST_N frames.

An implementation MUST only send a single initial REQUEST_CHANNEL frame from the Requester to the Responder. And
a Responder MUST respond to an initial REQUEST_CHANNEL frame with a REQUEST_N frame.

A Requester may indicate end of REQUEST_CHANNEL frames by setting the C bit. A Requester MUST NOT
send any additional REQUEST_CHANNEL frames after sending a frame with the C bit set.

Upon receiving a CANCEL, the stream is terminated on the Responder.

Upon sending a CANCEL, the stream is terminated on the Requester.

Upon receiving a COMPLETE or ERROR, the stream is terminated on the Requester.

Upon sending a COMPLETE or ERROR, the stream is terminated on the Responder.

### Per Stream State

#### Requester

1. CLOSED: implicit starting/ending state of all stream IDs
1. Requested (sent REQUEST_*)
1. CLOSED (received COMPLETE or sent REQUEST_FNF)
1. CLOSED (received ERROR)

#### Responder

1. CLOSED: implicit starting/ending state of all stream IDs
1. Responding: sending RESPONSEs and processing REQUEST_N
1. CLOSED (received CANCEL)
1. CLOSED (sent COMPLETE or received REQUEST_FNF)
1. CLOSED (sent ERROR)

### Flow Control

There are multiple flow control mechanics provided by the protocol.

#### Reactive Stream Semantics

[Reactive Stream](http://www.reactive-streams.org/) semantics for flow control of Streams, Subscriptions, and Channels.

The Requester and the Responder MUST respect the reactive-streams semantics.

e.g. here's an example of a successful stream call with flow-control.

1. RQ -> RS: REQUEST_STREAM (REQUEST_N=3)
1. RS -> RQ: RESPONSE
1. RS -> RQ: RESPONSE
1. RS -> RQ: RESPONSE
1. RS needs to wait for a new REQUEST_N at that point
1. RQ -> RS: REQUEST_N (n=3)
1. RS -> RQ: RESPONSE
1. RS -> RQ: RESPONSE with COMPLETE

#### Lease Semantics

The LEASE semantics are to control the number of indivdiual requests (all types) that a Requester may send in a given period.
The only responsibility the protocol implementation has for the LEASE is to honor it on the Requester side. The Responder application
is responsible for the logic of generation and informing the Responder it should send a LEASE to the peer Requester.

Requester MUST respect the LEASE contract. The Requester MUST NOT send more than __Number of Requests__ specified
in the LEASE frame within the __Time-To-Live__ value in the LEASE.

A Responder that receives a REQUEST that it can not honor due to LEASE restrictions MUST respond with an ERROR frame with error code
of LEASE_ERROR. This includes an initial LEASE sent as part of [Connection Establishment](#connection-establishment).

#### QoS and Prioritization

Quality of Service and Prioritization of streams are considered application or network layer concerns and are better dealt with
at those layers. The metadata capabilities, including METADATA_PUSH, are tools that applications can use for effective prioritization.
DiffServ via IP QoS are best handled by the underlying network layer protocols.

### Handling the Unexpected

This protocol attempts to be very lenient in processing of received frames and SHOULD ignore
conditions that do not make sense given the current context. Clarifications are given below:

1. TCP half-open connections (and WebSockets) or other dead transports are detectable by lack of KEEPALIVE frames as specified
under [Keepalive Frame](#keepalive-frame). The decision to close a connection due to inactivity is the applications choice.
1. Request keepalive and timeout semantics are the responsibility of the application.
1. Lack of REQUEST_N frames that stops a stream is an application concern and SHALL NOT be handled by the protocol.
1. Lack of LEASE frames that stops new Requests is an application concern and SHALL NOT be handled by the protocol.
1. If a RESPONSE for a REQUEST_RESPONSE is received that does not have a COMPLETE flag set, the implementation MUST
assume it is set and act accordingly.
1. Reassembly of RESPONSEs and REQUEST_CHANNELs MUST assume the possibility of an infinite stream.
1. Stream ID values MAY be re-used after completion or error of a stream.
1. A RESPONSE with both __F__ and __C__ flags set, implicitly ignores the __F__ flag.
1. All other received frames that are not accounted for in previous sections MUST be ignored. Thus, for example:
    1. Receiving a Request frame on a Stream ID that is already in use MUST be ignored.
    1. Receiving a CANCEL on an unknown Stream ID (including 0) MUST be ignored.
    1. Receiving an ERROR on an unknown Stream ID MUST be ignored.
    1. Receiving a RESPONSE on an unknown Stream ID (including 0) MUST be ignored.
    1. Receiving a METADATA_PUSH with a non-0 Stream ID MUST be ignored.
	1. A server MUST ignore a SETUP frame after it has accepted a previous SETUP.
	1. A server MUST ignore a SETUP_ERROR frame.
	1. A client MUST ignore a SETUP_ERROR after it has completed connection establishment.
	1. A client MUST ignore a SETUP frame.
