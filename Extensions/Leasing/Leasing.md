# Leasing Strategy Extension

_This extension specification is currently incubating.  While incubating the version is 0._

## Introduction
When two systems are communicating via RSocket, it is crucial to provide a way of preserving systems stability. Even though the Leasing specification brings such an opportunity, it is not always possible to use the same leasing strategy to make communication stable.  This extension specification provides a way to specify by a `Client` using [`CompositeMedata`][cm] a set of Leasing strategies so the `Server` can choose one of them depends on the requirements and then respond as defined in the [negotiation](#negotiation) section.

## Metadata Payload
This metadata type is intended to be used per connection, and not per stream, nor individual payloads, and as such it **MUST** only be used in the [`SETUP`][sf] frame type.  The Metadata MIME Type is `message/x.rsocket.supported-lease-strategies.v0`.

[sf]: ../../Protocol.md#frame-setup

### Metadata Contents
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |L| Type ID/Len |   Lease Strategy                             ...
    +---------------+---------------+---------------+---------------+
    |L| Type ID/Len |   Lease Strategy                             ...
    +---------------+---------------+---------------+---------------+
                                   ...
```

* (**L**)Lease Strategy: Lease strategy is a well known value represented by a unique integer.  If L flag is set (a value of `1`), it indicates a [Well-known Lease Strategy ID][wk].  If L flag is not set (a value of `0`), it indicates the Lease Strategy Length in bytes.
* **Lease Strategy ID/Length**: (7 bits = max value 2^7 = 128) Unsigned 7-bit integer.  If L flag is set (a value of `1`), it indicates a [Well-known Lease Strategy ID][wk].  If A flag is not set (a value of `0`), it indicates the Lease Strategy Length in bytes.
* **Lease Strategy**: the strategy for leasing. This SHOULD be a US-ASCII string.  The string MUST NOT be null terminated.  (Not present if L flag is set)

[wk]: WellKnownLeaseStrategies.md


## Negotiation

Once a `Client` specified [supported lease strategies](#metadata-payload), the `Server` MUST select one of the provided supported lease strategies or reject if none of the provided are supported.  In turn, to encode the selected lease strategy, `Server` MUST use the metadata field of the `LEASE`:

### Metadata Contents
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |L| Type ID/Len |   Lease Strategy                                  
    +---------------+---------------+---------------+---------------+
```

* (**L**)Lease Strategy: Lease strategy is a well known value represented by a unique integer.  If L flag is set (a value of `1`), it indicates a [Well-known Strategy Type ID][wk].  If L flag is not set (a value of `0`), it indicates the Lease Strategy Length in bytes.
* **Lease Strategy ID/Length**: (7 bits = max value 2^7 = 128) Unsigned 7-bit integer.  If L flag is set (a value of `1`), it indicates a [Well-known Strategy Type ID][wk].  If A flag is not set (a value of `0`), it indicates the Lease Strategy Length in bytes.
* **Lease Strategy**: the strategy for leasing. This SHOULD be a US-ASCII string.  The string MUST NOT be null terminated.  (Not present if L flag is set)

[wk]: WellKnownLeaseStrategies.md

Note, if the selected lease strategy has a different frame layout than the default one, the first [`LEASE`][lf] frame MUST follow the default [`LEASE`][lf] frame layout to let the `Client` read metadata field content 


[lf]: ../../Protocol.md#frame-lease

### Handling Unexpected

If `Server` does not specify lease strategy defined in the [negotiation](#negotiation) section, the `Client` MUST close the connection with the __CONNECTION_ERROR__ [Error Code][ec] and reestablishe connection without specifying lease strategies or without leasing at all.

[ec]: ../../Protocol.md#error-codes