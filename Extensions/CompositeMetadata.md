# Composite Metadata Extension

_This extension specification is currently incubating.  While incubating the version is 0._

## Introduction
There are a number of situations where an arbitrary collection of discrete metadata types should be attached to frame.  For example, a request frame may want to include both routing metadata as well as tracing metadata.  This extension specification provides an interoperable structure for metadadata payloads to contain multiple discrete metadata types.  It is designed such that if a consumer of the metadata is unaware of a particular type, it can be safely skipped and the next one read.

## Metadata Payload
This metadata type is intended to be used per stream, and not per connection nor individual payloads and as such it **MUST** only be used in frame types used to initiate interactions.  This includes [`REQUEST_FNF`][rf], [`REQUEST_RESPONSE`][rr], [`REQUEST_STREAM`][rs], and [`REQUEST_CHANNEL`][rc].  Multiple metadata payloads with the same MIME type are allowed.  The order of metadata payloads MUST be preserved when presented to responders.  The [`SETUP` Frame][s] Metadata MIME Type is `message/x.rsocket.composite-metadata.v0`.

[rc]: ../Protocol.md#frame-request-channel
[rf]: ../Protocol.md#frame-fnf
[rr]: ../Protocol.md#frame-request-response
[rs]: ../Protocol.md#frame-request-stream
[s]:  ../Protocol.md#frame-setup

### Metadata Contents
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |M| MIME ID/Len |   Metadata Encoding MIME Type                ...
    +---------------+---------------+---------------+---------------+
    |              Metadata Length                  |
    +-----------------------------------------------+---------------+
    |                     Metadata Payload                         ...
    +---------------+-----------------------------------------------+
    |M| MIME ID/Len |   Metadata Encoding MIME Type                ...
    +---------------+-------------------------------+---------------+
    |              Metadata Length                  |
    +-----------------------------------------------+---------------+
    |                     Metadata Payload                         ...
    +---------------------------------------------------------------+
                                   ...
```

* **Metadata Payload**: Any number of complete metadata payloads.
  * (**M**)etadata Type: Metadata type is a well known value represented by a unique integer.
  * **MIME ID/Length**: (7 bits = max value 2^7 = 128) Unsigned 7-bit integer.  If M flag is set, indicates a [Well-known MIME Type ID][wk].  If M flag is not set, indicates the encoding MIME Type Length in bytes.
  * **Metadata Encoding MIME Type**: MIME Type for encoding of Metadata. This SHOULD be a US-ASCII string that includes the [Internet media type](https://en.wikipedia.org/wiki/Internet_media_type) specified in [RFC 2045][rf].  Many are registered with [IANA][ia] and others such as [Routing][r] and [Tracing (Zipkin)][tz] are not.  [Suffix][s] rules MAY be used for handling layout.  The string MUST NOT be null terminated.  (Not present if M flag is set)
  * **Metadata Length**: (24 bits = max value 16,777,215) Unsigned 24-bit integer of Metadata Length in bytes.
  * **Metadata Payload**: User configured metadata encoded as defined by the Metadata Encoding MIME Type.

[ia]: https://www.iana.org/assignments/media-types/media-types.xhtml
[r]:  Routing.md
[rf]: https://tools.ietf.org/html/rfc2045
[s]:  http://www.iana.org/assignments/media-type-structured-suffix/media-type-structured-suffix.xml
[tz]: Tracing-Zipkin.md
[wk]: Well-Known-MIME-Types.md
