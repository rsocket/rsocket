## Mime types

A [Setup Frame](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md#setup-frame) in the Reactive
Socket protocol specifies mime types for both [data and metadata](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md#data-and-metadata) payloads of a frame.
This document provides a guidance for the mime types of these payloads.

#### Metadata

Reactive Socket provides a default mime type for metadata payloads and all implementations of the protocol MUST use
this default, in absence of a specific mime type provided by the user.

##### Overview

The default mime type assumes key-value metadata fields with the following encodings:

* __Key__   : The value is always a UTF-8 string.
* __Value__ : Value is an opaque binary value and the encoding can vary from one field to another.

##### Name

The name of the default mime type for metadata payloads is __application/x.reactivesocket+kv__. This name MUST be
mentioned in the [SETUP frame](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md#setup-frame) as
the mime type for metadata.

##### Format

Key value pairs in the metadata are expressed as follows:

```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |R|          Key1 length        |         Value1 length         |
    +-+-------------------------------------------------------------+
    |                              Key1                            ...
    +---------------------------------------------------------------+
    |                             Value1                           ...
    +---------------------------------------------------------------+
    |R|          Key2 length        |         Value2 length         |
    +-+-------------------------------------------------------------+
    |                              Key2                            ...
    +---------------------------------------------------------------+
    |                             Value2                           ...
    +---------------------------------------------------------------+
                           Other key-value pairs
```

The above format is a chained list of one or more key value pairs, prepended by key and value lengths.
It does _not_ specify the total length of the metadata payload as that is [already specified](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md#metadata-optional-header)
before the metadata payload starts.

* __R__ bit is reserved and MUST be set to 0.
* __KeyN length__ (15 = max 32,767 bytes) Length in bytes of the key in the following key-value pair.
* __ValueN length__ (16 = max 65,535 bytes) Length in bytes of the value in the following key-value pair.

#### Data

Reactive Socket does not provide any default mime type for the data payload. Applications must pass an appropriate data
payload mime type in the setup frame as specified by the protocol.
