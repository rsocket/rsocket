namespace rxlib {

    class Frame {

        static Frame construct(short type) {
            if (type == 1) { return new Setup(); }
            if (type == 2) { return new Lease(); }
            if (type == 3) { return new Keepalive(); }
            if (type == 4) { return new Request(); }
            if (type == 5) { return new RequestFNF(); }
            if (type == 6) { return new RequestStream(); }
            if (type == 7) { return new RequestSub(); }
            if (type == 8) { return new RequestChannel(); }
            if (type == 9) { return new RequestN(); }
            if (type == 10) { return new Cancel(); }
            if (type == 11) { return new Response(); }
            if (type == 12) { return new Error(); }
            if (type == 13) { return new MetadataPush(); }
            return null;
        }

        static Frame parse(Buffer buf, int offset) {
            short type = buf.getShort(offset + 4);
            Frame frame = construct(type);
            if (frame == null) { return null; }
            frame.type = type;
            frame.decode(buf, offset);
            return frame;
        }

        int size;
        short type;
        short flags = 0;
        int stream = 0;

        int decode(Buffer buf, int offset) {
            size = buf.getInt(offset + 0);
            flags = buf.getShort(offset + 6);
            stream = buf.getInt(offset + 8);
            return 12 + decodeType(buf, offset + 12);
        }

        int encode(Buffer buf, int offset) {
            int size = encodeType(buf, offset + 12);
            size = size + 12;
            buf.putInt(offset, size);
            buf.putShort(offset + 4, type);
            buf.putShort(offset + 6, flags);
            buf.putInt(offset + 8, stream);
            return size;
        }

        int decodeType(Buffer buf, int offset);

        int encodeType(Buffer buf, int offset);

        void dispatch(FrameReceiver receiver);

    }

    class Setup extends Frame {

        int version = 0;
        int keepaliveInterval = 0;
        int maxLifetime = 0;
        String metadataType = "";
        String dataType = "";

        Setup() { self.type = 1; }

        int decodeType(Buffer buf, int offset) {
            version = buf.getInt(offset);
            keepaliveInterval = buf.getInt(offset + 4);
            maxLifetime = buf.getInt(offset + 8);
            byte mdSize = buf.getByte(offset + 12);
            metadataType = buf.getStringUTF8(offset + 13, mdSize);
            byte dataSize = buf.getByte(offset + 13 + mdSize);
            dataType = buf.getStringUTF8(offset + 14 + mdSize, dataSize);
            return 14 + mdSize + dataSize;
        }

        int encodeType(Buffer buf, int offset) {
            buf.putInt(offset, version);
            buf.putInt(offset + 4, keepaliveInterval);
            buf.putInt(offset + 8, maxLifetime);
            byte mdSize = buf.putStringUTF8(offset + 13, metadataType);
            buf.putByte(offset + 12, mdSize);
            byte dataSize = buf.putStringUTF8(offset + 14 + mdSize, dataType);
            buf.putByte(offset + 13 + mdSize, dataSize);
            return 14 + mdSize + dataSize;
        }

        String toString() {
            return "Setup{" + version.toString() + ", " + keepaliveInterval.toString() + ", " +
                maxLifetime.toString() + ", " + metadataType + ", " + dataType + "}";
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onSetup(self);
        }

    }

    class Lease extends Frame {

        int ttl;
        int nrequests;

        Lease() { self.type = 2; }

        int decodeType(Buffer buf, int offset) {
            ttl = buf.getInt(offset);
            nrequests = buf.getInt(offset + 4);
            return 8;
        }

        int encodeType(Buffer buf, int offset) {
            buf.putInt(offset, ttl);
            buf.putInt(offset + 4, nrequests);
            return 8;
        }

        String toString() {
            return "Lease{" + ttl.toString() + ", " + nrequests.toString() + "}";
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onLease(self);
        }
    }

    class Keepalive extends Frame {

        Keepalive() { self.type = 3; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onKeepalive(self);
        }
    }

    class Request extends Frame {

        Request() { self.type = 4; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        String toString() {
            return "Request{}";
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onRequest(self);
        }
    }

    class RequestFNF extends Frame {

        RequestFNF() { self.type = 5; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onRequestFNF(self);
        }
    }

    class RequestSub extends Frame {

        RequestSub() { self.type = 6; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onRequestSub(self);
        }
    }

    class RequestChannel extends Frame {

        RequestChannel() { self.type = 7; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onRequestChannel(self);
        }
    }

    class RequestStream extends Frame {

        RequestStream() { self.type = 8; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onRequestStream(self);
        }
    }

    class RequestN extends Frame {

        RequestN() { self.type = 9; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onRequestN(self);
        }
    }

    class Cancel extends Frame {

        Cancel() { self.type = 10; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onCancel(self);
        }
    }

    class Response extends Frame {

        Response() { self.type = 11; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        String toString() {
            return "Response{}";
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onResponse(self);
        }
    }

    class Error extends Frame {

        int code;

        Error() { self.type = 12; }

        int decodeType(Buffer buf, int offset) {
            code = buf.getInt(offset);
            return 4;
        }

        int encodeType(Buffer buf, int offset) {
            buf.putInt(offset, code);
            return 4;
        }

        String toString() {
            return "Error{" + code.toString() + "}";
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onError(self);
        }
    }

    class MetadataPush extends Frame {

        MetadataPush() { self.type = 13; }

        int decodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        int encodeType(Buffer buf, int offset) {
            // TODO
            return 0;
        }

        void dispatch(FrameReceiver receiver) {
            receiver.onMetadataPush(self);
        }

    }

    interface FrameReceiver {

        void onSetup(Setup setup) {}

        void onLease(Lease lease) {}

        void onKeepalive(Keepalive keepalive) {}

        void onRequest(Request request) {}

        void onRequestFNF(RequestFNF fnf) {}

        void onRequestSub(RequestSub sub) {}

        void onRequestChannel(RequestChannel channel) {}

        void onRequestStream(RequestStream stream) {}

        void onRequestN(RequestN requestN) {}

        void onCancel(Cancel cancel) {}

        void onResponse(Response response) {}

        void onError(Error error) {}

        void onMetadataPush(MetadataPush push) {}

    }

    interface FrameSender {

        void send(Frame frame);

    }   

}
