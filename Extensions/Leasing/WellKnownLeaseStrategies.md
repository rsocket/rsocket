# Well-known Lease Strategies

## Introduction
TODO

## Mappings
All well-known Lease Types assume UTF-8 character encoding wherever a character set might be necessary.  If another character set is required, a string-based Lease Type should be used.

| Lease Type                                 | Identifier
| -------------------------------------------| ----------
| [`Requests Count`][request-leasing]        | `0x00`
| [`Concurrency Limit`][concurrency-leasing] | `0x01`
| [`Frames Count`][frames-leasing]           | `0x02`

[request-leasing]: ../../Protocol.md#frame-lease
[concurrency-leasing]: ConcurrencyLimitLeasing.md
[frames-leasing]: FramesCountLeasing.md