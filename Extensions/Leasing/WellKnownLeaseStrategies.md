# Well-known Lease Strategies

## Introduction
The [Lease Strategy Extension][le] provides a standardized mechanism for negotiating Lease Strategy in the [Setup Frame][sf] metadata payload. Lease Strategies define how to read the Lease Strategies Metadata Payload. However, due to their definitions as strings and the number of times they need to be sent as part of typical interaction, they can be wasteful in their typical form.  Because of this, it's useful to represent well-known Lease Strategies as integer values during transmission.  This behavior does not remove the need or ability in the specifications to declare Lease Strategies as strings.

[le]: Leasing.md
[sf]: ../../Protocol.md#frame-setup

## Mappings
All well-known Lease Strategies assume UTF-8 character encoding wherever a character set might be necessary.  If another character set is required, a string-based Lease Type should be used.

| Lease Strategy                             | Identifier
| -------------------------------------------| ----------
| [`Requests Count`][request-leasing]        | `0x00`
| [`Concurrency Limit`][concurrency-leasing] | `0x01`
| [`Frames Count`][frames-leasing]           | `0x02`

[request-leasing]: ../../Protocol.md#frame-lease
[concurrency-leasing]: ConcurrencyLimitLeasing.md
[frames-leasing]: FramesCountLeasing.md