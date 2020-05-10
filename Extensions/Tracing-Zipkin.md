# Tracing (Zipkin) Metadata Extension

_This extension specification is currently incubating.  While incubating the version is 0._

## Introduction
Observability and tracing are key requirements for robust and reliable applications.  When using distributed applications connected with RSocket, it's important to propagate metadata about the current logical operations throughout the entire system.  One of the most popular systems for doing this kind of tracing is [Zipkin][z].  This extension specification provides an interoperable structure for Zipkin metadata payloads to contain tracing information.  It is designed such that systems can efficently communicate span and trace information to a Zipkin server and propagate that information throughout a distributed system.

[z]: https://zipkin.io

## Metadata Payload
This metadata type is intended to be used per stream, and not per connection nor individual payloads and as such it **MUST** only be used in frame types used to initiate interactions and payloads.  This includes [`REQUEST_FNF`][rf], [`REQUEST_RESPONSE`][rr], [`REQUEST_STREAM`][rs], [`REQUEST_CHANNEL`][rc], and [`PAYLOAD`][p].  The Metadata MIME Type is `message/x.rsocket.tracing-zipkin.v0`.

[p]:  ../Protocol.md#frame-payload
[rc]: ../Protocol.md#frame-request-channel
[rf]: ../Protocol.md#frame-fnf
[rr]: ../Protocol.md#frame-request-response
[rs]: ../Protocol.md#frame-request-stream

### Metadata Contents
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |B|D|S|R|T|P|   |
    +-+-+---+---+---+-----------------------------------------------+
    |                                                               |
    +                                                               +
    |                                                               |
    +                           Trace ID                            +
    |                                                               |
    +                                                               +
    |                                                               |
    +---------------------------------------------------------------+
    |                                                               |
    +                           Span ID                             +
    |                                                               |
    +---------------------------------------------------------------+
    |                                                               |
    +                        Parent Span ID                         +
    |                                                               |
    +---------------------------------------------------------------+
```

* **Flags**: (8 bits)
  * (**I**)Ds Set: When zero, the metadata only includes sampling information and no IDs
    * For example, a health check might set only the (**N**)ot Sampled flag without generating IDs
  * (**D**)ebug: Tracing payload should be force traced.
  * (**S**)ample: Tracing payload should be accepted for tracing. (Ignored when D flag is set.)
  * (**R**)eject: Tracing payload should not be sampled. (Ignored when S flag or D flag is set.)
  * (**T**)race Id Size: Unset indicates that the Trace Id is 64-bit. Set indicates that the Trace Id is 128-bit.
  * (**P**)arent Span Id: Tracing payload contains a parent span id.
* **Trace ID**: (64 or 128 bits) Unsigned 64- or 128-bit integer ID of the trace. Every span in a trace shares this ID.
* **Span ID**: (64 bits) Unsigned 64-bit integer ID for a particular span. This may or may not be the same as the trace id.
* **Parent Span ID**: (64 bits) Unsigned 64-bit integer ID for a particular parent span.  This is an optional ID that will only be present on child spans. That is the span without a parent id is considered the root of the trace. (Not present if P flag is not set)
