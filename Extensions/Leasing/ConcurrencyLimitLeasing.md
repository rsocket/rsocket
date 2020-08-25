# Max Concurrency Limit Leasing Strategy Extension

_This extension specification is currently incubating.  While incubating the version is 0._

## Introduction
TODO


### Frame Contents
```
     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |                         Stream ID = 0                         |
    +-----------+-+-+---------------+-------------------------------+
    |Frame Type |0|M|     Flags     |
    +-----------+-+-+---------------+-------------------------------+
    |0|                       Time-To-Live                          |
    +---------------------------------------------------------------+
    |0|                     Concurrency Limit                       |
    +---------------------------------------------------------------+
                                Metadata
```

* __Frame Type__: (6 bits) 0x02 
* __Flags__: (10 bits)
     * (__M__)etadata: Metadata present
* __Time-To-Live (TTL)__: (31 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit integer of Time (in milliseconds) for validity of LEASE from time of reception. Value MUST be > 0.
* __Concurrency Limit__: (63 bits = max value 2^31-1 = 2,147,483,647) Unsigned 31-bit long of Number of Max Concurrent Requests at a time. Value MUST be >= 0. 

A Responder implementation MAY stop all further requests by sending a LEASE with a value of 0 for __Concurrency Limit__.

When a LEASE expires due to time, the value of the __Concurrency Limit__ that a Requester may make is implicitly 0.

This frame only supports Metadata, so the Metadata Length header MUST NOT be included, even if the (M)etadata flag is set true.

[wk]: WellKnownLeaseStrategies.md