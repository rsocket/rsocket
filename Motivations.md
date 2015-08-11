## Motivations

#### Transport Layer Flexibility

Support multiple transport protocols (HTTP/2, WebSockets, TCP, Aeron, QUIC, etc) with a single application protocol to allow swapping based on environment, device capabilities and performance needs. 
Support WebSockets which needs an application protocol.
Support TCP which needs an application protocol.

#### Performance

Allow persistent connections to reduce user latency by eliminating round-trip cost of handshakes (such as SSL/TLS) for each request/response.

Use binary encoding to reduce computation and byte size.

#### Interaction Models

Support the following interaction models:
- request/response (single-response)
- request/stream (multi-response, finite)
- fire-and-forget
- topic subscription (multi-response, infinite)

Support bi-directional requests. Both client and server can act as requestor or responder. This allows a client (such as a user device) to act as a responder to requests from the server. 

#### Flow Control

Control flow of emission from responder to requestor using Reactive Stream semantics at the application level. This enables use of bounded buffers so rate of flow adjusts to consumption.
Optional support to control flow of requests from requestor to responder using leasing strategy. This enables client-side load balancing for sending messages only to servers that have signalled capacity. 

