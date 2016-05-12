use rxlib.q;

import rxlib;
import quark.concurrent;
import quark.logging;

@doc("A simple Echo responder.")
class Echo extends Responder {

    Response respond(Request request) {
        return new Response();
    }

}

@doc("A reactive socket server skeleton. The server skeleton uses web sockets.")
@doc("The server will dispatch to a different handler based on the upgrade url.")
class RXServer extends WSServlet {

    static Logger log = new Logger("rxsrv");

    WSHandler onWSConnect(HTTPRequest upgrade) {
        String urls = upgrade.getUrl();
        log.info("CONNECTION: " + urls);
        URL url = URL.parse(urls);

        if (url.path == "/request") { return new RXHandler(new RequestServer(new Echo())); }
        if (url.path == "/lease/request") { return new RXHandler(new LeasedRequestServer(new Echo(), 5, 1.0)); }

        return null; // TODO: define a catchall handler to do something reasonable
    }

}

void main(List<String> args) {
    Config config = logging.makeConfig();
    config.setAppender(logging.stdout());
    // Set this to debug for a full trace of all network interactions.
    config.setLevel("info");
    config.configure();

    RXServer server = new RXServer();
    // XXX: ugh, need to have the paths in two places right now
    server.serveWS(args[1] + "/request");
    server.serveWS(args[1] + "/lease/request");
}
