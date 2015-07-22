interaction model:
 - request / response
 - request / stream
 - push notification (via subscription)
 - fire and forget
 
Persitent connection, full duplex, multiplexed
Binary encoding (for the protocol itself)
Preference for zero-copy
Favor extensibility over fixed size messages
Back-pressure notification [reactive stream semantics]

Abstracted from the transport, but we are targeting:
 - websockets
 - tcp with framing
 - aeron

Need to handle:
- msg routing
- load shedding
- autoscaling
- failure recovery

Prefer stateless, but statefulness is an optimization.

Subscription assumes idempotent redundent delivery!

We are assumming polyglot libraries, we target:
- Java
- Javascript [node.js, and browser]
