## Introduction

## Terminology

* __Frame__: A frame of data containing 1 or more headers chained together that contain data, control,
and metadata.
* __Transport__: Protocol used to carry ReactiveSockets protocol. Such as WebSockets, TCP, Aeron, etc.
* __Header__: Unit of 
* __Stream__: Unit of operation (request/response, etc.). See [Design Principles](DesignPrinciples.md).

## Operation

### Frame Header Format

ReactiveSocket frames begin with a header. The general layout is given below. When used over
transport protocols that provide framing (WebSocket and Aeron), the Frame Length field is not included.
For transports that do not provide framing, such as TCP, the Frame Length is included

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|                       Frame Length                          |
    +---------------+---------------+-------------------------------+
    |    Version    |                  Reserved                     |
    +---------------+-----------------------------------------------+
    |                           Stream ID                           |
    |                                                               |
    +---------------------------------------------------------------+
                                  Headers
```

* __Frame Length__: (31 = max 2147483647 bytes) Length of Frame. Including header. Only used for TCP.
* __Version__: (8) Current version is 0.
* __Stream ID__: (64) Stream Identifier for this frame.

### Header Chains

ReactiveSocket uses IPv6-style header chains to provide flexibility. The general layout of a ReactiveSocket
frame is a Frame Header followed by 1 or more Headers.

```
     +----------------------------------------+
     |       Frame Length (for TCP only)      |
     +----------------------------------------+
     | Frame Header (version, Stream ID, etc.)|
     +----------------------------------------+
     |                 Header                 |
     +----------------------------------------+
     |                 Header                 |
     +----------------------------------------+
     |                 ......                 |
     +----------------------------------------+
     |                 Header                 |
     +----------------------------------------+
```

The general format for a header is given below.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |     Type      |I|                Header Length                |
    +---------------+-+---------------------------------------------+
                        Header Data (Depends on Type)
```

* __Type__: (8) Type of header.
* __Flags__:
    * (__I__)gnore: ignore current header if not understood.
* __Header Length__: (23) Length of current header in bytes (23 = max 8,388,608 bytes). Includes
the Type and Header Length fields.

### Header Types

|  Type                              | Value  | Description |
|:-----------------------------------|:-------|:------------|
| __HDR_RESERVED                     | 0x00 | __Reserved__ |
| __HDR_SUBSCRIBE_REQUEST_RESPONSE__ | 0x01 | __SUBSCRIBE_REQUEST_RESPONSE__: |
| __HDR_SUBSCRIBE_STREAM__           | 0x02 | __SUBSCRIBE_STREAM__: |
| __HDR_STREAM_REQUEST__             | 0x03 | __STREAM_REQUEST__: |
| __HDR_DISPOSE__                    | 0x04 | __DISPOSE__: |
| __HDR_NEXT_COMPLETE__              | 0x05 | __NEXT_COMPLETE__: |
| __HDR_NEXT__                       | 0x06 | __NEXT__: |
| __HDR_ERROR__                      | 0x07 | __ERROR__: Error |
| __HDR_COMPLETE__                   | 0x08 | __COMPLETE__: |
| __HDR_SETUP__                      | 0x09 | __Setup__: Setup. |
| __HDR_EXT__                        | 0xFF | __Extension Header__: Used to extend more options as well as extensions (TBD). |

### Subscribe Request Response

Contents
1. 

### Subscribe Stream

Contents
1.

### Stream Request

Contents
1.

### Dispose

Contents
1.

### Next Complete

Contents
1.

### Next

Contents
1.

### Error

Contents
1.

### Complete

Contents
1.

### Setup

Contents
1.

### Extension Header

The general format for a header is given below.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |     0xFF      |1|             Extension Type                  |
    +---------------+-+---------------------------------------------+
    |                         Header Length                         |
    +---------------------------------------------------------------+
                          Depends on Extension Type...
```

* __Type__: (8) 0xFF for Extension Header.
* __Flags__:
    * (__I__)gnore: Can be ignored.
* __Header Length__: (24) Length of current header in bytes (32 = max 4,294,967,296 bytes). Includes
the Type, Extension Type, and Header Length fields.

## Stream Sequences and Lifetimes

### Subscribe Request Response

To Server: SUBSCRIBE_REQUEST_RESPONSE
To Client: DATA? (once?)
To Server: DISPOSE | NEXT_COMPLETE | ERROR

### Subscribe Stream

To Server: SUBSCRIBE_STREAM
To Client: DATA?
To Server: DISPOSE | NEXT | COMPLETE | ERROR
