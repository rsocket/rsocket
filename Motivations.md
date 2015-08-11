## Motivations

Reduce perceived latency and increase system efficiency by supporting non-blocking, duplex, async application communication with flow control over multiple transports from any language.

## Why?

#### Scalability & Performance

- Reduce hardware footprint (and thus cost and operational complexity) by:
   - increasing CPU efficiency
   - increasing memory efficiency
   - using binary encoding to reduce computation and byte size
   - allowing persistent connections

- Reduce perceived user latency by:
   - eliminating round-trip cost of handshakes (such as SSL/TLS) for each request/response over persistent connections.
   - reducing computation time by using binary encoding
   - allocating less memory and reducing garbage collection cost

#### Interaction Models

- Support the following interaction models:
  - Request/Response (single-response)
  - Request/Stream (multi-response, finite) to support collection/stream based responses.
  - Fire-and-Forget to support efficient, lossy messaging. 
  - Topic subscription (multi-response, infinite) to enable push notifications and event stream processing.

- Support bi-directional requests where both client and server can act as requestor or responder. This allows a client (such as a user device) to act as a responder to requests from the server. 
  - For example, a server could query clients for trace debug information, state, etc. 
  - This future proofs infrastructure for scalability to allow server-side to query when needed instead of having millions/billions of clients constantly submitting data that may only occasionally be needed.
  - This also opens up future interaction models currently not envisioned between client and server without restricting use of legacy client/server models and enabling peer-to-peer interactions.

- Support cancellation of any request to allow efficient cleanup of server (responder) resources.

#### Transport Layer Flexibility

- Allow swapping transport layer based on environment, device capabilities and performance needs by supporting multiple transport protocols (HTTP/2, WebSockets, TCP, Aeron, QUIC, etc) with a single application protocol. 
- Allow use of WebSockets which needs an application protocol.
- Allow use of TCP which needs an application protocol.
- Allow use of HTTP/2 which needs a mapping of application behavior to the HTTP semantics.
- Allow interchangeable use of HTTP/1, HTTP/2, WebSockets, TCP (and other duplex transports) with same application behavior.

#### Flow Control

- Design for the data center where a client communicates with many servers via optional support to control flow of requests from requestor to responder using leasing strategy. This enables client-side load balancing for sending messages only to servers that have signalled capacity. 
- Control flow of emission from responder to requestor using Reactive Stream semantics at the application level. This enables use of bounded buffers so rate of flow adjusts to application consumption and not rely solely on transport and network buffering.

