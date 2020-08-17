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
    |0|                     Concurrency Limit                       |
    +                                                               +
    |                                                               |
    +---------------------------------------------------------------+
                                Metadata
```

* __Frame Type__: (6 bits) 0x02 
* __Flags__: (10 bits)
     * (__M__)etadata: Metadata present
* __Concurrency Limit__: (63 bits = max value 2^63-1 = 9,223,372,036,854,775,807) Unsigned 63-bit long of Number of Max Concurrent Requests at a time. Value MUST be >= 0. 

A Responder implementation MAY stop all further requests by sending a LEASE with a value of 0 for __Concurrency Limit__.

This frame only supports Metadata, so the Metadata Length header MUST NOT be included, even if the (M)etadata flag is set true.

[wk]: WellKnownLeaseStrategies.md