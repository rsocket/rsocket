## Introduction

## Terminology

* __Frame__: A frame of data containing 1 or more headers chained together that contain data, control,
and metadata.
* __Transport__: Protocol used to carry ReactiveSockets protocol. Such as WebSockets, TCP, Aeron, etc.

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
    |    Version    |  Next Header  |          Reserved             |
    +---------------+---------------+-------------------------------+
                                  Headers
```

* __Frame Length__: (31 = max 2147483647 bytes) Length of Frame. Including header. Only used for TCP.
* __Version__: (8) Current version is 0.
* __Next Header__: (8) Type of next header.

### Header Chains

ReactiveSocket uses IPv6-style header chains to provide flexibility. The general format
for a header is given below.

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |  Next Header  |I|             |        Header Length          |
    +---------------+-+-------------+-------------------------------+
                               Header Data
```

* __Next Header__: (8) Type of next header.
* __Flags__:
    * (__I__)gnore: ignore current header is not understood.
* __Header Length__: (16) Length of current header in bytes (16 = max 65535 bytes)

### Header Types

|  Type              | Value  | Description |
|:-------------------|:-------|:------------|
| __NHDR_PAD__   | 0x00 | __Reserved__ |
| __NHDR_DATA__  | 0x01 | __Data__: Data |
| __NHDR_ERR__   | 0x02 | __Error__: Error |
| __NHDR_SETUP__ | 0x03 | __Setup__: Setup. |
| __NHDR_EXT__   | 0xFF | __Extension Header__: Used to extend more options as well as extensions (TBD). |
