# Routing Metadata Extension

_This extension specification is currently incubating.  While incubating the version is 0._

## Introduction
When two system are communicating via RSocket, there are often logical divisions in the messages that are sent from the requester to the responder.  These logical divisions can often be implemented by the responder as "routes" for messages to be sent to.  This extension specification provides an interoperable structure for metadata payloads to contain routing information.  It is designed such that an arbitrary collection of tags (strings) can be used by the responder to route messages and any individual tag (or all included tags) can be ignored.

## Metadata Payload
This metadata type is intended to be used per stream, and not per connection nor individual payloads and as such it **MUST** only be used in frame types used to initiate interactions.  This includes [`REQUEST_FNF`][rf], [`REQUEST_RESPONSE`][rr], [`REQUEST_STREAM`][rs], and [`REQUEST_CHANNEL`][rc].  The Metadata MIME Type is `message/x.rsocket.routing.v0`.

[rc]: ../Protocol.md#frame-request-channel
[rf]: ../Protocol.md#frame-fnf
[rr]: ../Protocol.md#frame-request-response
[rs]: ../Protocol.md#frame-request-stream

### Metadata Contents
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |  Tag Length   |              Tag                             ...
    +---------------+-----------------------------------------------+
    |  Tag Length   |              Tag                             ...
    +---------------+-----------------------------------------------+
                                   ...
```

* **Tag Payload**: Any number of complete tag payloads.
  * **Tag Length**: (8 bits = max value 2^8 = 256) Unsigned 8-bit integer of Tag Length in bytes.
  * **Tag**:  The UTF-8 encoded Token used for routing.  The string MUST NOT be null terminated.  Examples include URI-style routes (`/person`, `/address`), or artibrary metadata (`ios-client`, `android-client`).
