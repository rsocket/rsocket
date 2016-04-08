namespace rxlib {

    class RXHandler extends WSHandler, FrameSender {

        static Logger log = new Logger("rxlib");

        WebSocket socket;
        Buffer buf = defaultCodec().buffer(1024);
        RXEndpoint endpoint;

        RXHandler(RXEndpoint endpoint) {
            self.endpoint = endpoint;
        }

        void send(Frame frame) {
            frame.encode(buf, 0);
            socket.sendBinary(buf);
            log.info("SENT: " + frame.toString());
        }

        void onWSInit(WebSocket socket) {
            self.socket = socket;
            endpoint.onInit(self);
        }

        void onWSConnected(WebSocket socket) {
            log.info("CONNECT: " + socket.toString());
            endpoint.onConnect();
        }

        void onWSError(WebSocket socket) {
            log.error(socket.toString());
        }

        void onWSClosed(WebSocket socket) {
            log.info("CLOSED: " + socket.toString());
        }

        void onWSFinal(WebSocket socket) {
            endpoint.onDisconnect();
        }

        void onWSBinary(WebSocket socket, Buffer buf) {
            Frame frame = Frame.parse(buf, 0);
            log.info("RCVD: " + frame.toString());
            frame.dispatch(endpoint);
        }

    }   

}
