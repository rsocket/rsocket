# RSocket

Routing and Forwarding Specification

### Table of Contents

- [Status](#status)
- [Terminology](#terminology)
- [Versioning Scheme](#versioning-scheme)
  - [Cross version compatibility](cross-version-compatibility)
- [Introduction](#introduction)
  - [Why a Broker](#why-a-broker)
  - [Routing using Metadata](#routing-using-metadata)
  - [RSocket Interaction Models](#rsocket-interaction-models)
  - [Clustering](#clustering)
- [Framing](#framing)
  - [Metadata](#metadata)
  - [Framing Header Format](#framing-header-format)
  - [Frame Length](#frame-length)
  - [Frame Types](#frame-types)
    - [ROUTE_SETUP](#route_setup)
    - [BROKER_INFO](#broker_info)
    - [ROUTE_JOIN](#route_join)
    - [ROUTE_REMOVE](#route_remove)
    - [ADDRESS](#address)
- [Routing Protocol Semantics](#routing-protocol-semantics)
  - [Announcements](#announcements)
  - [Routable Destinations](#routable-destinations)
  - [Brokers](#brokers)
- [Forwarding Protocol](#forwarding-protocol)
  - [Wrapping and Unwrapping Metadata in an ADDRESS](#wrapping-and-unwrapping-metadata-in-an-address)
  - [Implementation Recommendation](#implementation-recommendation)
  - [Forwarding Semantics](#forwarding-semantics)
  - [Creating List of Routable Destinations](#creating-list-of-routable-destinations)
  - [Handling Routing Flags](#handling-routing-flags)
  - [Forwarding the Request](#forwarding-the-request)
- [Well-known Keys](#well-known-keys)
  - [Well-known Types](#well-known-types)

## Status

This protocol is currently a draft for the final specifications. Current version of the protocol is
**0.1** (Major Version: 0, Minor Version: 1). This is currently considered a 1.0 Release Candidate.
Final testing is being done in Java with a goal to release 1.0 soon.

## Terminology

- Broker - forwards RSocket requests to routable destinations
- Tag – a key/value pair which determines where to route data and builds and searches
    dates in routing tables
- Metadata – a key/value pair used to represent metadata for routing and forwarding
    data. Metadata is not used for routing table information
- Routing – the mechanism for creating, maintaining, and sharing routing tables
- Forwarding – the actual forwarding of a request to a routing destination
- Routable Destination – somewhere a request can be forwarded to
- Envelope – a frame that used to wrap and forward frames between routable
    destinations
- Origin – where a request starts from
- Routing Table – a table with bitmap indices use to determine where to route requests

## Versioning Scheme

RSocket Routing and Forwarding follows a versioning scheme consisting of a numeric major
version and a numeric minor version.

#### Cross version compatibility

RSocket Routing and Forwarding spec does not assume backward compatibility between major
versions, but it is encouraged. Versions with the same major version are compatible.

## Introduction

Routing and forwarding are used to forward RSocket requests between two RSocket
connections via broker. In some cases, point-to-point interactions between a client and server
are enough, in an enterprise environment, it is useful to decouple the client and server from
each other. Some examples of why decoupling is necessary include blue/green deployments,
load balancing, A/B testing, feature toggles, etc. Additionally, providing an intermediary can
help with security and scalability. Finally, with the load balancing, routing and QoS, better
overall application latency and throughput can be achieved than by direct connections.

This describes a specification for clients to connect an intermediate broker and have their
requests forwarded using formalized metadata frames. The metadata defines how to announce
a new routable destination, and forward requests.

#### Why a Broker?

A router is a device that forwards packets between destinations. Generally, it does not provide
any transformations to a packet, but forwards it on to the next router until the packets reaches
its destination. In a contract, a broker acts as an intermediary between parties translating a
message from sender to receiver. This specification allows the intermediary to do more than
just forwarding between nodes. Instead, it leverages the message passing aspect of RSocket to
allow for multi-cast, sharding, etc. Once a suitable route is found, that route stays active for the
duration of the RSocket stream. Finally, this specification does not determine if the routable
destination is an RSocket Client or RSocket Server. Traditionally, a message broker has clients
that connect and then send messages between themselves. This specification expects
persistent connections between origin and destination like a message broker.

#### Routing vs Forwarding

_TODO – fill this out more about Routing and Forwarding_

#### Routing using Metadata

Most familiar request routing schemes use parsing strings and regex. These include HTTP URLs
and Headers to determine where to send requests. Alternatively, if they are using a queue or
message broker-based solution, they will use topic/queues names and sometimes these names
have wild-cards. This specification takes a different approach. Each RSocket that connects to a
broker provides tags that can be used to route requests. The tags are inserted into a queryable
table for fast lookup. When a requester sends a message, it includes tags. The broker uses the
request message’s tags to select candidates for forwarding the message. The tags are used like
a query in database allowing the broker to create dynamic routes. This is detailed in the
forwarding specification section.

#### RSocket Interaction Models

This specification applies to the RSocket fire and forget, request/reply, request/stream,
request/channel, and metadata push interaction models. An extension frame can support this if
the implementor of the extension frames supports a metadata field.

#### Clustering

This specification does not include a specification for clustering brokers currently. It does
include information about how brokers can exchange information to determine if they can
route requests between each other. A formal cluster definition could be added later, and the
specification does not prevent clustering being used to share information.


## Framing

#### Metadata

RSocket Routing and Forwarding Specification will create a framing envelope that will wrap
metadata. The metadata will stay enveloped until it reaches its destination. In a stream with
multiple frames sent from the producer, i.e. request/channel, the Routing and Forwarding
envelope metadata only needs to be sent on the first frame.

RSocket Routing and Forwarding protocol will use binary frames. The frames will be used in
with existing RSocket constructs and will not change the RSocket protocol to change at this
time.

The frames are for the metadata field. They may be used in conjunction with the composite
metadata field.

The frames will all share the same mime-type message/x.rsocket.forwarding

#### Framing Header Format

Routing and Forwarding frames will begin with a frame header. This is the general layout:

```
0 1 2 3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Major Version                 | Minor Version                 |
+-----------+-------------------+-------------------------------+
|Frame Type | Flags             | Depends on Frame Type ...
+-----------+-------------------+
```
- **Major Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Major version
    number of the protocol.
- **Minor Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Minor version
    number of the protocol.
- Frame Type (6 bits = max value 63) Type of Frame
- Flags (10 bits) Reserved for future use

#### Frame Length

Routing and Forwarding frames do not have a length. They defer the frame’s length to the
encapsulate RSocket Extension frame.

#### Frame Types

| Type | Value | Description |
| ---- | ----- | ----------- |
| RESERVED | 0x00 | Reserved |
| ROUTE_SETUP | 0x01 | Information a routable destination sends to a broker when it connects
| ROUTE_ADD | 0x02 | Information passed between brokers when a routable destination connects. This information may not arrive from the broker where the routable destination connected, so the information could be forwarded
| ROUTE_REMOVE | 0x03 | Information passed between brokers to indicate a routable destination is no longer available.
| BROKER_INFO | 0x04 | Information a broker passes to another broker
| ADDRESS | 0x05 | A frame that contain information forwarding a message from an origin to a destination. This frame is intended for the metadata field.

##### ROUTE_SETUP

Route setup frames are sent from a routable destination to a broker when it wants to make a
service available for routing. The ROUTE_SETUP frame can be set via the RSocket SETUP frame
or another frame in the METADATA field. This frame includes a version number.

```
0 1 2 3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Major Version                 | Minor Version                 |
+-----------+-------------------+-------------------------------+
|Frame Type | Flags             |
+-----------+-------------------+-------------------------------+
|                                                               |
|                                                               |
| Route Id                                                      |
|                                                               |
+---------------+-----------------------------------------------+
| Name Length   | Service Name ...
+---------------+-----------------------------------------------+
|W|Key Length   | Tag Key ...
+---------------+-----------------------------------------------+
|F|Value Length | Tag Value ...
+---------------+-----------------------------------------------+
```
- **Major Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Major version
    number of the protocol.
- **Minor Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Minor version
    number of the protocol.
- **Frame Type** : (6 bits) 0x
- **Flags** : (10 bits)
- **Route Id** : (128 bit) id generated by the route when connecting that is used to uniquely
    identify the route. A route must be unique for all other routes. A route generally
    represents a connection from a service to a broker. For instance, a service can have
    multiple connections, and each connection would have a unique route id.
- **Name Length** : (8 bits = max value 256) Service name type in length
- **Service Name** : UTF-8 encoded string representing the routable service name. This is the
    human readable route name.
- **Key Length** : (7 bits = max 128) Optional. If frame does not end with the service name,
    the next field is the tag key length. If the first bit is set to 0, assume this is a length tag
    key, and the tag key field will follow. If the first bit is set to 1, this is a well-known tag
    type and will be looked up from the list of well-known tags included in the protocol.
- **Tag Key** : UTF-8 encoded string representing a key for the tag key value pair
- **Value Length** : (7 bits = max 128) OpT128tional. This does not need to present even if
    the key is present. If there is no value length present, assume the value is null. The first
    bit is not optional and is used to indicate if there are additional tags or not. If the first bit
    is set to 1, there are more tags. If it is set to 0, there are no more tags.
- **Tag Value** : UTF-8 is optional present if there is a value length. Represent the value for
    the tag.

##### BROKER_INFO

This frame is sent between brokers who want to forward requests between each other. This is
considered unidirectional information. If broker A sends broker B a BROKER_INFO frame, then
broker A can only forward data to Broker B. Broker B would need to send Broker A a
BROKER_INFO frame before it can forward requests from A. The broker implementations can
choose to share BROKER_INFO frames with other brokers. For instance, broker A could send
broker B a BROKER_INFO frame which broker B could forward to broker C. Broker C could then
receive requests from A, etc.

```
0 1 2 3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Major Version                 | Minor Version                 |
+-----------+-------------------+-------------------------------+
|Frame Type | Flags             |
+-----------+-------------------+-------------------------------+
|                                                               |
|                                                               |
| Broker Id                                                     |
|                                                               |
+---------------------------------------------------------------+
| Timestamp                                                     |
|                                                               |
+---------------+-----------------------------------------------+
|W|Key Length   | Metadata Key ...
+---------------+-----------------------------------------------+
|F|Value Length | Metadata Value ...
+---------------+-----------------------------------------------+
```
- **Major Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Major version
    number of the protocol.
- **Minor Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Minor version
    number of the protocol.
- **Frame Type** : (6 bits) 0x
- **Flags** : (10 bits)
- **Broker Id** : (128 bit) id generated by the broker to uniquely identify the broker.
- **Timestamp** : (64 bit) GMT UNIX epoch time stamp when the frame was credit
- **Metadata Key Length** : (7 bits = max 128) If the first bit is set to 0, assume this is a length
    metadata key, and the metadata key field will follow. If the first bit is set to 1, this is a
    well-known tag type and will be looked up from the list of well-known metadata
    included in the protocol.
- **Metadata Key** : UTF-8 encoded string representing a key for the metadata key value pair


- **Metadata Value Length** : (7 bits = max 128) Optional. This does not need to present even
    if the key is present. If there is no value length present, assume the value is null. The
    first bit is not optional and is used to indicate if there are additional metadata or not. If
    the first bit is set to 1 there are more tags. If it is set to 0, there is no more metadata.
- **Metadata Value** : A byte string containing metadata

##### ROUTE_JOIN

The ROUTE_JOIN frame is sent between brokers and contains information about routable
destinations.

```
0 1 2 3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Major Version                 | Minor Version                 |
+-----------+-------------------+-------------------------------+
|Frame Type | Flags             |
+-----------+-------------------+-------------------------------+
|                                                               |
|                                                               |
| Broker Id                                                     |
|                                                               |
+---------------------------------------------------------------+
|                                                               |
|                                                               |
| Route Id                                                      |
|                                                               |
+---------------------------------------------------------------+
| Timestamp                                                     |
|                                                               |
+---------------+-----------------------------------------------+
| Name Length   | Service Name ...
+---------------+-----------------------------------------------+
|W|Key Length   | Tag Key ...
+---------------+-----------------------------------------------+
|F|Value Length | Tag Value ...
+---------------+-----------------------------------------------+
```
- **Major Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Major version
    number of the protocol.
- **Minor Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Minor version
    number of the protocol.i
- **Frame Type** : (6 bits) 0x
- **Flags** : (10 bits)
- **Broker Id** : (128 bit) id generated by the broker that received the connection from the
    route. This is used to distinguish which broker to route to when creating routing tables.
- **Route Id** : (128 bit) id generated by the route when connecting that is used to uniquely
    identify the route. A route must be unique for all other routes.
- **Timestamp** : (64 bit) GMT UNIX epoch time stamp when the frame was credit
- **Name Length** : (8 bits = max value 256) Service name type in length
- **Service Name** : UTF-8 encoded string representing the routable service name
- **Key Length** : (7 bits = max 128) If frame does not end with the service name, the next
    field is the tag key length. If the first bit is set to 0, assume this is a length tag key, and
    the tag key field will follow. If the first bit is set to 1, this is a well-known tag type and
    will be looked up from the list of well-known tags included in the protocol.
- **Tag Key** : UTF-8 encoded string representing a key for the tag key value pair
- **Value Length** : (7 bits = max 128) Optional. This does not need to present even if the key
    is present. If there is no value length present, assume the value is null. The first bit is not
    optional and is used to indicate if there are additional tags or not. If the first bit is set to
    1, there are more tags. If it is set to 0, there are no more tags.
- **Tag Value** : UTF-8 that is optional present if there is a value length. Represent the value
    for the tag.

##### ROUTE_REMOVE

Used to indicate a route is no longer valid and should be removed from the routing table.

```
0 1 2 3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Major Version                 | Minor Version                 |
+-----------+-------------------+-------------------------------+
|Frame Type | Flags             |
+-----------+-------------------+-------------------------------+
|                                                               |
|                                                               |
| Broker Id                                                     |
|                                                               |
+---------------------------------------------------------------+
|                                                               |
|                                                               |
| Route Id                                                      |
|                                                               |
+---------------------------------------------------------------+
| Timestamp                                                     |
|                                                               |
+---------------------------------------------------------------+
```
- **Major Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Major version
    number of the protocol.
- **Minor Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Minor version
    number of the protocol.
- **Frame Type** : (6 bits) 0x
- **Flags** : (10 bits)
- **Broker Id** : (128 bit) id generated by the broker that received the connection from the
    route. This is used to distinguish which broker to route to when creating routing tables.
- **Key Length** : (7 bits = max 128) If frame does not end with the service name, the next
    field is the tag key length. If the first bit is set to 0, assume this is a length metadata key,
    and the tag key field will follow. If the first bit is set to 1, this is a well-known metadata
    type and will be looked up from the list of well know tags included in the protocol.
- **Route Id** : (128 bit) id generated by the route when connecting that is used to uniquely
    identify the route. A route must be unique for all other routes.
- **Timestamp** : (64 bit) GMT UNIX epoch time stamp when the frame was created

##### ADDRESS

The ADDRESS frame is metadata attached to a request that is used to forward the message
between nodes until it reaches its intended destination. It may be attached as the payload’s


only metadata, or it can be included in composite metadata. Implementations MUST support
both cases.

```
0 1 2 3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
| Major Version                 | Minor Version                 |
+-----------+-------------------+-------------------------------+
|Frame Type | Flags             |
+-----------+---------------------------------------------------+
|                                                               |
|                                                               |
| Origin Route Id                                               |
|                                                               |
+---------------+-----------------------------------------------+
|W|Key Length   | Metadata Key ...
+---------------+-----------------------------------------------+
|F|Value Length | Metadata Value ...
+---------------+-----------------------------------------------+
|W|Key Length   | Tag Key ...
+---------------+-----------------------------------------------+
|F|Value Length | Tag Value ...
+---------------+-----------------------------------------------+
| Wrapped Metadata ...
+---------------------------------------------------------------+
```
- **Major Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Major version
    number of the protocol.
- **Minor Version** : (16 bits = max value 65,535) Unsigned 16-bit integer of Minor version
    number of the protocol.
- **Frame Type** : (6 bits) 0x
- **Flags** : (10 bits)
    o **(E) indicates if the payload is encrypted**
    o **(U) indicates unicast routing**
    o **(M) indicates multicast routing**
    o **(S) indicates shared routing**
       The flags U, M, S are exclusive. A request that has more than one of these flags
       set is considered invalid, and the request MUST be rejected.
- **Original Route Id** : The Route Id of where the ADDRESS came from
- **Metadata Key Length** : (7 bits = max 128) If the first bit is set to 0, assume this is a length
    metadata key, and the metadata key field will follow. If the first bit is set to 1, this is a
    well-known tag type and will be looked up from the list of well-known metadata
    included in the protocol.
- **Metadata Key** : UTF-8 encoded string representing a key for the metadata key value pair
- **Metadata Value Length** : (7 bits = max 128) Optional. This does not need to present even
    if the key is present. If there is no value length present, assume the value is null. The
    first bit is not optional and is used to indicate if there are additional metadata or not. If
    the first bit is set to 1, there are more tags. If it is set to 0, there is no more metadata.
- **Metadata Value** : A byte string containing metadata
- **Tag Key** : UTF-8 encoded string representing a key for the tag key value pair
- **Value Length** : (7 bits = max 128) Optional. This does not need to present even if the key
    is present. If there is no value length present, assume the value is null. The first bit is not
    optional and is used to indicate if there are additional tags or not. If the first bit is set to
    1, there are more tags. If it is set to 0, there are no more tags.
- **Tag Value** : UTF-8 that is optional present if there is a value length. Represent the value
    for the tag.
- **Wrapped Metadata** : If there is existing metadata in a request before routing, the
    ADDRESS frame can be used to wrap this metadata. The wrapped metadata field has no
    length and consists of the ADDRESS frame’s remain bytes

The metadata key/value pairs attached to this request is not application metadata. It SHOULD
only be metadata about how the message is to be routed. The intended target of this metadata
is other brokers. Metadata is distinct from tags in that metadata is not used for routing.

Tags are information used use by brokers to determine where to route a message. All tags
included in the ADDRESS are used for routing a request.

## Routing Protocol Semantics

The routing protocol is used to announce that a routable destination is available, announce
when a routable destination is no longer available, disseminate routing information, and build a
routing table.

#### Announcements

_Routable Destinations_

A routable destination that wishes to receive requests MUST send a ROUTE_SETUP frame to
broker that it wishes to receive traffic from. The route is considered valid for as long as the
connection is valid. If the connection to broker breaks, it is no longer valid. If the routable
destination and broker support RSocket, resumption of the connection is not considered
broken if resumption is successful.

_Route Id_

When connecting to a broker the routable destination MUST provide a Route Id. A Route Id is
used to determine a unique route. The Route Id SHOULD be correlated with RSocket’s physical
transport connection. For instance, if a client makes 4 connections to a broker that would
create 4 unique Routable destinations. Each connection would have a unique Route Id
associated with it. If a connection disconnects, it SHOULD reconnect with the same Route Id. In
the example with 4 connections, if the 3rd connection with router id 1234 is disconnected, when
it reconnects to a broker it SHOULD reconnect with router id 1234. Brokers can only allow one
connection for a given Route Id to be connected at a time. Re-connecting with the same Route
Id will allow the broker to clean up connections easier.

#### Brokers

_Handling ROUTE_SETUP Frames_

A broker that receives a ROUTE_SETUP frame will use this frame to create a new route. A
broker or a broker cluster MUST only allow one connection for a given Route Id. If a routable
destination connects, and it is determined that there is an existing route present with the same
Route Id the Broker or Broker cluster MUST close the existing route, and remove it from the
table, and replace it with the information from the new ROUTE_SETUP.

_Emitting ROUTE_ADD Frames_

A broker SHOULD announce the new route to other interested brokers. The Broker does this by
creating a ROUTER_ADD frame with the information from the ROUTE_SETUP frame that it
received. ROUTE_ADD frames MAY be sent to other Brokers to reconcile route information
when requested by another Broker. ROUTE_ADD frames will contain a GMT timestamp. Frames
will be ignored if the information in the routing table has a newer timestamp than the
ROUTE_ADD frame.

_Default Tags_

Each routable destination MUST have two tags automatically added its ROUTE_ADD frame by
the Broker if they are not already present. The tags are io.rsocket.routing.ServiceName and
io.rsocket.routing.RouteId. These tags will be automatically added so that each tag can be
routed to via ServiceName or RouteId. A Broker MAY chose to add additional tags depending on
the implementation. It is recommended that these tags are added by the origin.

_Emitting ROUTE_REMOVE Frames_

When a routable destination disconnects from the Broker, the Broker MUST emit a
ROUTE_REMOVE frame to interested Brokers. Brokers that receive this frame MUST remove
the indicated front from their Route table if ROUTE_REMOVE frame’s timestamp is newer than
the route table’s timestamp.

_Routing Table_

Brokers will construct a routing table from the ROUTE_SETUP, ROUTE_ADD and
ROUTE_REMOVE frames. Each entry in the route table will have a unique id that is the Route Id.
The route table MUST not allow duplicate Route Id entries. The broker will use the timestamp
of events to determine if the update will be applied. Updates to the routing table will only be
applied if the table entry’s timestamp is older than the updates’ timestamp.

## Forwarding Protocol

Brokers route is based on an ADDRRESS frame found in the request payload’s metadata. This
can either be as a composite metadata entry, or the only entry in the request payload’s
metadata. It is RECOMMENDED that this is used with composite metadata. Routing is
supported on the request/reply, request/channel, request/stream, metadata/push, and
fire/forget interactions.

#### Wrapping and Unwrapping Metadata in an ADDRESS

Clients may want to forward a message that has existing metadata. The origin can wrap the
existing metadata into an ADDRESS frame, and then un-wrap the metadata at the destination.

#### Forwarding Semantics

Forwarding requests between routable destinations is done using the tags provided in the
ADDRESS frame. The first step in forwarding the data is to create a list of routable destinations
to forward the request to.

Creating list of Routable Destinations

1. Broker receives client ADDRESS frame stored in metadata field of the RSocket request
    payload
2. Use the tags provided in the ADDRESS to lookup routable destinations in the brokers
    routing table
       a. For each ADDRESS tag, look up the corresponding bitmap index in the brokers
          routing table
             i. Note: An ADDRESS may want to match routes with tags A, B and C– but a
                routable destination contains tags A, B, C and D. For the purposes of
                routing, D will be ignored. Only tags provided in the ADDRESS are
                considered.
       b. All tags must have a valid index. If a tag does not contain an index, then there are
          no routable destinations available for the provided tags
             i. The broker can handle this situation in the following ways, depending on
                the implementation
                   1. Reject the route immediately and send an error to the client
                   2. Wait for the route to become available
                   3. Wait for the route to become available with a timeout. If the
                      timeout expires, send an error to the client
       c. Use a bitwise ‘AND’ to combine the found tag indexes to determine a valid index
          of routable destinations
       d. If the index is empty, there are no valid routable destinations. Use the method
          described above for handling a situation where there are no routes.
       e. If the index is not empty, look at the flags to determine the route type. The
          following sections detail how to handle the routing type.

##### Handling Routing Flags

Once a list of routable destinations has been created, the routing flags need to be introspected
to see which routing method to use.

_Unicast Routing_

When the unicast route flag is set, a broker will use a list of routes and select one routable
destination from the list of routes. The method to select the routes is determined by the
implementation. The client can supply the io.rsocket.routing.LBMethod metadata to provide a
hint to the broker which algorithm they would prefer. This is optional and the broker does not
need to use the hint.

_Shard Routing_

When the shard route flag is set, a broker must select a route from the list of routes using
sharding. The one or more instances of the metadata io.rsocket.routing.ShardKey MUST be
present. The value of the io.rsocket.routing.ShardKey metadata MUST be to a tag key that is
present on the request. If the value in the io.rsocket.routing.ShardKey metadata is not to a tag
that is present, the request is invalid and MUST be rejected. Using the tag(s) from the
io.rsocket.routing.ShardKey metadata, the broker will select a routable destination using
implementation of the brokers choice. Optionally, the client can supply the
io.rsocket.routing.ShardMethod metadata to provide the broker a hint of which algorithm the
broker would like. This is optional and broker does not need to use the hint.

_Multicast Routing_

When the multicast route flag is set, a broker must forward a request to all routes in the list of
routes. The manner with which it forwards the routes depends on the request’s RSocket
interaction model.

1. Fire and Forget – the broker will send the message to each routable destination
2. Request / Reply – the broker will forward the message to each routable destination. The
    broker will only reply to client with the FIRST message that returns. This includes an
    error. It will cancel requests that have not completed and ignore additional results.
3. Request / Stream – the broker will forward the message to each routable destination
    and combine the response streams into a single stream back to the client. An error
    message will cancel all streams.
4. Request / Channel – the broker will stream each message from the client to the routing
    destinations. It will combine the responses back to the client in a single stream. An error
    message will cancel all streams.

While multi-cast streaming a routable destination could no long be valid. The broker
implementation can either emit an error closing the stream, or quietly handle its removal. The
is determined by the implementation.

_Forwarding the Request_

Once the broker has determined the routes and the method the broker can forward the
message, the message can be forwarded to another broker where it will be forwarded to
another broker or to the destination. A broker forwarding a message MAY add additional
metadata, and tags to the envelope but it MUST not mutate the wrapped metadata, or data of
the request. If wrapping was used to send the ADDRESS frame, once the routable destination
receives the request, it will unwrap the metadata and discard the ADDRESS frame.

## Well-known Keys

To keep the request more compact, the protocol will maintain a list of well-known tags and
metadata keys.

#### Well-known Types

This table contains a set of keys used for tags and metadata. If they are included in a tag on the
envelope, they will be considered for routing. If they are included in metadata, they will not be
considered for routing.

| Key | Value | Description |
| --- | ----- | ----------- |
| No Tag Present| 0x00 | Used to indicate there is no tag |
| io.rsocket.routing.ServiceName | 0x01 | Tag for the service name
| io.rsocket.routing.RouteId | 0x02 | Tag for the a Route Id
| io.rsocket.routing.InstanceName | 0x03 | Tag for the instance name
| io.rsocket.routing.ClusterName | 0x04 | Tag key for indicating metadata about a cluster
| io.rsocket.routing.Provider | 0x05 | Indicates who is providing computer – i.e. AWS, Google, etc.
| io.rsocket.routing.Region | 0x06 | Indicates a region – i.e. AWS region
| io.rsocket.routing.Zone | 0x07 | Indicates a zone – i.e. AWS AZ
| io.rsocket.routing.Device | 0x08 | Tag that indicates a type of Device like iPhone, Chrome, PlayStation, etc.
| io.rsocket.routing.OS | 0x09 | Operating System
| io.rsocket.routing.UserName | 0x0A | String representing a user
| io.rsocket.routing.UserId | 0x0B | Numeric value representing a user
| io.rsocket.routing.MajorVersion | 0x0C |
| io.rsocket.routing.MinorVersion | 0x0D |
| io.rsocket.routing.PatchVersion | 0x0E |
| io.rsocket.routing.Version | 0x0F |
| io.rsocket.routing.Environment | 0x10 | The environment the routable destination is in – e.g. test, staging, prod
| io.rsocket.routing.TestCell | 0x11 | Test Cell for A/B testing
| io.rsocket.routing.DNS | 0x12 | The DNS of the routable destination – the host name
| io.rsocket.routing.IPv4 | 0x13 | IPv4 that could route with - doesn’t need to be addressable and isn’t unique
| io.rsocket.routing.IPv6 | 0x14 | IPv6 that could route with - doesn’t need to be addressable and isn’t unique
| io.rsocket.routing.Country | 0x15 | Country a route is in
| io.rsocket.routing.TimeZone | 0x1A | Time zone a route is in
| io.rsocket.routing.ShardKey | 0x1B | Contains a key to a tag to shard the request on
| io.rsocket.routing.ShardMethod | 0x1C | Which algorithm to use for sharding the request
| io.rsocket.routing.StickyRouteKey | 0x1D | Contains a key to a tag used to create a sticky route.
| io.rsocket.routing.LBMethod | 0x1E | Which algorithm to use for load balancing a request
| Broker Implementation Ext Key | 0x7C | This value is reserved to create extensions for broker implementation. These keys would be specific to a broker and are not expected to work on another implementation. This tag would allow the protocol to create another list of tags for quick lookup. When this tag is sent, the key length is 16- bits allowing 65, extension tags.
| Well Know Ext Key | 0x7F | This value is reserved to create Well-known Types for the specification if the current list exceeds 127 tags. This tag would allow the protocol to create another list of tags for quick lookup. When this tag is sent, the key length is 16-bits allowing 65, extension tags.

