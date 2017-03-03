## Status

This protocol is currently a draft for the final specifications. 
Current version of the protocol is __0.2__ (Major Version: 0, Minor Version: 2).

## Introduction

Specify an application protocol for [Reactive Streams](http://www.reactive-streams.org/) semantics across an asynchronous, binary
boundary. For more information, please see [ReactiveSocket.io](http://reactivesocket.io/).

ReactiveSocket assumes an operating paradigm. These assumptions are:
- one-to-one communication
- non-proxied communication. Or if proxied, the ReactiveSocket semantics and assumptions are preserved across the proxy.
- no state preserved across [transport protocol](#transport-protocol) sessions by the protocol

Key words used by this document conform to the meanings in [RFC 2119](https://tools.ietf.org/html/rfc2119).

Byte ordering is big endian for all fields.

## Table of Contents

- [Terminology](#terminology)
- [Versioning Scheme](#versioning-scheme) 
- [Data and Metadata](#data-and-metadata) 
- [Framing](#framing)
  - [Transport Protocol](#transport-protocol)
  - [Framing Protocol Usage](#framing-protocol-usage)
  - [Framing Format](#framing-format)
  - [Frame Header Format](#frame-header-format)
  - [Stream Identifiers](#stream-identifiers)
  - [Frame Types](#frame-types)
- [Resuming Operation](#resuming-operation)
- [Connection Establishment](#connection-establishment)
- [Fragmentation and Reassembly](#fragmentation-and-reassembly)
- [Stream Sequences and Lifetimes](#stream-sequences-and-lifetimes)
  - [Request Response](#stream-sequences-request-response)
  - [Fire and Forget](#stream-sequences-fire-and-forget)
  - [Request Stream](#stream-sequences-request-stream)
  - [Request Channel](#stream-sequences-channel)
- [Flow Control](#flow-control)
  - [Reactive Stream Semantics](#flow-control-reactive-streams)
  - [Lease Semantics](#flow-control-lease)
  - [QoS and Prioritization](#flow-control-qos)
- [Handling the Unexpected](#handling-the-unexpected)


## Terminology

* __Frame__: A single message containing a request, response, or protocol processing.
* __Fragment__: A portion of an application message that has been partitioned for inclusion in a Frame.
See [Fragmentation and Reassembly](#fragmentation-and-reassembly).
* __Transport__: Protocol used to carry ReactiveSocket protocol. One of WebSockets, TCP, or Aeron. The transport MUST
provide capabilities mentioned in the [transport protocol](#transport-protocol) section.
* __Stream__: Unit of operation (request/response, etc.). See [Motivations](Motivations.md).
* __Request__: A stream request. May be one of four types. As well as request for more items or cancellation of previous request.
* __Payload__: A stream message (upstream or downstream). Contains data associated with a stream created by a previous request. In Reactive Streams and Rx this is the 'onNext' event.
* __Complete__: Terminal event sent on a stream to signal successful completion. In Reactive Streams and Rx this is the 'onComplete' event.
  * A frame (PAYLOAD or REQUEST_CHANNEL) with the Complete bit set is sometimes referred to as COMPLETE in this document when reference to the frame is semantically about the Complete bit/event.
* __Client__: The side initiating a connection.
* __Server__: The side accepting connections from clients.
* __Connection__: The instance of a transport session between client and server.
* __Requester__: The side sending a request. A connection has at most 2 Requesters. One in each direction.
* __Responder__: The side receiving a request. A connection has at most 2 Responders. One in each direction.

## Versioning Scheme

ReactiveSocket follows a versioning scheme consisting of a numeric major version and a numeric minor version.

### Cross version compatibility

ReactiveSocket assumes that all version changes (major and minor) are backward incompatible.
A client can pass a version that it supports via the [Setup Frame](#frame-setup).
It is up to a server to accept clients of lower versions than what it supports.

## Data And Metadata

ReactiveSocket provides mechanisms for applications to distinguish payload into two types. Data and Metadata. The distinction
between the types in an application is left to the application.

The following are features of Data and Metadata.

- Metadata can be encoded differently than Data.
- Metadata can be "attached" (i.e. correlated) with the following entities:
    - Connection via Metadata Push and Stream ID of 0
    - Individual Request or Payload (upstream or downstream)

## Framing

### Transport Protocol

The ReactiveSocket protocol uses a lower level transport protocol to carry ReactiveSocket frames. A transport protocol MUST provide the following:

1. Unicast [Reliable Delivery](https://en.wikipedia.org/wiki/Reliability_(computer_networking)).
1. [Connection-Oriented](https://en.wikipedia.org/wiki/Connection-oriented_communication) and preservation of frame ordering. Frame A sent before Frame B MUST arrive in source order. i.e. if Frame A is sent by the same source as Frame B, then Frame A will always arrive before Frame B. No assumptions about ordering across sources is assumed.
1. [FCS](https://en.wikipedia.org/wiki/Frame_check_sequence) is assumed to be in use either at the transport protocol or at each MAC layer hop. But no protection against malicious corruption is assumed.

An implementation MAY "close" a transport connection due to protocol processing. When this occurs, it is assumed that the connection will have no further frames sent and all frames will be ignored.

ReactiveSocket as specified here has been designed for and tested with TCP, WebSocket, Aeron, and [HTTP/2 streams](https://http2.github.io/http2-spec/#StreamsLayer) as transport protocols.

### Framing Protocol Usage

Some of the supported transport protocols for ReactiveSocket may not support specific framing that preserves message boundaries. For these protocols, a framing protocol MUST be used with the ReactiveSocket frame that prepends the ReactiveSocket Frame Length.

The frame length field MUST be omitted if the transport protocol preserves message boundaries e.g. provides compatible framing. If, however, the transport protocol only provides a stream abstraction or can merge messages without preserving boundaries, or multiple transport protocols may be used, then the frame header MUST be used.

|  Transport Protocol            | Frame Length Field Required |
|:-------------------------------|:----------------------------|
| TCP                            | __YES__ |
| WebSocket                      | __NO__  |
| Aeron                          | __NO__  |
| HTTP/2 Stream                  | __YES__ |

### Framing Format

When using a transport protocol providing framing, the ReactiveSocket frame is simply encapsulated into the transport protocol messages directly.

```
    +-----------------------------------------------+
    |                ReactiveSocket Frame          ...
    |                                              
    +-----------------------------------------------+
```

When using a transport protocol that does not provide compatible framing, the Frame Length MUST be prepended to the ReactiveSocket Frame.

```
     0                   1                   2
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                    Frame Length               |
    +-----------------------------------------------+
    |                ReactiveSocket Frame          ...
    |                                              
    +-----------------------------------------------+
```

* __Frame Length__: (24 bits = max value 16,777,215) Unsigned 24-bit integer representing the length of Frame in bytes. Excluding the Frame Length field.

__NOTE__: Byte ordering is big endian.

### Frame Header Format

ReactiveSocket frames begin with a ReactiveSocket Frame Header. The general layout is given below.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |0|                         Stream ID                           |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |I|M|     Flags     |     Depends on Frame Type    ...
    +-------------------------------+
```

* __Stream ID__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer representing the stream Identifier for this frame or 0 to indicate the entire connection. Value MUST be >= 0.
  * Transport protocols that include demultiplexing, such as HTTP/2, MAY omit the Stream ID field if all parties agree. The means of negotiation and agreement is left to the transport protocol. 
* __Frame Type__: (6 bits = max value 63) Type of Frame.
* __Flags__: (10 bits) Any Flag bit not specifically indicated in the frame type should be set to 0 when sent and not interpreted on
reception. Flags generally depend on Frame Type, but all frame types MUST provide space for the following flags:
     * (__I__)gnore: Ignore frame if not understood
     * (__M__)etadata: Metadata present

__NOTE__: Byte ordering is big endian.

#### Handling Ignore Flag

The (__I__)gnore flag is used for extension of the protocol. A value of 0 in a frame for this flag indicates the protocol can't
ignore this frame. An implementation MAY send an ERROR[CONNECTION_ERROR] frame and close the underlying transport
connection on reception of a frame that it does not understand with this bit not set.

#### Frame Validation

ReactiveSocket implementations may provide their own validation at the metadata level for specific frames. However, this is an application concern and not necessary for protocol processing.

#### Metadata Optional Header

Specific Frame Types MAY contain an optional metadata header that provides metadata about a frame.
This metadata header is between the Frame Header and any payload.

Metadata Length MUST be less than or equal to the Frame Length minus the length of the Frame Header.
If Metadata Length is greater than this value, the entire frame MUST be ignored.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |              Metadata Length                  |
    +---------------------------------------------------------------+
    |                       Metadata Payload                       ...
    +---------------------------------------------------------------+
    |                       Payload of Frame                       ...
    +---------------------------------------------------------------+
```

* __Metadata Length__: (24 bits = max value 16,777,215) Unsigned 24-bit integer representing the length of Metadata in bytes. Excluding Metadata Length field.

<a name="stream-identifiers"></a>
### Stream Identifiers

#### Generation

Stream IDs are generated by a Requester. The lifetime of a Stream ID is determined by the request type and
the semantics of the stream based on its type.

Stream ID value of 0 is reserved for any operation involving the connection.

A Stream ID MUST be locally unique for a Requester in a connection.

Stream ID generation follows general guidelines for [HTTP/2](https://tools.ietf.org/html/rfc7540) with respect
to odd/even values. In other words, a client MUST generate odd Stream IDs and a server MUST generate even Stream IDs.

Stream IDs on the client MUST start at 1 and increment by 2 sequentially, such as 1, 3, 5, 7, etc.

Stream IDs on the server MUST start at 2 and increment by 2 sequentially, such as 2, 4, 6, 8, etc.

#### Lifetime

Stream IDs MUST be used for only one stream per connection without re-use. Once the max Stream ID has been used (2^31-1), no new streams can be created, thus a new connection MUST be established to create new streams once the max has been met. 

### Frame Types

|  Type                          | Value  | Description |
|:-------------------------------|:-------|:------------|
| __RESERVED__                                     | 0x00 | __Reserved__ |
| [__SETUP__](#frame-setup)                         | 0x01 | __Setup__: Sent by client to initiate protocol processing. |
| [__LEASE__](#frame-lease)                         | 0x02 | __Lease__: Sent by Responder to grant the ability to send requests. |
| [__KEEPALIVE__](#frame-keepalive)                 | 0x03 | __Keepalive__: Connection keepalive. |
| [__REQUEST_RESPONSE__](#frame-request-response)   | 0x04 | __Request Response__: Request single response. |
| [__REQUEST_FNF__](#frame-fnf)                     | 0x05 | __Fire And Forget__: A single one-way message. |
| [__REQUEST_STREAM__](#frame-request-stream)       | 0x06 | __Request Stream__: Request a completable stream. |
| [__REQUEST_CHANNEL__](#frame-request-channel)     | 0x07 | __Request Channel__: Request a completable stream in both directions. |
| [__REQUEST_N__](#frame-request-n)                 | 0x08 | __Request N__: Request N more items with Reactive Streams semantics. |
| [__CANCEL__](#frame-cancel)                       | 0x09 | __Cancel Request__: Cancel outstanding request. |
| [__PAYLOAD__](#frame-payload)                     | 0x0A | __Payload__: Payload on a stream. For example, response to a request, or message on a channel. |
| [__ERROR__](#frame-error)                         | 0x0B | __Error__: Error at connection or application level. |
| [__METADATA_PUSH__](#frame-metadata-push)         | 0x0C | __Metadata__: Asynchronous Metadata frame |
| [__RESUME__](#frame-resume)                       | 0x0D | __Resume__: Replaces SETUP for Resuming Operation (optional) |
| [__RESUME_OK__](#frame-resume-ok)                 | 0x0E | __Resume OK__ : Sent in response to a RESUME if resuming operation possible (optional) |
| [__EXT__](#frame-ext)                             | 0x3F | __Extension Header__: Used To Extend more frame types as well as extensions. |

<a name="frame-setup"></a>
### SETUP Frame (0x01)

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
    |                         Stream ID = 0                         |
    +-----------+-+-+-+-+-----------+-------------------------------+
    |Frame Type |0|M|R|L|  Flags    |
    +-----------+-+-+-+-+-----------+-------------------------------+
    |         Major Version         |        Minor Version          |
    +-------------------------------+-------------------------------+
    |0|                 Time Between KEEPALIVE Frames               |
    +---------------------------------------------------------------+
    |0|                       Max Lifetime                          |
    +---------------------------------------------------------------+
    |         Token Length          | Resume Identification Token  ...
    +---------------+-----------------------------------------------+
    |  MIME Length  |   Metadata Encoding MIME Type                ...
    +---------------+-----------------------------------------------+
    |  MIME Length  |     Data Encoding MIME Type                  ...
    +---------------+-----------------------------------------------+
                          Metadata & Setup Payload
```

* __Frame Type__: (6 bits = max value 63) 0x01
* __Flags__: (10 bits)
     * (__M__)etadata: Metadata present
     * (__R__)esume Enable: Client requests resume capability if possible. Resume Identification Token present.
     * (__L__)ease: Will honor LEASE (or not).
* __Major Version__: (16 bits = max value 65,535) Unsigned 16-bit integer of Major version number of the protocol.
* __Minor Version__: (16 bits = max value 65,535) Unsigned 16-bit integer of Minor version number of the protocol.
* __Time Between KEEPALIVE Frames__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer of Time (in milliseconds) between KEEPALIVE frames that the client will send. Value MUST be > 0. 
   * For server-to-server connections, a reasonable time interval between client KEEPALIVE frames is 500ms.
   * For mobile-to-server connections, the time interval between client KEEPALIVE frames is often > 30,000ms.
* __Max Lifetime__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer of Time (in milliseconds) that a client will allow a server to not respond to a KEEPALIVE before it is assumed to be dead. Value MUST be > 0. 
* __Resume Identification Token Length__: (16 bits = max value 65,535) Unsigned 16-bit integer of Resume Identification Token Length in bytes. (Not present if R flag is not set)
* __Resume Identification Token__: Token used for client resume identification (Not present if R flag is not set)
* __MIME Length__: Encoding MIME Type Length in bytes.
* __Encoding MIME Type__: MIME Type for encoding of Data and Metadata. This SHOULD be a US-ASCII string
that includes the [Internet media type](https://en.wikipedia.org/wiki/Internet_media_type) specified
in [RFC 2045](https://tools.ietf.org/html/rfc2045). Many are registered with
[IANA](https://www.iana.org/assignments/media-types/media-types.xhtml) such as
[CBOR](https://www.iana.org/assignments/media-types/application/cbor).
[Suffix](http://www.iana.org/assignments/media-type-structured-suffix/media-type-structured-suffix.xml)
rules MAY be used for handling layout. For example, `application/x.netflix+cbor` or
`application/x.reactivesocket+cbor` or `application/x.netflix+json`. The string MUST NOT be null terminated.
* __Setup Data__: includes payload describing connection capabilities of the endpoint sending the
Setup header.

__NOTE__: A server that receives a SETUP frame that has (__R__)esume Enabled set, but does not support resuming operation, MUST reject the SETUP with an ERROR[REJECTED_SETUP]. 

<a name="frame-error"></a>
### ERROR Frame (0x0B)

Error frames are used for errors on individual requests/streams as well as connection errors and in response to SETUP frames. 

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Stream ID                           |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |0|0|      Flags    |
    +-----------+-+-+---------------+-------------------------------+
    |                          Error Code                           |
    +---------------------------------------------------------------+
                               Error Data
```

* __Frame Type__: (6 bits = max value 63) 0x0B
* __Error Code__: (32 bits = max value 2^31-1 = 2,147,483,647) Type of Error.
     * See list of valid Error Codes below.
* __Error Data__: includes Payload describing error information. Error Data SHOULD be a UTF-8 encoded string. The string MUST NOT be null terminated.

A Stream ID of 0 means the error pertains to the connection., including connection establishment. A Stream ID > 0 means the error pertains to a given stream.

The Error Data is typically an Exception message, but could include stringified stacktrace information if appropriate.  

#### Error Codes

|  Type                          | Value      | Description |
|:-------------------------------|:-----------|:------------|
| __RESERVED__                   | 0x00000000 | __Reserved__ |
| __INVALID_SETUP__              | 0x00000001 | The Setup frame is invalid for the server (it could be that the client is too recent for the old server). Stream ID MUST be 0. |
| __UNSUPPORTED_SETUP__          | 0x00000002 | Some (or all) of the parameters specified by the client are unsupported by the server. Stream ID MUST be 0. |
| __REJECTED_SETUP__             | 0x00000003 | The server rejected the setup, it can specify the reason in the payload. Stream ID MUST be 0. |
| __REJECTED_RESUME__            | 0x00000004 | The server rejected the resume, it can specify the reason in the payload. Stream ID MUST be 0. |
| __CONNECTION_ERROR__           | 0x00000101 | The connection is being terminated. Stream ID MUST be 0. Sender or Receiver of this frame MAY close the connection immediately without waiting for outstanding streams to terminate.|
| __CONNECTION_CLOSE__           | 0x00000102 | The connection is being terminated. Stream ID MUST be 0. Sender or Receiver of this frame MUST wait for outstanding streams to terminate before closing the connection. New requests MAY not be accepted.|
| __APPLICATION_ERROR__          | 0x00000201 | Application layer logic generating a Reactive Streams _onError_ event. Stream ID MUST be > 0. |
| __REJECTED__                   | 0x00000202 | Despite being a valid request, the Responder decided to reject it. The Responder guarantees that it didn't process the request. The reason for the rejection is explained in the Error Data section. Stream ID MUST be > 0. |
| __CANCELED__                   | 0x00000203 | The Responder canceled the request but may have started processing it (similar to REJECTED but doesn't guarantee lack of side-effects). Stream ID MUST be > 0. |
| __INVALID__                    | 0x00000204 | The request is invalid. Stream ID MUST be > 0. |
| __RESERVED__                   | 0xFFFFFFFF | __Reserved for Extension Use__ |

__NOTE__: Unsed values in the range of 0x0001 to 0x00300 are reserved for future protocol use. Values in the range of 0x00301 to 0xFFFFFFFE are reserved for application layer errors.

When this document refers to a specific Error Code as a frame, it uses this pattern: ERROR[error_code] or ERROR[error_code|error_code]

For example:

- ERROR[INVALID_SETUP] means the ERROR frame with the INVALID_SETUP code
- ERROR[REJECTED] means the ERROR frame with the REJECTED code
- ERROR[CONNECTION_ERROR|REJECTED_RESUME] means the ERROR frame either either the CONNECTION_ERROR or REJECTED_RESUME code

<a name="frame-lease"></a>
### LEASE Frame (0x02)

Lease frames MAY be sent by the client-side or server-side Responders and inform the
Requester that it may send Requests for a period of time and how many it may send during that duration.
See [Lease Semantics](#lease-semantics) for more information.

The last received LEASE frame overrides all previous LEASE frame values.

Lease frames MUST always use Stream ID 0 as they pertain to the Connection.

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                         Stream ID = 0                         |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |0|M|     Flags     |
    +-----------+-+-+---------------+-------------------------------+
    |0|                       Time-To-Live                          |
    +---------------------------------------------------------------+
    |0|                     Number of Requests                      |
    +---------------------------------------------------------------+
                                Metadata
```

* __Frame Type__: (6 bits = max value 63) 0x02 
* __Flags__: (10 bits)
     * (__M__)etadata: Metadata present
* __Time-To-Live (TTL)__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer of Time (in milliseconds) for validity of LEASE from time of reception. Value MUST be > 0. 
* __Number of Requests__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer of Number of Requests that may be sent until next LEASE. Value MUST be > 0. 

A Responder implementation MAY stop all further requests by sending a LEASE with a value of 0 for __Number of Requests__ or __Time-To-Live__.

When a LEASE expires due to time, the value of the __Number of Requests__ that a Requester may make is implicitly 0.

<a name="frame-keepalive"></a>
### KEEPALIVE Frame (0x03)

KEEPALIVE frames MUST always use Stream ID 0 as they pertain to the Connection.

KEEPALIVE frames MUST be initiated by the client and sent periodically with the (__R__)espond flag set.

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
    |                         Stream ID = 0                         |
    +-----------+-+-+-+-------------+-------------------------------+
    |Frame Type |0|0|R|    Flags    |
    +-----------+-+-+-+-------------+-------------------------------+
    |0|                  Last Received Position                     |
    +                                                               +
    |                                                               |
    +---------------------------------------------------------------+
                                  Data
```

* __Frame Type__: (6 bits = max value 63) 0x03
* __Flags__: (10 bits)
     * (__R__)espond with KEEPALIVE or not
* __Last Received Position__: (63 bits = max value 2^63-1) Unsigned 63-bit long of Resume Last Received Position. Value MUST be > 0. (optional. Set to all 0s when not supported.)
* __Data__: Data attached to a KEEPALIVE.

<a name="frame-request-response"></a>
### REQUEST_RESPONSE Frame (0x04)

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Stream ID                           |
    +-----------+-+-+-+-------------+-------------------------------+
    |Frame Type |0|M|F|     Flags   |
    +-------------------------------+
                         Metadata & Request Data
```

* __Frame Type__: (6 bits = max value 63) 0x04
* __Flags__: (10 bits)
    * (__M__)etadata: Metadata present
    * (__F__)ollows: More fragments follow this fragment.
* __Request Data__: identification of the service being requested along with parameters for the request.

<a name="frame-fnf"></a>
### REQUEST_FNF (Fire-n-Forget) Frame (0x05)

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Stream ID                           |
    +-----------+-+-+-+-------------+-------------------------------+
    |Frame Type |0|M|F|    Flags    |
    +-------------------------------+
                          Metadata & Request Data
```

* __Frame Type__: (6 bits = max value 63) 0x05
* __Flags__: (10 bits)
    * (__M__)etadata: Metadata present
    * (__F__)ollows: More fragments follow this fragment.
* __Request Data__: identification of the service being requested along with parameters for the request.

<a name="frame-request-stream"></a>
### REQUEST_STREAM Frame (0x06)

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Stream ID                           |
    +-----------+-+-+-+-------------+-------------------------------+
    |Frame Type |0|M|F|    Flags    |
    +-------------------------------+-------------------------------+
    |0|                    Initial Request N                        |
    +---------------------------------------------------------------+
                          Metadata & Request Data
```

* __Frame Type__: (6 bits = max value 63) 0x06
* __Flags__: (10 bits)
    * (__M__)etadata: Metadata present
    * (__F__)ollows: More fragments follow this fragment.
* __Initial Request N__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer representing the initial number of items to request. Value MUST be > 0.
* __Request Data__: identification of the service being requested along with parameters for the request.

See [Flow Control: Reactive Streams Semantics](#flow-control-reactive-streams) for more information on RequestN behavior.

<a name="frame-request-channel"></a>
### REQUEST_CHANNEL Frame (0x07)

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Stream ID                           |
    +-----------+-+-+-+-+-----------+-------------------------------+
    |Frame Type |0|M|F|C|  Flags    |
    +-------------------------------+-------------------------------+
    |0|                    Initial Request N                        |
    +---------------------------------------------------------------+
                           Metadata & Request Data
```

* __Frame Type__: (6 bits = max value 63) 0x07
* __Flags__: (10 bits)
    * (__M__)etadata: Metadata present
    * (__F__)ollows: More fragments follow this fragment.
    * (__C__)omplete: bit to indicate stream completion.
	   * If set, `onComplete()` or equivalent will be invoked on Subscriber/Observer.
* __Initial Request N__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer representing the initial request N value for channel. Value MUST be > 0.
* __Request Data__: identification of the service being requested along with parameters for the request.

A requester MUST send only __one__ REQUEST_CHANNEL frame. Subsequent messages from requester to responder MUST be sent as PAYLOAD frames. 

A requester MUST __not__ send PAYLOAD frames after the REQUEST_CHANNEL frame until the responder sends a REQUEST_N frame granting credits for number of PAYLOADs able to be sent.

See Flow Control: Reactive Streams Semantics for more information on RequestN behavior.

<a name="frame-request-n"></a>
### REQUEST_N Frame (0x08)

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Stream ID                           |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |0|0|     Flags     |
    +-------------------------------+-------------------------------+
    |0|                         Request N                           |
    +---------------------------------------------------------------+
```

* __Frame Type__: (6 bits = max value 63) 0x08
* __Request N__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer representing the number of items to request. Value MUST be > 0.

See Flow Control: Reactive Streams Semantics for more information on RequestN behavior.

<a name="frame-cancel"></a>
### CANCEL Frame (0x09)

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Stream ID                           |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |0|0|    Flags      |
    +-------------------------------+-------------------------------+
```

* __Frame Type__: (6 bits = max value 63) 0x09

<a name="frame-payload"></a>
### PAYLOAD Frame (0x0A)

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Stream ID                           |
    +-----------+-+-+-+-+-+---------+-------------------------------+
    |Frame Type |0|M|F|C|N|  Flags  |
    +-------------------------------+-------------------------------+
                         Metadata & Data
```

* __Frame Type__: (6 bits = max value 63) 0x0A
* __Flags__: (10 bits)
    * (__M__)etadata: Metadata Present.
    * (__F__)ollows: More fragments follow this fragment.
    * (__C__)omplete: bit to indicate stream completion.
       * If set, `onComplete()` or equivalent will be invoked on Subscriber/Observer.
    * (__N__)ext: bit to indicate Next (Payload Data and/or Metadata present).
       * If set, `onNext(Payload)` or equivalent will be invoked on Subscriber/Observer.
* __Payload Data__: payload for Reactive Streams onNext.

<a name="frame-metadata-push"></a>
### METADATA_PUSH Frame (0x0C)

A Metadata Push frame can be used to send asynchronous metadata notifications from a Requester or
Responder to its peer.

METADATA_PUSH frames MUST always use Stream ID 0 as they pertain to the Connection.

Metadata tied to a particular stream uses the individual Payload frame Metadata flag.

Frame Contents

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                         Stream ID = 0                         |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |0|1|     Flags     |
    +-------------------------------+-------------------------------+
                                Metadata
```

* __Frame Type__: (6 bits = max value 63) 0x0C

<a name="frame-ext"></a>
### EXT (Extension) Frame (0x3F)

The general format for an extension frame is given below.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                           Stream ID                           |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |I|M|    Flags      |
    +-------------------------------+-------------------------------+
    |0|                      Extended Type                          |
    +---------------------------------------------------------------+
                          Depends on Extended Type...
```

* __Frame Type__: (6 bits = max value 63) 0x3F
* __Flags__: (10 bits)
    * (__I__)gnore: Can the frame be ignored if not understood?
    * (__M__)etadata: Metadata Present.
* __Extended Type__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer of Extended type information. Value MUST be > 0.

## Resuming Operation

Due to the large number of active requests for ReactiveSocket, it is often necessary to provide the ability for resuming operation on transport failure. This behavior is totally optional for operation and may be supported or not based on an implementation choice.

### Assumptions

ReactiveSocket resumption exists only for specific cases. It is not intended to be an “always works” solution. If resuming operation is not possible, the connection should be terminated with an ERROR as specified by the protocol definition.

1. Resumption is optional behavior for implementations. But highly suggested. Clients and Servers should assume NO resumption capability by default.
1. Resumption is an optimistic operation. It may not always succeed.
1. Resumption is desired to be fast and require a minimum of state to be exchanged.
1. Resumption is designed for loss of connectivity and assumes client and server state is maintained across connectivity loss. I.e. there is no assumption of loss of state by either end. This is very important as without it, all the requirements of "guaranteed messaging" come into play.
1. Resumption assumes no changes to Lease, Data format (encoding), etc. for resuming operation. i.e. A client is not allowed to change the metadata MIME type or the data MIME type or version, etc. when resuming operation.
1. Resumption is always initiated by the client and either allowed or denied by the server.
1. Resumption makes no assumptions of application state for delivered frames with respect to atomicity, transactionality, etc. See above.

### Implied Position

Resuming operation requires knowing the position of data reception of the previous connection. For this to be simplified, the underlying transport is assumed to support contiguous delivery of data on a per frame basis. In other words, partial frames are not delivered for processing nor are gaps allowed in the stream of frames sent by either the client or server. The current list of supported transports (TCP, WebSocket, and Aeron) all satisfy this requirement or can be made to do so in the case of TCP.

As a Requester or Responder __sends__ REQUEST, CANCEL, or PAYLOAD frames, it maintains a __position__ of that frame within the connection in that direction. This is a 64-bit value that starts at 0. As a Requester or Responder __receives__ REQUEST, CANCEL, or PAYLOAD frames, it maintains an __implied position__ of that frame within the connection in that direction. This is also a 64-bit value that starts at 0.

The reason this is “implied” is that the position is not included in each frame and is inferred simply by the message being sent/received on the connection in relation to previous frames.

This position will be used to identify the location for resuming operation to begin.

Frame types outside REQUEST, CANCEL, ERROR, and PAYLOAD do not have assigned (nor implied) positions.

When a client sends a RESUME frame, it sends two implied positions: the last frame that was received from the server; the earliest frame position it still retains.  The server can make a determination on whether resumption is possible: have all frames past the client's last-received position been retained? and has the client retained all frames past the server's last-retained position.  If resumption is allowed to continue, the server sends a RESUME_OK frame, indicating its last-received position.

### Client Lifetime Management

Client lifetime management for servers MUST be extended to incorporate the length of time a client may successfully attempt resumption passed a transport disconnect. The means of client lifetime management are totally up to the implementation.

### Resume Operation

All ERROR frames sent MUST be CONNECTION_ERROR or REJECTED_RESUME error code.

Client side resumption operation starts when the client desires to try to resume and starts a new transport connection. The operation then proceeds as the following:

* Client sends RESUME frame. The client MUST NOT send any other frame types until resumption succeeds. The RESUME Identification Token MUST be the token used in the original SETUP frame. The RESUME Last Received Position field MUST be the last successfully received implied position from the server.
* Client waits for either a RESUME_OK or ERROR[CONNECTION_ERROR|REJECTED_RESUME] frame from the server.
* On receiving an ERROR[REJECTED_RESUME] frame, the client MUST NOT attempt resumption again.
* On receiving a RESUME_OK, the client:
    * MUST assume that the next REQUEST, CANCEL, ERROR, and PAYLOAD frames have an implied position commencing from the last implied positions
    * MAY retransmit *all* REQUEST, CANCEL, ERROR, and PAYLOAD frames starting at the RESUME_OK Last Received Position field value from the server.
    * MAY send an ERROR[CONNECTION_ERROR|CONNECTION_CLOSE] frame indicating the end of the connection and MUST NOT attempt resumption again

Server side resumption operation starts when the client sends a RESUME frame. The operation then proceeds as the following:

* On receiving a RESUME frame, the server:
    * MUST send an ERROR[REJECTED_RESUME] frame if the server does not support resuming operation. 
    * use the RESUME Identification Token field to determine which client the resume pertains to. If the client is identified successfully, resumption MAY be continued. If not identified, then the server MUST send an ERROR[REJECTED_RESUME] frame.
    * if successfully identified, then the server MAY send a RESUME_OK and then:
        * MUST assume that the next REQUEST, CANCEL, ERROR, and PAYLOAD frames have an implied position commencing from the last implied positions
        * MAY retransmit *all* REQUEST, CANCEL, ERROR, and PAYLOAD frames starting at the RESUME Last Received Position field value from the client.
    * if successfully identified, then the server MAY send an ERROR[REJECTED_RESUME] frame if the server can not resume operation given the value of RESUME Last Received Position if the position is not one it deems valid to resume operation from or other extenuating circumstances.

A Server that receives a RESUME frame after a SETUP frame, SHOULD send an ERROR[CONNECTION_ERROR].

A Server that receives a RESUME frame after a previous RESUME frame, SHOULD send an ERROR[CONNECTION_ERROR].

Leasing semantics are NOT assumed to carry over from previous connections when resuming. LEASE semantics MUST be restarted upon a new connection by sending a LEASE frame from the server.

<a name="frame-resume"></a>
#### RESUME Frame (0x0D)

The general format for a Resume frame is given below.

RESUME frames MUST always use Stream ID 0 as they pertain to the connection.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                         Stream ID = 0                         |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |0|0|    Flags      |
    +-------------------------------+-------------------------------+
    |        Major Version          |         Minor Version         |
    +-------------------------------+-------------------------------+
    |         Token Length          | Resume Identification Token  ...
    +---------------------------------------------------------------+
    |0|                                                             |
    +                 Last Received Server Position                 +
    |                                                               |
    +---------------------------------------------------------------+
    |0|                                                             |
    +                First Available Client Position                +
    |                                                               |
    +---------------------------------------------------------------+
```

* __Frame Type__: (6 bits = max value 63) 0x0D
* __Major Version__: (16 bits = max value 65,535) Unsigned 16-bit integer of Major version number of the protocol.
* __Minor Version__: (16 bits = max value 65,535) Unsigned 16-bit integer of Minor version number of the protocol.
* __Resume Identification Token Length__: (16 bits = max value 65,535) Unsigned 16-bit integer of Resume Identification Token Length in bytes. 
* __Resume Identification Token__: Token used for client resume identification. Same Resume Identification used in the initial SETUP by the client.
* __Last Received Server Position__: (63 bits = max value 2^63-1) Unsigned 63-bit long of the last implied position the client received from the server. Value MUST be >= 0.
* __First Available Client Position__: (63 bits = max value 2^63-1) Unsigned 63-bit long of the earliest position that the client can rewind back to prior to resending frames. Value MUST be >= 0.

<a name="frame-resume-ok"></a>
#### RESUME_OK Frame (0x0E)

The general format for a Resume OK frame is given below.

RESUME OK frames MUST always use Stream ID 0 as they pertain to the connection.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                         Stream ID = 0                         |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |0|0|    Flags      |
    +-------------------------------+-------------------------------+
    |0|                                                             |
    +               Last Received Client Position                   +
    |                                                               |
    +---------------------------------------------------------------+
```

* __Frame Type__: (6 bits = max value 63) 0x0E
* __Last Received Client Position__: (63 bits = max value 2^63-1) Unsigned 63-bit long of the last implied position the server received from the client. Value MUST be >= 0.

#### Keepalive Position Field

Keepalive frames include the implied position of the client (or server). When sent, they act as a means for the other end of the connection to know the position of the other side.

This information MAY be used to update state for possible retransmission, such as trimming a retransmit buffer, or possible associations with individual stream status.

### Identification Token Handling

The requirements for the Resume Identification Token are implementation dependent. However, some guidelines and considerations are:

* Tokens may be generated by the client.
* Tokens may be generated outside the client and the server and managed externally to the protocol.
* Tokens should uniquely identify a connection on the server. The server should not assume a generation method of the token and should consider the token opaque. This allows a client to be compatible with any ReactiveSocket implementation that supports resuming operation and allows the client full control of Identification Token generation.
* Tokens MUST be valid for the lifetime of an individual ReactiveSocket including possible resumption.
* A server should not accept a SETUP with a Token that is currently already being used
* Tokens should be resilient to replay attacks and thus should only be valid for the lifetime of an individual connection
* Tokens should not be predictable by an attacking 3rd party

## Connection Establishment

__NOTE__: The semantics are similar to [TLS False Start](https://tools.ietf.org/html/draft-bmoeller-tls-falsestart-00).

Immediately upon successful connection, the client MUST send either a SETUP or RESUME frame with
Stream ID of 0. Any other frame received that is NOT a SETUP|RESUME frame or a SETUP|RESUME frame with
a Stream ID > 0, MUST cause the server to send an ERROR[INVALID_SETUP] and close the connection. 

See [Resume Operation](#resume-operation) for more information about resuming. The rest of this section assumes use of SETUP for establishing a connection.

The client-side Requester can inform the server-side Responder as to whether it will
honor LEASEs or not based on the presence of the __L__ flag in the SETUP frame.

The client-side Requester that has NOT set the __L__ flag in the SETUP frame may send
requests immediately if it so desires without waiting for a LEASE from the server.

The client-side Requester that has set the __L__ flag in the SETUP frame MUST wait
for the server-side Responder to send a LEASE frame before it can send requests.

If the server accepts the contents of the SETUP frame, it MUST send a LEASE frame if
the SETUP frame set the __L__ flag. The server-side Requester may send requests
immediately upon receiving a SETUP frame that it accepts if the __L__ flag is not set in the SETUP frame.

If the server does NOT accept the contents of the SETUP frame, the server MUST send
back an ERROR[INVALID_SETUP|UNSUPPORTED_SETUP] and then close the connection.

The __S__ flag of the SETUP indicates the client requires the server to adhere to strict interpretation
of the Data and Metadata of the SETUP. Anything in the Data and/or Metadata that is not understood or can
be provided by the server should require the SETUP to be rejected.

The server-side Requester mirrors the LEASE requests of the client-side Requester. If a client-side
Requester sets the __L__ flag in the SETUP frame, the server-side Requester MUST wait for a LEASE
frame from the client-side Responder before it can send a request. The client-side Responder MUST
send a LEASE frame after a SETUP frame with the __L__ flag set.

A client assumes a SETUP is accepted if it receives a response to a request, a LEASE
frame, or if it sees a REQUEST type.

A client assumes a SETUP is rejected if it receives an ERROR.

Until connection establishment is complete, a Requester MUST NOT send any Request frames.

Until connection establishment is complete, a Responder MUST NOT emit any PAYLOAD frames.

### Negotiation

The assumption is that the client will be dictating to the server what it desires to do. The server will decide to support
that SETUP (accept it) or not (reject it). The ERROR[INVALID_SETUP|UNSUPPORTED_SETUP|REJECTED_SETUP] error code indicates the reason for the rejection.

### Sequences without LEASE

The possible sequences without LEASE are below.

1. Client-side Request, Server-side __accepts__ SETUP
    * Client connects & sends SETUP & sends REQUEST
    * Server accepts SETUP, handles REQUEST, sends back normal sequence based on REQUEST type
1. Client-side Request, Server-side __rejects__ SETUP
    * Client connects & sends SETUP & sends REQUEST
    * Server rejects SETUP, sends back ERROR[INVALID_SETUP|UNSUPPORTED_SETUP|REJECTED_SETUP], closes connection
1. Server-side Request, Server-side __accepts__ SETUP
    * Client connects & sends SETUP
    * Server accepts SETUP, sends back REQUEST type
1. Server-side Request, Server-side __rejects__ SETUP
    * Client connects & sends SETUP
    * Server rejects SETUP, sends back ERROR[INVALID_SETUP|UNSUPPORTED_SETUP|REJECTED_SETUP], closes connection

### Sequences with LEASE

The possible sequences with LEASE are below.

1. Client-side Request, Server-side __accepts__ SETUP
    * Client connects & sends SETUP with __L__ flag
    * Server accepts SETUP, sends back LEASE frame
    * Client-side sends REQUEST
1. Client-side Request, Server-side __rejects__ SETUP
    * Client connects & sends SETUP with __L__ flag
    * Server rejects SETUP, sends back ERROR[INVALID_SETUP|UNSUPPORTED_SETUP|REJECTED_SETUP], closes connection
1. Server-side Request, Server-side __accepts__ SETUP
    * Client connects & sends SETUP with __L__ flag
    * Server accepts SETUP, sends back LEASE frame
    * Client sends LEASE frame
    * Server sends REQUEST
1. Server-side Request, Server-side __rejects__ SETUP
    * Client connects & sends SETUP with __L__ flag
    * Server rejects SETUP, sends back ERROR[INVALID_SETUP|UNSUPPORTED_SETUP|REJECTED_SETUP], closes connection

## Fragmentation And Reassembly

PAYLOAD frames and all REQUEST frames may represent a large object and MAY need to be fragmented to fit within the Frame Data size. When this occurs, the __F__ flag indicates if more fragments follow the current frame (or not).

Fragmentation does not change the request(n) or lease counts. In other words, a fragmented PAYLOAD frame counts as a single request(n) credit, and a request counts against a single lease count, regardless of how many fragments the frame is split into.

#### PAYLOAD Frame

When a PAYLOAD frame needs to be fragmented, a sequence of PAYLOAD frames is delivered using the (F)ollows flag.

When a PAYLOAD is fragmented, the Metadata MUST be transmitted completely before the Data. 

For example, a single PAYLOAD with 20MB of Metdata and 25MB of Data that is fragmented into 3 frames:

```
-- PAYLOAD frame 1
Frame length = 16MB
(M)etadata present = 1
(F)ollows = 1 (fragments coming)
Metadata Length = 16MB

16MB of METADATA
0MB of Data

-- PAYLOAD frame 2
Frame length = 16MB
(M)etadata present = 1
(F)ollows = 1 (fragments coming)
Metadata Length = 4MB

4MB of METADATA
12MB of Data

-- PAYLOAD frame 3
Frame length = 13MB
(M)etadata present = 0
(F)ollows = 0

0MB of METADATA
13MB of Data
```

If the sender (Requester or Responder) wants to cancel sending a fragmented sequence, it MAY send a CANCEL frame without finishing delivery of the fragments. 

#### REQUEST Frames

When REQUEST_RESPONSE, REQUEST_FNF, REQUEST_STREAM, or REQUEST_CHANNEL frames need to be fragmented, the first frame is the REQUEST_* frame with the (F)ollows flag set, followed by a sequence of PAYLOAD frames.

When fragmented, the Metadata MUST be transmitted completely before the Data. 

For example, a single PAYLOAD with 20MB of Metdata and 25MB of Data that is fragmented into 3 frames:

```
-- REQUEST_RESPONSE frame 1
Frame length = 16MB
(M)etadata present = 1
(F)ollows = 1 (fragments coming)
Metadata Length = 16MB

16MB of METADATA
0MB of Data

-- PAYLOAD frame 2
Frame length = 16MB
(M)etadata present = 1
(F)ollows = 1 (fragments coming)
Metadata Length = 4MB

4MB of METADATA
12MB of Data

-- PAYLOAD frame 3
Frame length = 13MB
(M)etadata present = 0
(F)ollows = 0

0MB of METADATA
13MB of Data
```

If the Requester wants to cancel sending a fragmented sequence, it MAY send a CANCEL frame without finishing delivery of the fragments. 

## Stream Sequences and Lifetimes

Streams exists for a specific period of time. So an implementation may assume that Stream IDs are valid for a finite period of time. This period of time is bound by either a) the lifetime of the underlying transport protocol connection, or b) the lifetime of a session if resumability is used to extend the session across multiple transport protocol connections. Beyond that, each interaction pattern imposes lifetime based on a sequence of interactions between Requester and Responder.

In the section below, "RQ -> RS" refers to Requester sending a frame to a Responder. And "RS -> RQ" refers to Responder sending
a frame to a Requester.

In the section below, "*" refers to 0 or more and "+" refers to 1 or more.

Once a stream has "terminated", the Stream ID can be "forgotten" by the Requester and Responder, but the Stream ID MUST NOT be re-used. See [Stream Identifier](#stream-identifiers) for more information.

<a name="stream-sequences-request-response"></a>
### Request Response

1. RQ -> RS: REQUEST_RESPONSE
1. RS -> RQ: PAYLOAD with COMPLETE

or

1. RQ -> RS: REQUEST_RESPONSE
1. RS -> RQ: ERROR[APPLICATION_ERROR|REJECTED|CANCELED|INVALID]

or

1. RQ -> RS: REQUEST_RESPONSE
1. RQ -> RS: CANCEL

Upon sending a response, the stream is terminated on the Responder.

Upon receiving a CANCEL, the stream is terminated on the Responder and the response SHOULD not be sent.

Upon sending a CANCEL, the stream is terminated on the Requester.

Upon receiving a COMPLETE or ERROR[APPLICATION_ERROR|REJECTED|CANCELED|INVALID], the stream is terminated on the Requester.

<a name="stream-sequences-fire-and-forget"></a>
### Request Fire-n-Forget

1. RQ -> RS: REQUEST_FNF

Upon reception, the stream is terminated by the Responder.

Upon being sent, the stream is terminated by the Requester.

REQUEST_FNF are assumed to be best effort and MAY not be processed due to: (1) SETUP rejection, (2) mis-formatting, (3) etc.

<a name="stream-sequences-request-stream"></a>
### Request Stream

1. RQ -> RS: REQUEST_STREAM
1. RS -> RQ: PAYLOAD*
1. RS -> RQ: ERROR[APPLICATION_ERROR|REJECTED|CANCELED|INVALID]

or

1. RQ -> RS: REQUEST_STREAM
1. RS -> RQ: PAYLOAD*
1. RS -> RQ: COMPLETE

or

1. RQ -> RS: REQUEST_STREAM
1. RS -> RQ: PAYLOAD*
1. RQ -> RS: CANCEL

At any time, the Requester may send REQUEST_N frames.

Upon receiving a CANCEL, the stream is terminated on the Responder.

Upon sending a CANCEL, the stream is terminated on the Requester.

Upon receiving a COMPLETE or ERROR[APPLICATION_ERROR|REJECTED|CANCELED|INVALID], the stream is terminated on the Requester.

Upon sending a COMPLETE or ERROR[APPLICATION_ERROR|REJECTED|CANCELED|INVALID], the stream is terminated on the Responder.

<a name="stream-sequences-channel"></a>
### Request Channel

#### COMPLETE from Requester and Responder

1. RQ -> RS: REQUEST_CHANNEL
1. RQ -> RS: PAYLOAD*
1. RQ -> RS: COMPLETE

  intermixed with 
  
1. RS -> RQ: PAYLOAD*
1. RS -> RQ: COMPLETE

#### Error from Requester, Responder terminates

1. RQ -> RS: REQUEST_CHANNEL
1. RQ -> RS: PAYLOAD*
1. RQ -> RS: ERROR[APPLICATION_ERROR]

  intermixed with 
  
1. RS -> RQ: PAYLOAD*

#### Error from Requester, Responder already Completed

1. RQ -> RS: REQUEST_CHANNEL
1. RQ -> RS: PAYLOAD*
1. RQ -> RS: ERROR[APPLICATION_ERROR]

  intermixed with 
  
1. RS -> RQ: PAYLOAD*
1. RS -> RQ: COMPLETE

#### Error from Responder, Requester terminates

1. RQ -> RS: REQUEST_CHANNEL
1. RQ -> RS: PAYLOAD*

  intermixed with 
  
1. RS -> RQ: PAYLOAD*
1. RS -> RQ: ERROR[APPLICATION_ERROR|REJECTED|CANCELED|INVALID]

#### Error from Responder, Requester already Completed

1. RQ -> RS: REQUEST_CHANNEL
1. RQ -> RS: PAYLOAD*
1. RQ -> RS: COMPLETE

  intermixed with 
  
1. RS -> RQ: PAYLOAD*
1. RS -> RQ: ERROR[APPLICATION_ERROR|REJECTED|CANCELED|INVALID]

#### Cancel from Requester, Responder terminates

1. RQ -> RS: REQUEST_CHANNEL
1. RQ -> RS: PAYLOAD*
1. RQ -> RS: COMPLETE
1. RQ -> RS: CANCEL

  intermixed with 
  
1. RS -> RQ: PAYLOAD*


At any time, a Requester may send PAYLOAD frames.

At any time, a Requester, as well as a Responder, may send REQUEST_N frames.

An implementation MUST only send a single initial REQUEST_CHANNEL frame from the Requester to the Responder. And
a Responder MUST respond to an initial REQUEST_CHANNEL frame with a REQUEST_N frame.

Upon receiving a CANCEL, the stream is terminated on the Responder.

Upon sending a CANCEL, the stream is terminated on the Requester.

Upon receiving an ERROR[APPLICATION_ERROR|REJECTED|CANCELED|INVALID], the stream is terminated on both Requester and Responder.

Upon sending an ERROR[APPLICATION_ERROR|REJECTED|CANCELED|INVALID], the stream is terminated on both the Requester and Responder.

In absence of ERROR or CANCEL, the stream is terminated after both Requester and Responder have sent and received COMPLETE.

A Requester may indicate COMPLETE by setting the C bit on either the initial REQUEST_CHANNEL frame, or on the last PAYLOAD frame sent. A Requester MUST NOT send any additional PAYLOAD frames after sending a frame with the C bit set.

### Flow Control

There are multiple flow control mechanics provided by the protocol.

<a name="flow-control-reactive-streams"></a>
#### Reactive Streams Semantics

[Reactive Streams](http://www.reactive-streams.org/) semantics are used for flow control of Streams, Subscriptions, and Channels. This is a credit-based model where the Requester grants the Responder credit for the number of PAYLOADs it can send. It is sometimes referred to as "request-n" or "request(n)". 

Credits are cumulative. Once credits are granted from Requester to Responder, they cannot be revoked. For example, sending `request(3)` and `request(2)` accumulates to a value of 5, allowing the Responder to send 5 PAYLOADs.

Please note that this explicitly does NOT follow rule number 17 in https://github.com/reactive-streams/reactive-streams-jvm/blob/v1.0.0/README.md#3-subscription-code

While Reactive Streams support a demand of up to 2^63-1, and treats 2^63-1 as a magic number signaling to not track demand, this is not the case for ReactiveSocket. ReactiveSocket prioritizes byte size and only uses 4 bytes instead of 8 so the magic number is unavailable.

The Requester and the Responder MUST respect the Reactive Streams semantics.

e.g. here's an example of a successful stream call with flow-control.

1. RQ -> RS: REQUEST_STREAM (REQUEST_N=3)
1. RS -> RQ: PAYLOAD
1. RS -> RQ: PAYLOAD
1. RS -> RQ: PAYLOAD
1. RS needs to wait for a new REQUEST_N at that point
1. RQ -> RS: REQUEST_N (N=3)
1. RS -> RQ: PAYLOAD
1. RS -> RQ: PAYLOAD with COMPLETE

<a name="flow-control-lease"></a>
#### Lease Semantics

The LEASE semantics are to control the number of indivdiual requests (all types) that a Requester may send in a given period.
The only responsibility the protocol implementation has for the LEASE is to honor it on the Requester side. The Responder application
is responsible for the logic of generation and informing the Responder it should send a LEASE to the peer Requester.

Requester MUST respect the LEASE contract. The Requester MUST NOT send more than __Number of Requests__ specified
in the LEASE frame within the __Time-To-Live__ value in the LEASE.

A Responder that receives a REQUEST that it can not honor due to LEASE restrictions MUST respond with an ERROR[REJECTED]. This includes an initial LEASE sent as part of [Connection Establishment](#connection-establishment).

<a name="flow-control-qos"></a>
#### QoS and Prioritization

Quality of Service and Prioritization of streams are considered application or network layer concerns and are better dealt with
at those layers. The metadata capabilities, including METADATA_PUSH, are tools that applications can use for effective prioritization.
DiffServ via IP QoS are best handled by the underlying network layer protocols.

### Handling the Unexpected

This protocol attempts to be very lenient in processing of received frames and SHOULD ignore
conditions that do not make sense given the current context. Clarifications are given below:

1. TCP half-open connections (and WebSockets) or other dead transports are detectable by lack of KEEPALIVE frames as specified
under [Keepalive Frame](#frame-keepalive). The decision to close a connection due to inactivity is the applications choice.
1. Request keepalive and timeout semantics are the responsibility of the application.
1. Lack of REQUEST_N frames that stops a stream is an application concern and SHALL NOT be handled by the protocol.
1. Lack of LEASE frames that stops new Requests is an application concern and SHALL NOT be handled by the protocol.
1. If a PAYLOAD for a REQUEST_RESPONSE is received that does not have a COMPLETE flag set, the implementation MUST
assume it is set and act accordingly.
1. Reassembly of PAYLOADs and REQUEST_CHANNELs MUST assume the possibility of an infinite stream.
1. A PAYLOAD with both __F__ and __C__ flags set, implicitly ignores the __F__ flag.
1. Flag bits not specified for a particular frame MUST be ignored. 
1. All other received frames that are not accounted for in previous sections MUST be ignored. Thus, for example:
    1. Receiving a Request frame on a Stream ID that is already in use MUST be ignored.
    1. Receiving a CANCEL on an unknown Stream ID (including 0) MUST be ignored.
    1. Receiving an ERROR on an unknown Stream ID MUST be ignored.
    1. Receiving a PAYLOAD on an unknown Stream ID (including 0) MUST be ignored.
    1. Receiving a METADATA_PUSH with a non-0 Stream ID MUST be ignored.
	1. A server MUST ignore a SETUP frame after it has accepted a previous SETUP.
	1. A server MUST ignore an ERROR[INVALID_SETUP|UNSUPPORTED_SETUP|REJECTED_SETUP|REJECTED_RESUME] frame.
	1. A client MUST ignore an ERROR[INVALID_SETUP|UNSUPPORTED_SETUP|REJECTED_SETUP|REJECTED_RESUME] frame after it has completed connection establishment.
	1. A client MUST ignore a SETUP frame.
