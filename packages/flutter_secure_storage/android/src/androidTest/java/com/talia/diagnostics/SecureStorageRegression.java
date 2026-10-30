package com.talia.diagnostics;

import android.app.Instrumentation;
import android.app.Activity;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.security.keystore.KeyInfo;
import android.util.Base64;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.security.Key;
import java.security.KeyFactory;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

/** Device-only regression for the actual installed plugin; fixture data is isolated. */
public final class SecureStorageRegression extends Instrumentation {
    private static final String PREFIX = "talia_secure_storage_test_";
    private static final String SENTINEL = "secure-storage-process-restart";

    @Override public void onCreate(Bundle args) {
        super.onCreate(args);
        String namespace = args.getString("namespace", "");
        String phase = args.getString("phase", "");
        Bundle result = new Bundle();
        try {
            if (!namespace.matches(PREFIX + "[0-9a-f]{32}")) throw new IllegalArgumentException("Invalid fixture namespace");
            Context context = getTargetContext();
            if ("cleanup".equals(phase)) {
                cleanup(context, namespace);
            } else if ("seed".equals(phase)) {
                seed(context, namespace);
            } else if ("verify".equals(phase)) {
                try { verify(context, namespace, result); } finally { cleanup(context, namespace); }
            } else {
                throw new IllegalArgumentException("Invalid phase");
            }
            result.putString("result", "PASS");
            finish(Activity.RESULT_OK, result);
        } catch (Throwable error) {
            result.putString("result", "FAIL " + error.getClass().getName());
            finish(Activity.RESULT_CANCELED, result);
        }
    }

    private static Object plugin(Context context, String namespace) throws Exception {
        ClassLoader loader = context.getClassLoader();
        Class<?> configClass = loader.loadClass("com.it_nomads.fluttersecurestorage.FlutterSecureStorageConfig");
        Map<String, Object> options = new HashMap<>();
        options.put("storageNamespace", namespace);
        Object config = configClass.getConstructor(Map.class).newInstance(options);
        Class<?> cipherClass = loader.loadClass("com.it_nomads.fluttersecurestorage.ciphers.KeyCipherImplementationRSAOAEP");
        Constructor<?> constructor = cipherClass.getDeclaredConstructor(Context.class, configClass);
        constructor.setAccessible(true);
        return constructor.newInstance(context, config);
    }

    private static Object invoke(Object cipher, String method, Class<?>[] types, Object... args) throws Exception {
        Method target = cipher.getClass().getDeclaredMethod(method, types);
        target.setAccessible(true);
        return target.invoke(cipher, args);
    }

    private static KeyStore keystore() throws Exception {
        KeyStore ks = KeyStore.getInstance("AndroidKeyStore");
        ks.load(null);
        return ks;
    }

    private static String alias(Context context, String namespace) {
        return context.getPackageName() + ".FlutterSecureStoragePluginKeyOAEP." + namespace;
    }

    private static void seed(Context context, String namespace) throws Exception {
        SharedPreferences prefs = context.getSharedPreferences(namespace, Context.MODE_PRIVATE);
        require(!keystore().containsAlias(alias(context, namespace)), "fixture alias already exists");
        byte[] beforeData = hashPrefs(context, "FlutterSecureStorage");
        byte[] beforeKeys = hashPrefs(context, "FlutterSecureKeyStorage");
        Object first = plugin(context, namespace);
        KeyStore ks = keystore();
        String keyAlias = alias(context, namespace);
        Key privateKey = ks.getKey(keyAlias, null);
        KeyInfo info = KeyFactory.getInstance(privateKey.getAlgorithm(), "AndroidKeyStore")
                .getKeySpec(privateKey, KeyInfo.class);
        require(info.getPurposes() == 2, "incorrect key purposes");
        byte[] publicKey = ks.getCertificate(keyAlias).getPublicKey().getEncoded();
        Object second = plugin(context, namespace);
        require(Arrays.equals(publicKey, keystore().getCertificate(keyAlias).getPublicKey().getEncoded()), "alias replaced");
        KeyGenerator generator = KeyGenerator.getInstance("AES");
        generator.init(256, new SecureRandom());
        SecretKey key = generator.generateKey();
        byte[] wrapped = (byte[]) invoke(first, "wrap", new Class<?>[]{Key.class}, key);
        Key unwrapped = (Key) invoke(second, "unwrap", new Class<?>[]{byte[].class, String.class}, wrapped, "AES");
        require(Arrays.equals(key.getEncoded(), unwrapped.getEncoded()), "roundtrip failed");
        Cipher gcm = Cipher.getInstance("AES/GCM/NoPadding");
        gcm.init(Cipher.ENCRYPT_MODE, key);
        byte[] encrypted = gcm.doFinal(SENTINEL.getBytes("UTF-8"));
        require(prefs.edit().putString("wrapped", encode(wrapped)).putString("iv", encode(gcm.getIV()))
                .putString("sentinel", encode(encrypted)).putString("dataHash", encode(beforeData))
                .putString("keyHash", encode(beforeKeys)).commit(), "fixture save failed");
    }

    private static void verify(Context context, String namespace, Bundle result) throws Exception {
        SharedPreferences prefs = context.getSharedPreferences(namespace, Context.MODE_PRIVATE);
        Object cipher = plugin(context, namespace);
        byte[] wrapped = decode(prefs.getString("wrapped", ""));
        Key key = (Key) invoke(cipher, "unwrap", new Class<?>[]{byte[].class, String.class}, wrapped, "AES");
        Cipher gcm = Cipher.getInstance("AES/GCM/NoPadding");
        gcm.init(Cipher.DECRYPT_MODE, key, new GCMParameterSpec(128, decode(prefs.getString("iv", ""))));
        require(SENTINEL.equals(new String(gcm.doFinal(decode(prefs.getString("sentinel", ""))), "UTF-8")), "sentinel mismatch");
        boolean dataUnchanged = Arrays.equals(decode(prefs.getString("dataHash", "")), hashPrefs(context, "FlutterSecureStorage"));
        boolean keysUnchanged = Arrays.equals(decode(prefs.getString("keyHash", "")), hashPrefs(context, "FlutterSecureKeyStorage"));
        result.putString("default_data_unchanged", Boolean.toString(dataUnchanged));
        result.putString("default_keys_unchanged", Boolean.toString(keysUnchanged));
        require(dataUnchanged && keysUnchanged, "default preferences changed");
    }

    private static byte[] hashPrefs(Context context, String name) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        Map<String, ?> values = new TreeMap<>(context.getSharedPreferences(name, Context.MODE_PRIVATE).getAll());
        for (Map.Entry<String, ?> entry : values.entrySet()) {
            digest.update(entry.getKey().getBytes("UTF-8"));
            digest.update((byte) 0);
            Object value = entry.getValue();
            String stable = value instanceof java.util.Set ? new java.util.TreeSet<>((java.util.Set<String>) value).toString() : String.valueOf(value);
            digest.update(stable.getBytes("UTF-8"));
            digest.update((byte) 0);
        }
        return digest.digest();
    }

    private static void cleanup(Context context, String namespace) throws Exception {
        keystore().deleteEntry(alias(context, namespace));
        context.deleteSharedPreferences(namespace);
    }

    private static void require(boolean condition, String message) { if (!condition) throw new AssertionError(message); }
    private static String encode(byte[] bytes) { return Base64.encodeToString(bytes, Base64.NO_WRAP); }
    private static byte[] decode(String value) { return Base64.decode(value, Base64.NO_WRAP); }
}
