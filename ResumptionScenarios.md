# Resumption Scenarios

This [protocol](./protocol.md) addition, shows possible resumption scenarios to ensure that the protocol is understood properly and an implementer may see all posible scenarios which

```
Client                                                                                           | Server 
1                                                                                                |
2                                                                                                |
3  -> SETUP(ResumeFlag(1))                                                                       |
4                                                                                                | -> SETUP
5  -> REQUEST_STREAM  (StreamID(1)) // RPosition(0) Position(1) IPosition(0)                     |
6                                                                                                | -> REQUEST_STREAM  (Resume(1) StreamID(1)) // RPosition(0) Position(0) IPosition(1)
7                                                                                                | <- PAYLOAD         (Resume(1) StreamID(1)) // RPosition(0) Position(1) IPosition(1)
8  -> REQUEST_CHANNEL (StreamID(3)) // RPosition(0) Position(1) IPosition(0)                     |
9                                                                                                | <- PAYLOAD         (Resume(1) StreamID(1)) // RPosition(0) Position(2) IPosition(1)
10                                                                                               | -> REQUEST_CHANNEL (Resume(0) StreamID(3)) // RPosition(0) Position(0) IPosition(1)
11                                                                                               | <- PAYLOAD         (Resume(1) StreamID(3)) // RPosition(0) Position(1) IPosition(1)
12                                                                                               | <- REQUEST(N)      (Resume(0) StreamID(3)) // RPosition(0) Position(2) IPosition(1)
13 <- PAYLOAD         (StreamID(1)) // RPosition(0) Position(1) IPosition(1)                     |
14 -> KEEPALIVE       (NoE(1), { StreamID(1) : 1})                                               |
15                                                                                               | -> KEEPALIVE       (NoE(1), { StreamID(1) : 1 })
16                                                                                               | <- KEEPALIVE       (NoE(2), { StreamID(1) : 1, StreamID(3) : 1 })
17 <- KEEPALIVE       (NoE(2), { StreamID(1) : 1, StreamID(3) : 1 })                             | 
18 <- PAYLOAD         (Resume(1) StreamID(3)) // RPosition(1) Position(1) IPosition(1)           |  
19 <- REQUEST(N)      (Resume(0) StreamID(3)) // RPosition(1) Position(1) IPosition(2)           |  
20 -> REQUEST_STREAM  (StreamID(5)) // RPosition(0) Position(1) IPosition(0)                     |
21~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~DISCON|
22                                                                                               | <- PAYLOAD         (Resume(0) StreamID(1)) // RPosition(1) Position(3) IPosition(1)
23                                                                                               | <- REQUEST_RESPONSE(Resume(0) StreamID(2)) // RPosition(0) Position(1) IPosition(0)
24                                                                                               |NECTION~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
25                                                                                               ⍭ <~ PAYLOAD         (Resume(0) StreamID(1)) // RPosition(1) Position(4) IPosition(1)
26 ~> PAYLOAD         (Resume(0) StreamID(3)) // RPosition(1) Position(2) IPosition(2)           ⍭
27 ~> PAYLOAD         (Resume(0) StreamID(3)) // RPosition(1) Position(3) IPosition(2)           ⍭
28------------------------------------------------------------------------------------------RECONNECTION----------------------------------------------------------------------------------
29 -> RESUME          (NoE(2), { StreamID(1) : 1, StreamID(3) : 2 })                             |
30                                                                                               | -> RESUME          (NoE(2), { StreamID(1) : 1, StreamID(3) : 2 })          
31                                                                                               | <- RESUME_OK       (NoE(2), { StreamID(1) : 1, StreamID(3) : 1 })
32                                                                                               | <- REDELIVER 3 FRAMES          
33 <- RESUME_OK       (NoE(2), { StreamID(1) : 1, StreamID(3) : 2 })                             |
33 <- RESUME_OK       (NoE(2), { StreamID(1) : 1, StreamID(3) : 2 })                             |
34 -> REDELIVER 3 FRAMES                                                                         |
35 <- PAYLOAD         (Resume(0) StreamID(1)) // RPosition(1) Position(1) IPosition(2)           |
36 <- PAYLOAD         (Resume(0) StreamID(1)) // RPosition(1) Position(1) IPosition(3)           |
37                                                                                               | -> PAYLOAD         (Resume(0) StreamID(3)) // RPosition(2) Position(2) IPosition(2)           
38                                                                                               | -> REQUEST_STREAM  (Resume(0) StreamID(5)) // RPosition(0) Position(0) IPosition(1)           
39                                                                                               | -> PAYLOAD         (Resume(0) StreamID(5)) // RPosition(2) Position(2) IPosition(3)           
```

according to the above sequence we can describe it as the following:
<pre>
<code>
[<span style="color:red"><b>Line  3</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(0)] sends Setup with Resumability enabled
[<span style="color:red"><b>Line  4</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(0)] receives Setup and accept it
[<span style="color:red"><b>Line  5</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(1)] sends RequestStream. Since resumability is enabled we assume possibility to have it enabled for that stream as well. Increase (P)osition to 1. Other positions are not changed.
[<span style="color:red"><b>Line  6</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(1)] receives RequestStream and decides to enable resumability for that stream. (I)mplied Position is increased to 1. Other positions are not changed.
[<span style="color:red"><b>Line  7</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(1)] sends Payload with (R)esume flag set. (P)osition is increased to 1. Other positions are not changed.
[<span style="color:red"><b>Line  8</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(3)] sends RequestChannel. Since resumability is enabled we assume possibility to have it enabled for that stream as well. Increase (P)osition to 1. Other positions are not changed.
[<span style="color:red"><b>Line  9</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(1)] sends Payload. (P)osition is increased to 2. Other positions are not changed.
[<span style="color:red"><b>Line 10</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(3)] receives RequestChannel and decides to enable resumability for that stream. (I)mplied Position is increased to 1. Other positions are not changed.
[<span style="color:red"><b>Line 11</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(3)] sends Payload with (R)esume flag set. (P)osition is increased to 1. Other positions are not changed.
[<span style="color:red"><b>Line 12</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(3)] sends RequestN. (P)osition is increased to 2. Other positions are not changed.
[<span style="color:red"><b>Line 13</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(1)] receives Payload. Resume confirmed. (P)osition is increased to 2. Other positions are not changed.
[<span style="color:red"><b>Line 14</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(0)] sends KeepAlive. Number of Entries is 1.
                 [StreamID(1)] includes (I)mpliedPosition equal to 1.
[<span style="color:red"><b>Line 15</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(0)] receives KeepAlive.
                 [StreamID(1)] releases 1 frame from the Queue. (R)etained Position is increased to 1.
[<span style="color:red"><b>Line 16</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(0)] sends KeepAlive.
                 [StreamID(1)] includes (I)mpliedPosition equal to 1.
                 [StreamID(3)] includes (I)mpliedPosition equal to 1.
[<span style="color:red"><b>Line 17</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(0)] receives KeepAlive.
                 [StreamID(1)] releases 1 frame from the Queue. (R)etained Position is increased to 1.
                 [StreamID(3)] resume confirmed. Releases 1 frame from the Queue. (R)etained Position is increased to 1.
[<span style="color:red"><b>Line 18</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(3)] receives Payload. (I)mplied Position is increased to 1. Other positions are not changed. Note, frame was reordered which is acceptable.
[<span style="color:red"><b>Line 19</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(3)] receives RequestN. (I)mplied Position is increased to 2. Other positions are not changed. Note, frame was reordered which is acceptable but is in order with other frames with the same StreamID.
[<span style="color:red"><b>Line 20</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(5)] sends RequestStream. Since resumability is enabled we assume possibility to have it enabled for that stream as well. Increase (P)osition to 1. Other positions are not changed.
[<span style="color:red"><b>Line 21</b></span>][<span style="color:green"><i>Client</i></span>]              losts connection.
[<span style="color:red"><b>Line 22</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(1)] sends Payload. (P)osition is increased to 3. Other positions are not changed.
[<span style="color:red"><b>Line 23</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(2)] sends RequestStream. Since resumability is enabled we assume possibility to have it enabled for that stream as well. Increase (P)osition to 1. Other positions are not changed.
[<span style="color:red"><b>Line 24</b></span>][<span style="color:blue"><i>Server</i></span>]              losts connection.
[<span style="color:red"><b>Line 25</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(1)] enqueues Payload. (P)osition is increased to 4. Other positions are not changed.
[<span style="color:red"><b>Line 26</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(3)] enqueues Payload. (P)osition is increased to 2. Other positions are not changed.
[<span style="color:red"><b>Line 27</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(3)] enqueues Payload. (P)osition is increased to 3. Other positions are not changed.
[<span style="color:red"><b>Line 28</b></span>]                      reestablished connection.
[<span style="color:red"><b>Line 29</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(0)] sends Resume.
                 [StreamID(1)] includes (I)mpliedPosition equal to 1.
                 [StreamID(3)] includes (I)mpliedPosition equal to 2.
                 [StreamID(5)] includes (I)mpliedPosition equal to 0.
[<span style="color:red"><b>Line 30</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(0)] receives Resume.
                 [StreamID(1)] no operations are performed since (I)mplied Position is equal to (R)etained Position.
                 [StreamID(2)] rejects since Client has not received that request.
                 [StreamID(3)] releases 1 frame from the Queue. (R)etained Position is increased to 2.
                 [StreamID(5)] no operation performed since stream is unknown
[<span style="color:red"><b>Line 31</b></span>][<span style="color:blue"><i>Server</i></span>][StreamID(0)] sends ResumeOk.
                 [StreamID(1)] includes (I)mpliedPosition equal to 1.
                 [StreamID(3)] includes (I)mpliedPosition equal to 1.
[<span style="color:red"><b>Line 32</b></span>][<span style="color:blue"><i>Server</i></span>]              retransmits undelivered frames.
                 [StreamID(1)] sends Payload at (P)osition 2 (was sent at Line 9)
                 [StreamID(1)] sends Payload at (P)osition 3 (was sent at Line 22)
                 [StreamID(1)] sends Payload at (P)osition 4 (was equeued at Line 25)
[<span style="color:red"><b>Line 33</b></span>][<span style="color:green"><i>Client</i></span>][StreamID(0)] receives ResumeOk.
                 [StreamID(1)] no operations are performed since (I)mplied Position is equal to (R)etained Position.
                 [StreamID(3)] no operations are performed since (I)mplied Position is equal to (R)etained Position.
[<span style="color:red"><b>Line 32</b></span>][<span style="color:blue"><i>Server</i></span>]               retransmits undelivered frames.
                 [StreamID(3)] sends Payload at (P)osition 2. (was enqueued at Line 26)
                 [StreamID(3)] sends Payload at (P)osition 3. (was enqueued at Line 27)
                 [StreamID(5)] sends RequestStream. No positions are changed. (was sent at Line 20)
</code>
</pre>