### FAQ

#### Why a new protocol? 

The full explanation of motivations can be found in [Motivations.md](https://github.com/ReactiveSocket/reactivesocket/blob/master/Motivations.md).

Some of the key reasons include:

- interaction models beyond request/response such as streaming responses and push
- application-level flow control semantics (async pull/push of bounded batch sizes) across network boundaries
- binary, multiplexed use of single connection
- need of an application protocol in order to use transport protocols such as WebSockets and [Aeron]

[Aeron]: https://github.com/real-logic/Aeron

#### Why not HTTP/2?

HTTP/2 is **much** better for browsers and request/response document transfer, but unfortunately does not expose interaction models beyond request/response, nor support application-level flow control. 

Here are some quotes from the HTTP/2 spec and FAQ that are useful to provide context on what HTTP/2 was targeting:

> “HTTP's existing semantics remain unchanged.”

> “… from the application perspective, the features of the protocol are largely unchanged …”

> "This effort was chartered to work on a revision of the wire protocol – i.e., how HTTP headers, methods, etc. are put “onto the wire”, not change HTTP’s semantics."

Additionally, "push promises" are focused on filling browser caches for standard web browsing behavior:

> “Pushed responses are always associated with an explicit request from the client.”

This means we still need SSE or WebSockets (and SSE is a text protocol so requires Base64 encoding to UTF-8) for push.

HTTP/2 was meant as a better HTTP/1.1, primarily for document retrieval in browsers for websites. We can do better than HTTP/2 for applications.

See also the ReactiveSocket [Motivations document](https://github.com/ReactiveSocket/reactivesocket/blob/master/Motivations.md).

#### Why "Reactive Streams" `request(n)` Flow Control?

Without application feedback in terms of work units done (not bytes), it is easy to cause "head of line blocking", overwhelm network and application buffers, and produce more data on the server than the client can handle. This is particularly bad when multiplexing multiple streams over a single connection where one stream can starve all others. Application layer `request(n)` semantics allows the consumer to signal how much it can receive on each stream, and allow the producer to interleave multiple streams together. 

Following are further details on some problems that can occur when using TCP and relying solely on its flow control: 

- Data is buffered by TCP on the sender and receiver side which means that understanding what is done on the subscriber is not possible.
- A sender who needs to send a large work unit (larger than the buffering on the TCP sender or receiver sides) is stuck in a scenario of poor behavior where the TCP connection will cycle between full and empty, and under-utilize the buffering drastically (as well as the throughput).
- TCP handles a single sender/receiver pair and Reactive Streams allows for multiple senders and/or multiple receivers (somewhat), and (most importantly) decoupling of data reception at the transport layer from application consumption control. I.e. an application may want to artificially slow down or limit processing separately from pulling off the data from the transport.

It all comes down to what TCP is designed to do (not overrun the receiver OS buffer space or network queues) and what Reactive Streams flow control is designed to do (allow for push/pull application work unit semantics, additional dissemination models, and application control of when it is ready for more or not). This clear separation of concerns is necessary for any real system to operate efficiently.

This illustrates why every single solution that doesn't have built-in flow control at the application level (pretty much every solution mentioned aside from MQTT, AMQP, and STOMP) is not well-suited for usage, and why ReactiveSocket incorporates application-level flow control as a first-class requirement. 

#### What about Session Continuation across connections?

Reactivesocket is not designed to provide session continuation across connections.

#### Connection Setup Requirement

This is effectively the same as the HTTP/2 requirement to exchange SETTINGS frames—see:

- <https://http2.github.io/http2-spec/#ConnectionHeader>
- <https://http2.github.io/http2-spec/#discover-http>

HTTP/2 and ReactiveSocket both require a stateful connection with an initial exchange. 

#### Transport Layer

HTTP/2 [requires TCP](https://http2.github.io/http2-spec/#starting). ReactiveSocket [requires TCP, WebSockets or Aeron](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md#terminology).

We have no intention of this running over HTTP/1.1. We also do not intend on running over HTTP/2, though that could be explored and conceptually is possible (with the use of SSE).

#### Proxying

Proxies that behave correctly for HTTP/2 will behave correctly for ReactiveSocket.

#### Frame Length

On TCP, it will be included. On Aeron or WebSockets it is not needed. 

If there is some reason to include it in Aeron or WebSockets we are fine with changing. 

#### State Spanning Connections

We determine this to be an unnecessary optimization at this protocol layer since the application has to be involved to make it work. Applications maintain state between connections. It is also very complex to implement for negligible gain. Many distributed systems implementations [fail to correctly handle these types of problems](https://aphyr.com/tags/jepsen).

#### Future-Proofing

There is no way to fully future-proof something, but we have made attempts to future-proof ReactiveSocket in the following ways:

- Frame type has a reserved value for extension
- Error code has a reserved value for extension
- Setup has a version field
- All fields have been sized according to given requirements as known currently (such as streamId supporting 4b requests)
- There is plenty of space for additional flags
- Separation of data and metadata
- Use of MimeType in Setup to eliminate coupling with encoding

Additionally, we have stuck within connection-oriented semantics of HTTP/2 and TCP so that connection behavior is not abnormal or special. 

Beyond those factors, TCP has existed since 1977. We do not expect it to be eliminated in the near future. Quic looks to be a legit alternative to TCP in the coming years. Since HTTP/2 is already working over Quic, we see no reason why ReactiveSocket will not also work over Quic. 

#### Prioritization, QoS, OOB

Prioritization, QoS, OOB is allowed with metadata, app-level logic and app control of emission.
ReactiveSocket does not enforce a queuing model, nor an emission model, nor a processing model. To be effective with QoS, it would need to control all aspects. This is not realistically possible without cooperation from the app logic as well as the underlying network layer (which would be a huge layering violation as well). It's the same reason why HTTP/2 does not go into that area either and simply provides a means to express intent. With metadata, ReactiveSocket doesn't even need to do that.

#### Why is cancellation required?

Modern distributed system topologies tend to have multiple levels of request fan-out. It means that one request on level may leads to tens of requests to multiple backends. Being able to cancel a request can save a non-trivial amount of work.

####  What are example use cases of cancellation?

Let's imagine a server responsible for computing the nth digit of Pi. A client sends a request to that server but realizes later that it doesn't want/need the response anymore (for arbitrary reasons). Rather than letting the server do the computation in vain, it can cancel it (the server may not even have started the work).

#### What are example use cases of request-stream?

Let's imagine a chat server, you want to receive all the messages said in the chat server but you don't want to poll or continuously poll (long polling technique). Another example might be we want to listen to a particular chat room and ignore all other messages.

#### What are example use cases of fire-and-forget versus request-response?

Some requests don't require a response, and when it's fine to simply ignore any failure to send them, fire-and-forget is the right solution. An example could be non-critical metrics tracking in environments where UDP is inappropriate.

#### Why Binary?

<https://http2.github.io/faq/#why-is-http2-binary>

#### Doesn't binary encoding make debugging harder?

Yes, but the tradeoff is worth it.

Binary encoding makes reading messages more difficult for humans, but it also makes reading them easier for machines. There's also a significant performance gain by not decoding the content.
Because we estimate that more than 99.99% of the messages will be read by a machine, we decided to make the reading easier for a machine.

There are extant tools for analyzing binary protocol exchanges, and new tools and extensions can readily be written to decode the binary ReactiveSocket format and present human-readable text.

#### What tooling exists for debugging the protocol?

Wireshark is the recommended tool. We don't have a plugin yet, but we plan to add one in the future.

#### Why are these different flow control approaches needed beyond what the transport layer offers?

TCP Flow Control is designed to control the rate of bytes from the sender/reader based on the consuming rate of the remote side. With ReactiveSocket, the streams are multiplexed on the same transport connection, so having flow control at the ReactiveSocket level is actually mandatory.

#### What are example use cases where ReactiveSocket flow control helps?

Flow control helps an application signal its capability to consume responses. This ensures that we never overflow any queue on the application layer.
Relying on the TCP flow control doesn't work, because we multiplex the streams on the same connection.

#### How does ReactiveSocket flow control behave?

There are two types of flow control: 

- One is provided by the request-n semantics defined in Reactive Streams (please [read the spec][Reactive Streams] for exhaustive details).
- The second is provided via the lease semantics defined in the [Protocol document](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md#lease-semantics).

#### How does ReactiveSocket benefit a client-side load balancer in a data center?

Each ReactiveSocket provides an availability number abstractly representing its capacity to send traffic.
For instance, when a client doesn't have a valid lease, it exposes a "0.0" availability indicating that it can't send any traffic. This extra piece of information, in combination with any load balancing strategy already used, give more information to the client to make smarter decisions.

#### Why is multiplexing more efficient?

- <https://http2.github.io/faq/#why-is-http2-multiplexed>
- <https://http2.github.io/faq/#why-just-one-tcp-connection>

#### Is multiplexing equivalent to pipelining?

No, pipelining requires reading the responses in the order of the requests. 

For example, with pipelining: a client sends `reqA`, `reqB`, `reqC`. It has to receive the responses in this order: `respA`, `respB`, `respC`.

With multiplexing, the same client can receive responses in any order, e.g. `respB`, `respA`, `respC`.

Pipelining can introduce [head-of-line-blocking](https://en.wikipedia.org/wiki/Head-of-line_blocking) and degrade the performance of the system.

#### Why is the "TLS False start" strategy useful for establishing a connection?

When respecting the lease semantics, establishing a ReactiveSocket between a client and a server require one round-trip (-> SETUP, <- LEASE, -> REQUEST). On slow network or when the connection latency is important, this round-trip is harmful. That's why you have the possibility to not respect the lease, and then can send your request right away (-> SETUP, -> REQUEST).

#### What are example use cases for payload data on the Setup frame?

You may want to pass data to your application at ReactiveSocket establishment, rather than reimplementing a connect protocol on top of ReactiveSocket, ReactiveSocket provides you the possibility to send information alongside the SETUP frame.
For instance, this can be used by a client to send its credentials.

#### Why multiple interaction models?

The interaction models could be reduced to just one "request-channel". Every other interaction model is a subtype of request-channel, but they have been specialized for two reasons:

- Ease of use from the client point of view.
- Performance.

#### So why the "ReactiveSocket" name? 

Isn't "Reactive" a totally [hyped](http://www.gartner.com/technology/research/methodologies/hype-cycle.jsp) buzzword? 

This library is directly related to several projects where "Reactive" is an important part of their name and architectural pattern. Thus the choice was made to retain this relationship in the name. Specifically:

- [Reactive Streams]
- [Reactive Streams IO] – proposed network protocol conforming to the Reactive Streams semantics.
- [Reactive Extensions] with [RxJava] and [RxJS] in particular.
- [Reactive Manifesto] – particularly the "message-driven" aspect.

ReactiveSocket implements, uses, or follows the principles in these projects and libraries, thus the name. 

[Reactive Streams]: http://www.reactive-streams.org
[Reactive Streams IO]: https://github.com/reactive-streams/reactive-streams-io
[Reactive Extensions]: http://www.reactivex.io
[RxJava]: https://github.com/ReactiveX/RxJava
[RxJS]: https://github.com/ReactiveX/RxJS
[Reactive Manifesto]: http://www.reactivemanifesto.org
