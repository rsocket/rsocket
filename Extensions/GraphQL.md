# GraphQL Extension Spec

_This extension specification is currently incubating.  While incubating the version is 0._

## Introduction

GraphQL protocol is one of the popular API protocol for building modern edge-network communication. This extension specification provides an interoperable structure for metadadata payloads and sub-specification which defines graphql communication over RSocket protocol.

## Handling GraphQL operation

A GraphQL operation can be handled if it is agreed during the RSocket `SETUP` phase and specified in the data-mime type `application/graphql` or if composite metadata enabled, specified in the REQUEST PAYLOAD data mime-type `application/graphql` via [Stream Data MIME Types Metadata Extension](/PerStreamDataMimeTypesDefinition.md).

GraphQL operation can be requested via `REQUEST_RESPONSE` and `REQUEST_STREAM` requests of RSocket Protocol.

> Note: +type semantic may specify graphQL message encoding if needed (e.g. `application/graphql+cbor`). By default it is JSON encoding.

### Single result operation

To handle `query` or `mutation` GraphQL operation a `REQUESTER` MUST issue a `REQUEST_RESPONSE` payload.

GraphQL operation lifecycle is bound to the RSocket REQUEST RESPONSE operation semantic and must follow it as specified by RSocket protocol.

### Streaming operation
To handle `subscription` GraphQL operation a `REQUESTER` MUST issue a `REQUEST_STREAM` payload.

Streaming operation lifecycle is bound to the RSocket REQUEST STREAM operation semantic and must follow it as specified by RSocket protocol.

### Handling Graphql errors

GraphQL errors must be encoded as a normal RSocket `PAYLOAD` with `NEXT` semantic followed by `PAYLOAD` with `COMPLETE` flag (onNext(ERROR_MESSAGE) -> onComplete()). RSocket Protocol `ERROR` must be treated as unexpected interruption of the subscription and MUST not contain any GraphQL data in the payload.


### Handling unexpected

1. If `REQUEST_STREAM` request does not contain `subscription` GraphQL operation, such request must be rejected with an `ERROR` having `INVALID` as an error code.
2. If `REQUEST_RESPONSE` request does not contain `query` or `mutation` GraphQL operation, such request must be rejected with an `ERROR` having `INVALID` as an error code.
3. Hand
