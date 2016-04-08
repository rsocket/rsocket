use rxlib.q;

import rxlib;
import quark.concurrent;
import quark.logging;

class Printer extends Requester {

    void onResponse(Response response) {
        print(response.toString());
    }

    void onError(Error error) {
        print("ERROR: " + error.toString());
    }

}

void spam(RequestClient client, Requester requester, int count) {
    int idx = 0;
    while (idx < 10) {
        client.request(new Request(), requester);
        idx = idx + 1;
    }
}

void main(List<String> args) {
    Config config = logging.config();
    config.setAppender(logging.stdout());
    config.setLevel("info");
    config.configure();
    Runtime runtime = Context.runtime();

    Printer printer = new Printer();

    RequestClient client = new SimpleRequestClient();
    runtime.open(args[1] + "/request", new RXHandler(client));
    spam(client, printer, 10);

    client = new LeasedRequestClient();
    runtime.open(args[1] + "/lease/request", new RXHandler(client));
    spam(client, printer, 10);
}
