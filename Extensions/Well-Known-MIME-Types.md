# Well-known MIME Types

## Introduction
MIME types are an integral part of the RSocket and Extension specifications.  However, due to their definitions as strings and the number of times they need to be sent as part of typical interaction, they can be wasteful in their typical form.  Because of this, it's useful to represent well-known MIME types as integer values during transmission.  This behavior does not remove the need or ability in the specifications to declare MIME types as strings.

## Mappings
All well-known MIME types assume UTF-8 character encoding wherever a character set might be necessary.  If another character set is required, a string-based MIME type should be used.

| MIME Type | Identifier
| --------- | ----------
| `application/avro` | `0`
| `application/cbor` | `1`
| `application/graphql` | `2`
| `application/gzip` | `3`
| `application/javascript` | `4`
| `application/json` | `5`
| `application/octet-stream` | `6`
| `application/pdf` | `7`
| `application/vnd.apache.thrift.binary` | `8`
| `application/vnd.google.protobuf` | `9`
| `application/xml` | `10`
| `application/zip` | `11`
| `audio/aac` | `12`
| `audio/mp3` | `13`
| `audio/mp4` | `14`
| `audio/mpeg3` | `15`
| `audio/mpeg` | `16`
| `audio/ogg` | `17`
| `audio/opus` | `18`
| `audio/vorbis` | `19`
| `image/bmp` | `20`
| `image/gif` | `21`
| `image/heic-sequence` | `22`
| `image/heic` | `23`
| `image/heif-sequence` | `24`
| `image/heif` | `25`
| `image/jpeg` | `26`
| `image/png` | `27`
| `image/tiff` | `28`
| `multipart/mixed` | `29`
| `text/css` | `30`
| `text/csv` | `31`
| `text/html` | `32`
| `text/plain` | `33`
| `text/xml` | `34`
| `video/H264` | `35`
| `video/H265` | `36`
| `video/VP8` | `37`
