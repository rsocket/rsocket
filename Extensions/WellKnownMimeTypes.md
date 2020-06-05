# Well-known MIME Types

## Introduction
MIME types are an integral part of the RSocket and Extension specifications.  However, due to their definitions as strings and the number of times they need to be sent as part of typical interaction, they can be wasteful in their typical form.  Because of this, it's useful to represent well-known MIME types as integer values during transmission.  This behavior does not remove the need or ability in the specifications to declare MIME types as strings.

## Mappings
All well-known MIME types assume UTF-8 character encoding wherever a character set might be necessary.  If another character set is required, a string-based MIME type should be used.

| MIME Type | Identifier
| --------- | ----------
| `application/avro` | `0x00`
| `application/cbor` | `0x01`
| `application/graphql` | `0x02`
| `application/gzip` | `0x03`
| `application/javascript` | `0x04`
| `application/json` | `0x05`
| `application/octet-stream` | `0x06`
| `application/pdf` | `0x07`
| `application/vnd.apache.thrift.binary` | `0x08`
| `application/vnd.google.protobuf` | `0x09`
| `application/xml` | `0x0A`
| `application/zip` | `0x0B`
| `audio/aac` | `0x0C`
| `audio/mp3` | `0x0D`
| `audio/mp4` | `0x0E`
| `audio/mpeg3` | `0x0F`
| `audio/mpeg` | `0x10`
| `audio/ogg` | `0x11`
| `audio/opus` | `0x12`
| `audio/vorbis` | `0x13`
| `image/bmp` | `0x14`
| `image/gif` | `0x15`
| `image/heic-sequence` | `0x16`
| `image/heic` | `0x17`
| `image/heif-sequence` | `0x18`
| `image/heif` | `0x19`
| `image/jpeg` | `0x1A`
| `image/png` | `0x1B`
| `image/tiff` | `0x1C`
| `multipart/mixed` | `0x1D`
| `text/css` | `0x1E`
| `text/csv` | `0x1F`
| `text/html` | `0x20`
| `text/plain` | `0x21`
| `text/xml` | `0x22`
| `video/H264` | `0x23`
| `video/H265` | `0x24`
| `video/VP8` | `0x25`
| `application/x-hessian` | `0x26`
| `application/x-java-object` | `0x27`
| `application/cloudevents+json` | `0x28`
| |
| `message/x.rsocket.mime-type.v0` | `0x7A`
| `message/x.rsocket.accept-mime-types.v0` | `0x7b`
| `message/x.rsocket.authentication.v0` | `0x7C`
| `message/x.rsocket.tracing-zipkin.v0` | `0x7D`
| `message/x.rsocket.routing.v0` | `0x7E`
| `message/x.rsocket.composite-metadata.v0` | `0x7F`
