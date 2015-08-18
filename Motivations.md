## Motivations

Large distributed systems are often implemented in a modular fashion by different teams using a variety of technologies and programming languages. The pieces need to talk to one another reliably and need to be updated seamlessly over time as bugs are fixed and new features delivered. Effective and scalable communication between modules is a crucial concern in distributed systems. It significantly affects how much latency users experience and the amount of resources required to build and run the system. Defining a formal communication protocol is a unique opportunity that allows for improvements in both these key areas. 

##### User Experience
A protocol that uses network resources inefficiently (repeated handshakes and connection setup and tear down overhead, bloated message format,  etc) can greatly increase the perceived latency of a system. Also without flow control semantics, a single poorly written module can overrun the rest of the system when dependent services slow down potentially causing retry storms that put further pressure on the system (some link to something that talks about that in more detail maybe https://github.com/Netflix/Hystrix/wiki#problem).

ReactiveSocket helps reduce latency by:
   - eliminating round-trip cost of handshakes (such as SSL/TLS) for each request/response over persistent connections.
   - reducing computation time by using binary encoding
   - allocating less memory and reducing garbage collection cost

ReactiveSocket supports optional flow control semantics to help protect server resources from being overwhelmed:
- When enabled, the flow control features of the protocol can control the flow of requests from requestor to responder using a leasing strategy. This enables client-side load balancing for sending messages only to servers that have signalled capacity. 
- Control flow of emission from responder to requestor using Reactive Stream semantics at the application level. This enables use of bounded buffers so rate of flow adjusts to application consumption and not rely solely on transport and network buffering.


A simple flow control scenario would be fantastic here I think.

##### Scalability & Performance
At runtime, a poorly chosen communication protocol wastes server resources (CPU, memory, network bandwidth). While that may be acceptable for smaller deployments, large systems with hundreds or thousands of nodes multiply the somewhat small inefficiencies into noticeable excess. Running with a huge footprint leaves less room for expansion as server resources are relatively cheap but not infinite. Managing giant clusters is much more expensive and less nimble even with good tools.

ReactiveSocket can help reduce hardware footprint (and thus cost and operational complexity) by:
   - increasing CPU efficiency
   - increasing memory efficiency
   - using binary encoding to reduce computation and byte size
   - allowing persistent connections

#### Interaction Models
An inappropriate protocol increases the costs of developing a system. It can be a leaky abstraction that forces the design of the system into the mold it allows. Then developers spend extra time working around its shortcomings to handle errors and achieve acceptable performance. In a polyglot environment this problem is amplified as different languages will use different approaches to solve this problem and requires extra coordination among teams to do so. To date the defacto standard is HTTP and everything is a request / response. In some cases this might not be the ideal communication model for a given feature.

ReactiveSocket is not limited to just one interaction model. The various supported interaction models described below open up powerful new possibilities for system design:

  - Request/Response (single-response)
    * Standard request / response semantics are still supported
  - Request/Stream (multi-response, finite) to support collection/stream based responses.
    * This is where you put a small example of where this would be helpful
  - Fire-and-Forget to support efficient, lossy messaging. 
    * This is where you put a small example of where this would be helpful
  - Topic subscription (multi-response, infinite) to enable push notifications and event stream processing.
    * This is where you put a small example of where this would be helpful
 
Consider the following uses of 
- Support bi-directional requests where both client and server can act as requestor or responder. This allows a client (such as a user device) to act as a responder to requests from the server. 
    * For example, a server could query clients for debug information, state, etc. 
    * This is a good start for an example but could be more helpful. What does this interaction look like? 
- Servers can ask for more work when needed instead of having millions/billions of clients constantly submitting data that may only occasionally be needed.
    * Some example of where clients typically repeatedly submit data that's only occasionally needed goes here
- Support cancellation of any request to allow efficient cleanup of server (responder) resources.
    * This needs an example also
- This also opens up future interaction models currently not envisioned between client and server without restricting use of legacy client/server models and enabling peer-to-peer interactions.



#### Transport Layer Flexibility
Some short treatment of application protocol vs transport protocol would be appropriate here.

As a protocol, ReactiveSocket allows for swapping of the underlying transport layer based on environment, device capabilities and performance needs. ReactiveSocket (the application protocol) can use any of several supported transport protocols (HTTP/2, WebSockets, TCP, Aeron, QUIC, etc).
Here are some typical scenarios:
- ReactiveSocket over WebSockets which needs an application protocol.
- ReactiveSocket over TCP which needs an application protocol.
- ReactiveSocket over HTTP/2 which needs a mapping of application behavior to the HTTP semantics.


## Comparisons
HTTP isn't the only protocol out there. Some work has been done to address the weaknesses of HTTP as well (HTTP 2 and Websockets). ReactiveSocket still compares favorably to many protocols: (I dont particularly like this intro but I'm running out of steam at the moment)

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
