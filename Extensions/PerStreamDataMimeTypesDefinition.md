# Stream Data MIME Types Metadata Extension

## Introduction
The definition of the `Payload` data MIME type is an integral part of the RSocket and Extension specifications. However, due to its definition as per connection, it is non-trivial to make it suitable for the cases where each stream can have different MIME types within a single connection. Therefore, this extension specification provides an interoperable structure for metadata payloads to contain data MIME types' information. It is designed such that both Requester can define using (CompositeMetadata)[cm] expected request `Payload` data MIME type and a set of accepted for the response `Payload` data MIME types as well as Responder can define in the response `Payload` data MIME Type using (CompositeMetadata)[cm]. If the data MIME type is not declared, then the MIME Type defined by `ConnectionSetupPayload` MUST be used instead. As per definition, the declaration of accepted data MIME types is on the Requester and may be considered to use by the Responder in order to encode the response data. Declaration of the accepted data MIME types by the Responder MUST be considered invalid and ignored by the Requester.


## Metadata Payload for data MIME Type
This metadata type is intended to be used per stream, and not per connection nor individual payloads and as such it **MUST** only be used in frame types used to initiate interactions.  This includes [`REQUEST_FNF`][rf], [`REQUEST_RESPONSE`][rr], [`REQUEST_STREAM`][rs], and [`REQUEST_CHANNEL`][rc].  Multiple metadata payloads with the same MIME type are allowed.  The order of metadata payloads MUST be preserved when presented to responders.  The [`SETUP` Frame][s] Metadata MIME Type is `message/x.rsocket.mime-type.v0`.

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
    +---------------+-----------------------------------------------+
```
* (**M**)etadata Type: Metadata type is a well known value represented by a unique integer.
* **MIME ID/Length**: (7 bits = max value 2^7 = 128) Unsigned 7-bit integer.  If M flag is set, indicates a [Well-known MIME Type ID][wk].  If M flag is not set, indicates the encoding MIME Type Length in bytes.
* **Metadata Encoding MIME Type**: MIME Type for encoding of Metadata. This SHOULD be a US-ASCII string that includes the [Internet media type](https://en.wikipedia.org/wiki/Internet_media_type) specified in [RFC 2045][rf].  Many are registered with [IANA][ia] and others such as [Routing][r] and [Tracing (Zipkin)][tz] are not.  [Suffix][s] rules MAY be used for handling layout.  The string MUST NOT be null terminated.  (Not present if M flag is set)


## Metadata Payload for accepted data MIME Types
This metadata type is intended to be used per stream, and not per connection nor individual payloads and as such it **MUST** only be used in frame types used to initiate interactions.  This includes [`REQUEST_FNF`][rf], [`REQUEST_RESPONSE`][rr], [`REQUEST_STREAM`][rs], and [`REQUEST_CHANNEL`][rc].  Multiple metadata payloads with the same MIME type are allowed.  The order of metadata payloads MUST be preserved when presented to responders.  The [`SETUP` Frame][s] Metadata MIME Type is `message/x.rsocket.accept-mime-types.v0`.

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
    +---------------+-----------------------------------------------+
    |M| MIME ID/Len |   Metadata Encoding MIME Type                ...
    +---------------+-----------------------------------------------+
                                   ...
```
* (**M**)etadata Type: Metadata type is a well known value represented by a unique integer.
* **MIME ID/Length**: (7 bits = max value 2^7 = 128) Unsigned 7-bit integer.  If M flag is set, indicates a [Well-known MIME Type ID][wk].  If M flag is not set, indicates the encoding MIME Type Length in bytes.
* **Metadata Encoding MIME Type**: MIME Type for encoding of Metadata. This SHOULD be a US-ASCII string that includes the [Internet media type](https://en.wikipedia.org/wiki/Internet_media_type) specified in [RFC 2045][rf].  Many are registered with [IANA][ia] and others such as [Routing][r] and [Tracing (Zipkin)][tz] are not.  [Suffix][s] rules MAY be used for handling layout.  The string MUST NOT be null terminated.  (Not present if M flag is set)



[ia]: https://www.iana.org/assignments/media-types/media-types.xhtml
[r]:  Routing.md
[rf]: https://tools.ietf.org/html/rfc2045
[s]:  http://www.iana.org/assignments/media-type-structured-suffix/media-type-structured-suffix.xml
[tz]: Tracing-Zipkin.md
[wk]: WellKnownMimeTypes.md
[cm]: CompositeMedata.md