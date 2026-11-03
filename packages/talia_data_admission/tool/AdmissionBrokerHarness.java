package com.talia.quran.admission;

import java.io.File;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

/** JVM-only proof of local aggregation, OS contention and irreversible foreground. */
public final class AdmissionBrokerHarness {
    private static void check(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
    private static String child(File file, String mode) throws Exception {
        String java = new File(System.getProperty("java.home"), "bin/java").getPath();
        Process p = new ProcessBuilder(java, "-cp", System.getProperty("java.class.path"),
                AdmissionBrokerHarness.class.getName(), "child", file.getPath(), mode).redirectErrorStream(true).start();
        String output;
        try (InputStream input = p.getInputStream()) { output = new String(input.readAllBytes(), StandardCharsets.UTF_8).trim(); }
        check(p.waitFor() == 0, "child failed: " + output);
        return output;
    }
    public static void main(String[] args) throws Exception {
        if (args[0].equals("child")) {
            String token = AdmissionBroker.acquire(new File(args[1]), "child", args[2]);
            System.out.print(token == null ? "denied" : "acquired");
            return;
        }
        File path = new File(args[0]);
        String a = AdmissionBroker.acquire(path, "engine-a", "probe");
        String b = AdmissionBroker.acquire(path, "engine-b", "worker");
        check(a != null && b != null, "aggregate readers");
        check(!AdmissionBroker.validate(a, "engine-b"), "engine token isolation");
        check(!AdmissionBroker.release(a, "engine-b"), "wrong engine release");
        check(AdmissionBroker.acquire(path, "engine-c", "maintenance") == null, "local exclusive conflict");
        check(child(path, "maintenance").equals("denied"), "cross-process exclusive conflict");
        check(child(path, "probe").equals("acquired"), "cross-process reader sharing");
        check(AdmissionBroker.release(a, "engine-a"), "release probe");
        check(AdmissionBroker.release(b, "engine-b"), "release worker");
        String exclusive = AdmissionBroker.acquire(path, "engine-a", "maintenance");
        check(exclusive != null, "maintenance admitted");
        check(child(path, "worker").equals("denied"), "cross-process worker conflict");
        check(AdmissionBroker.release(exclusive, "engine-a"), "release maintenance");
        String foreground = AdmissionBroker.acquire(path, "engine-a", "foreground");
        check(foreground != null && !AdmissionBroker.release(foreground, "engine-a"), "foreground lifetime");
        check(AdmissionBroker.acquire(path, "engine-b", "maintenance") == null, "served process rejected");
        System.out.println("AdmissionBroker harness passed");
    }
}
