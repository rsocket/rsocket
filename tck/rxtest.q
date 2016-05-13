package rxtest 0.1.0;

use rxlib.q;

void main(List<String> args) {
    test.run(args);
}

import quark.test;
import rxlib;

class RoundTripTest {

    void doTestSetup(int version,
                     int keepaliveInterval,
                     int maxLifetime,
                     String metadataType,
                     String dataType) {
        Setup setup = new Setup();
        setup.version = version;
        setup.keepaliveInterval = keepaliveInterval;
        setup.maxLifetime = maxLifetime;
        setup.metadataType = metadataType;
        setup.dataType = dataType;

        Buffer buf = defaultCodec().buffer(1024);
        setup.encode(buf, 0);

        Setup copy = new Setup();
        copy.decode(buf, 0);
        checkEqual(version, copy.version);
        checkEqual(keepaliveInterval, copy.keepaliveInterval);
        checkEqual(maxLifetime, copy.maxLifetime);
        checkEqual(metadataType, copy.metadataType);
        checkEqual(dataType, copy.dataType);
    }

    void testSetup1() { doTestSetup(123, 30, 60*10, "testMeta", "testType"); }
    void testSetup2() { doTestSetup(321, 0, 0, "", ""); }

    void doTestLease(int ttl, int nrequests) {
        Lease lease = new Lease();
        lease.ttl = ttl;
        lease.nrequests = nrequests;

        Buffer buf = defaultCodec().buffer(1024);
        lease.encode(buf, 0);

        Lease copy = new Lease();
        copy.decode(buf, 0);
        checkEqual(ttl, copy.ttl);
        checkEqual(nrequests, copy.nrequests);
    }

    void testLease1() { doTestLease(0, 0); }
    void testLease2() { doTestLease(0, 1); }
    void testLease3() { doTestLease(1, 0); }
    void testLease4() { doTestLease(1, 1); }

}
