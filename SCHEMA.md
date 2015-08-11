## Schema

A default schema for use with ReactiveSocket.

### Version 0 – application/x.reactivesocket.v0+xxx

#### Data

Requests must contain fields used for routing:

```
Key: uri
Value: String

Key: body
Value: Object
```

Non-request types have no specific keys, just "Object" encoded in the specificed encoding (ie. JSON, CBOR, etc)

MimeTypes for the above schema:

- application/x.reactivesocket.v0+json (schema above encoded with JSON)
- application/x.reactivesocket.v0+cbor (schema above encoded with CBOR)


#### Metadata

There is no specific schema so it is expected to use JSON, CBOR, etc as is.

- application/cbor
- application/json
- etc



