# ReactiveSocket TCK/RI

This directory contains (the start of) a reference implementation and
TCK for the reactive sockets protocol implemented in Quark.

The Quark language exists exclusively to be compiled into other high
level languages. It was created to aid in the implementation and ease
adoption of protocols that require complex behaviors. For more about
Quark see: https://github.com/datawire/quark

Please note that Quark is a new project under active development, so
if you have any trouble following the instructions here, please join
the public slack channel by clicking on the slack badge found at the
above link.

This directory contains the following files:

 - rxlib.q -- the core of the reference implementation
   + rxframe.q -- the frame definitions
   + rxws.q -- the web sockets glue
 - rxtest.q -- a test suite for rxlib.q
 - rxserver.q -- a TCK server
 - rxclient.q -- a TCK client

Because quark does not have its own runtime you need to choose a
language to use in order to run quark compiled code. This readme will
assume python, however java, ruby, and javascript should work
similarly if all the necessary dependencies are available.

To install the quark compiler, first use pip to install the
datawire-quark package and then run quark --version to verify that it
worked:

    # pip install --user --upgrade datawire-quark
    # quark --version
    Quark 0.5.1

Note: depending on your platform you may need to add ~/.local/bin to
your path.

You can now use the compiler to build the test suite, client, and server:

    # quark compile rxtest.q rxclient.q rxserver.q
    ...

By default, the compiler will produce source code in the output
directory. The output of the compiler is a set of interdependent
packages that use the native package tooling of the given backend.

    # tree -dL 2 output
    output
    ├── java
    │   ├── quark
    │   ├── rxclient
    │   ├── rxlib
    │   ├── rxserver
    │   └── rxtest
    ├── js
    │   ├── quark
    │   ├── rxclient
    │   ├── rxlib
    │   ├── rxserver
    │   └── rxtest
    ├── py
    │   ├── quark
    │   ├── rxclient
    │   ├── rxlib
    │   ├── rxserver
    │   └── rxtest
    └── rb
        ├── quark
        ├── rxclient
        ├── rxlib
        ├── rxserver
        └── rxtest

    24 directories

You can build and install these manually, or you can use quark to
install the generated packages in the language of your choice. The
quark compiler will simply invoke the toolchain of the given backend,
so you will need to have the appropriate tooling installed for your
language. We will use python for brevity, but other languages work
similarly.

    # quark install rxtest.q rxclient.q rxserver.q --python
    ...

# Running the tests

The details of running quark generated code differ depending on the
backend in use, however the quark compiler can run the code for you:

    # quark run --python rxtest.q
    ...

# Running the server

    # quark run rxserver.q ws://localhost:8910 --python

# Running the client

    # quark run rxclient.q ws://localhost:8910 --python

# Status

The implementation is currently mostly skeletal, however it does
include a functioning server and client that do simple
request/responses and rate limited request/responses using the
reactive sockets lease mechanism.

A few pieces of the implementation use some newer quark features that
aren't functioning quite right for java and ruby, so currently python
and javascript are the safe bets for playing with this stuff.
