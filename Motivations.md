## Motivations

- Define application layer semantics usable over multiple network transports. 
- Reduce perceived latency and increase system efficiency by supporting non-blocking, duplex, async application communication with flow control over multiple transports from any language.
- Improve polyglot interaction through formal network protocol.

#### Scalability & Performance

- Reduce hardware footprint (and thus cost and operational complexity) by:
   - increasing CPU efficiency
   - increasing memory efficiency
   - using binary encoding to reduce computation and byte size
   - allowing persistent connections

- Reduce perceived user latency by:
   - avoiding handshakes and the associated round-trip network overhead
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

- Design for the data center where a client communicates with many servers via optional support to control flow of requests from requestor to responder using leasing strategy. This enables application level client-side load balancing for sending messages only to servers that have signalled capacity. 
- Control flow of emission from responder to requestor using Reactive Stream semantics at the application level. This enables use of bounded buffers so rate of flow adjusts to application consumption and not rely solely on transport and network buffering.

## Comparisons

- ReactiveSocket is an OSI Layer 5/6, or TCP/IP Application Layer protocol. 
- It is intended for use over duplex, binary transport protocols.

#### TCP & QUIC

- No framing or application semantics. Must provide a protocol.

#### WebSockets

- No application semantics, just framing. Must provide a protocol.

#### HTTP/1 & HTTP/2

- Provides transport mechanisms equivalent to ReactiveSocket Schema (URI, errors, metadata). 
- HTTP itself is insufficient in defining application semantics. ([GRPC from Google](https://github.com/grpc/grpc-common/blob/master/PROTOCOL-HTTP2.md) is an example of a protocol being built on top of HTTP/2 to add these type of semantics)
- Limited application semantics. Requires application protocol to define:
  - Use of GET, POST or PUT for request
  - Use of Normal, Chunked or SSE for response
  - MimeType of payload
  - error messaging along with standard status codes
  - how client should behave with status codes
  - Use of SSE as persistent channel from server to client to allow server to make requests to client
- No defined mechanism for flow control from responder (typically server) to requestor (typically client)
- No defined mechanism for communicating requestor (typically server) availability other than failing a request (503)
- No fire-and-forget.
- REST alone is insufficient and inappropriate for defining application semantics.

In other words, HTTP provides barely sufficient raw capabilities for application protocols to be built with, but an application protocol still needs to be defined on top of it.

#### MQTT, AMQP, ZMTP

- Limited or no application semantics, just messaging. Must provide a protocol.

#### STOMP

- No application semantics, just framing. Must provide a protocol.
- ASCII protocol, not binary.

#### Thrift

- Coupled with encoding, RPC, etc
- Synchronous request/response, no multiplexing
