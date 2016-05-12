package rxlib 0.1.0;

include rxframe.q;
include rxws.q;

import quark.concurrent;

namespace rxlib {

    interface RXEndpoint extends FrameReceiver {

        void onInit(FrameSender sender);

        void onConnect();

        void onDisconnect(); // XXX: errors?

    }

    class BaseEndpoint extends RXEndpoint {

        FrameSender sender;

        void onInit(FrameSender sender) {
            self.sender = sender;
        }

        void onConnect() {}

        void onDisconnect() {}

        void send(Frame frame) {
            sender.send(frame);
        }

    }

    interface Responder {

        Response respond(Request request);

    }

    interface Requester {

        void onResponse(Response response);

        void onError(Error error);

    }

    class RequestServer extends BaseEndpoint {

        Responder responder;

        RequestResponse(Responder responder) {
            self.responder = responder;
        }

        void onSetup(Setup setup) {
            if (setup.flags != 0) {
                Error error = new Error();
                error.code = 1;
                self.send(error);
            }
        }

        void onRequest(Request request) {
            self.send(responder.respond(request));
        }

    }

    interface RequestClient extends RXEndpoint {

        void request(Request request, Requester requester);

    }

    class SimpleRequestClient extends BaseEndpoint, RequestClient {

        List<Request> outgoing = [];
        List<Requester> outstanding = [];
        bool connected = false;
        bool disconnected = false;

        RequestClient() {}

        void onConnect() {
            connected = true;
            Setup setup = new Setup();
            setup.flags = 0;
            self.send(setup);
            pump();
        }

        void onDisconnect() {
            disconnected = true;
            while (outstanding.size() > 0) {
                outstanding[0].onError(new Error());
                outstanding = outstanding.slice(1, outstanding.size());
            }
            outgoing = [];
        }

        void request(Request request, Requester requester) {
            if (disconnected) {
                requester.onError(new Error());
            } else {
                outgoing.add(request);
                outstanding.add(requester);
                pump();
            }
        }

        void onResponse(Response response) {
            Requester requester = outstanding[0];
            outstanding = outstanding.slice(1, outstanding.size());
            requester.onResponse(response);
        }

        int pumpSome(int limit) {
            if (!connected || disconnected) { return 0; }

            int count = 0;
            while (count < limit && outgoing.size() > 0) {
                self.send(outgoing[0]);
                outgoing = outgoing.slice(1, outgoing.size());
                count = count + 1;
            }
            return count;
        }

        void pump() {
            pumpSome(outgoing.size());
        }
    }

    class LeasedRequestClient extends SimpleRequestClient, Task {

        int leases = 0;
        long expires = 0L;

        LeasedRequestClient() {}

        void onConnect() {
            self.connected = true;
            Setup setup = new Setup();
            setup.flags = 4;
            self.send(setup);
        }

        void onLease(Lease lease) {
            leases = lease.nrequests;
            expires = now() + lease.ttl;
            Context.runtime().schedule(self, lease.ttl.toFloat()*1000.0);
            pump();
        }

        void onExecute(Runtime runtime) {
            if (now() >= expires) {
                leases = 0;
            }
        }

        void pump() {
            leases = leases - self.pumpSome(leases);
        }

    }

    class LeasedRequestServer extends BaseEndpoint, Task {

        Responder responder;
        int capacity;
        float period;
        bool disconnected = false;

        LeasedRequestServer(Responder responder, int capacity, float period) {
            self.responder = responder;
            self.capacity = capacity;
            self.period = period;
        }

        void onDisconnect() {
            disconnected = true;
        }

        void onSetup(Setup setup) {
            if (setup.flags != 4) {
                Error error = new Error();
                error.code = 1;
                self.send(error);
            } else {
                self.onExecute(Context.runtime());
            }
        }

        void onExecute(Runtime runtime) {
            if (!disconnected) {
                Lease lease = new Lease();
                lease.nrequests = capacity;
                lease.ttl = (period*1000.0).round();
                self.send(lease);
                Context.runtime().schedule(self, period);
            }
        }

        void onRequest(Request request) {
            self.send(responder.respond(request));
        }

    }   

}
