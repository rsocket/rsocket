# ReactiveSocket Protocol

ReactiveSocket is (being developed to be a) network protocol with client and server implementations following <a href="http://reactive-streams.org">Reactive Streams</a> semantics.

It enables the following interaction models via async message passing over a single network connection:

- request/response (stream of 1)
- request/stream (finite stream of many)
- fire-and-forget (no response)
- event subscription (infinite stream of many)

Artifacts include:

- [DesignPrinciples.md](https://github.com/ReactiveSocket/reactivesocket/blob/master/DesignPrinciples.md): Design and Architectural principles and context for the protocol and how it will be used.
- [Protocol.md](https://github.com/ReactiveSocket/reactivesocket/blob/master/Protocol.md): The protocol definition.

More information and links to various implementations can be found at http://reactivesocket.io

## Bugs and Feedback

For bugs, questions and discussions please use the [Github Issues](https://github.com/ReactiveSocket/reactivesocket/issues).

## LICENSE

Copyright 2015 Netflix, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
