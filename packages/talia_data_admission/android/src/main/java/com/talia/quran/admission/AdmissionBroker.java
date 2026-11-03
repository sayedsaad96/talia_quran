package com.talia.quran.admission;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.channels.FileChannel;
import java.nio.channels.FileLock;
import java.nio.channels.OverlappingFileLockException;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/** One process-wide broker, with a single OS lock shared by local readers. */
public final class AdmissionBroker {
    private static final Map<String, Holder> holders = new HashMap<>();
    private static FileChannel channel;
    private static RandomAccessFile file;
    private static FileLock lock;
    private static String lockPath;
    private static boolean servedProgress;

    private static final class Holder {
        final String engine;
        final String mode;
        Holder(String engine, String mode) { this.engine = engine; this.mode = mode; }
    }

    private AdmissionBroker() {}

    public static synchronized String acquire(File path, String engine, String mode) {
        if (engine == null || engine.isEmpty() || !validMode(mode)) return null;
        try {
            String canonical = path.getCanonicalPath();
            if (lockPath != null && !lockPath.equals(canonical)) return null;
            if (lock != null && !lock.isValid()) return null;
            boolean exclusive = mode.equals("maintenance");
            if (exclusive && (servedProgress || !holders.isEmpty())) return null;
            if (!exclusive && hasMaintenance()) return null;
            if (lock == null && !openLock(path, exclusive)) return null;
            String token = UUID.randomUUID().toString();
            holders.put(token, new Holder(engine, mode));
            if (mode.equals("foreground")) servedProgress = true;
            return token;
        } catch (IOException | SecurityException | OverlappingFileLockException e) {
            return null;
        }
    }

    private static boolean openLock(File path, boolean exclusive) throws IOException {
        RandomAccessFile candidate = new RandomAccessFile(path, "rw");
        FileChannel candidateChannel = candidate.getChannel();
        FileLock candidateLock = null;
        try {
            candidateLock = candidateChannel.tryLock(0, Long.MAX_VALUE, !exclusive);
            if (candidateLock == null || candidateLock.isShared() == exclusive) {
                if (candidateLock != null) candidateLock.release();
                candidate.close();
                return false;
            }
            file = candidate;
            channel = candidateChannel;
            lock = candidateLock;
            lockPath = path.getCanonicalPath();
            return true;
        } catch (IOException | RuntimeException e) {
            try { candidate.close(); } catch (IOException ignored) { }
            throw e;
        }
    }

    public static synchronized boolean validate(String token, String engine) {
        Holder holder = holders.get(token);
        return holder != null && holder.engine.equals(engine) && lock != null && lock.isValid();
    }

    public static synchronized boolean release(String token, String engine) {
        Holder holder = holders.get(token);
        if (holder == null || !holder.engine.equals(engine) || holder.mode.equals("foreground")) return false;
        if (lock == null || !lock.isValid()) return false;
        if (holders.size() == 1) {
            try {
                lock.release();
                channel.close();
                file.close();
                lock = null;
                channel = null;
                file = null;
            } catch (IOException e) {
                return false;
            }
        }
        holders.remove(token);
        return true;
    }

    private static boolean validMode(String mode) {
        return "probe".equals(mode) || "foreground".equals(mode) ||
               "worker".equals(mode) || "maintenance".equals(mode);
    }
    private static boolean hasMaintenance() {
        for (Holder holder : holders.values()) if (holder.mode.equals("maintenance")) return true;
        return false;
    }
}
