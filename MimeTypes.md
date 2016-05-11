## Mime types

A [Setup Frame](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md#setup-frame) in the ReactiveSocket protocol specifies mime types for both [data and metadata](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md#data-and-metadata) payloads of a frame.
This document provides a guidance for the mime types of these payloads.

#### Metadata

Reactive Socket provides a default mime type for metadata payloads and all implementations of the protocol MUST use this default, unless overridden by the user.

##### Overview

The default mime type assumes key-value metadata fields with the following encodings:

* __Key__   : The value is always a UTF-8 string.
* __Value__ : Value is an opaque binary value and the encoding can vary from one field to another.

##### Name

The name of the default mime type for metadata payloads is __application/x.reactivesocket+cbor__.
This name MUST be mentioned in the [SETUP frame](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md#setup-frame) as the mime type for metadata.

##### Format

[CBOR](http://cbor.io/) is used as the data format for encoding this key-value metadata.
According to the CBOR specification [section 2.1](https://tools.ietf.org/html/rfc7049#section-2.1) this data will be of the following form:
```
Indefinite length map (CBOR Major Type 5)
   UTF-8 definite length key.
   definite length binary string. (CBOR Major Type 2)
```

#### Data

Reactive Socket does not provide any default mime type for the data payload. Applications must pass an appropriate data payload mime type in the setup frame as specified by the protocol.
