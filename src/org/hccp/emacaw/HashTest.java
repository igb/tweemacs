package org.hccp.emacaw;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.UnsupportedEncodingException;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;

public class HashTest {

    public static void main(String[] args) throws NoSuchAlgorithmException, InvalidKeyException, UnsupportedEncodingException {

        String key1  = "keykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykeykey";
        String key2 = "0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33MGJlZWM3YjVlYTNmMGZkYmM5NWQwZGQ0N2YzYzViYzI3NWRhOGEzMw==";
        String key3 = "key";
        String key4 = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx";
        String key5 = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxX";



        String message = "The quick brown fox jumps over the lazy dog";

        String key = key2;



        SecretKeySpec signingKey = new SecretKeySpec(key.getBytes(), "HmacSHA1");


        Mac mac = Mac.getInstance("HmacSHA1");
        mac.init(signingKey);

        byte[] macBytes = mac.doFinal(message.getBytes());
        String base64Mac = toBase64(macBytes);
        String hexMac = toHex(macBytes);

        System.out.println("Base64 MAC = " + base64Mac);
        System.out.println("Hex MAC = " + hexMac);

        byte[] hmac = myMac(key,message);
        System.out.println("HMAC: " + toHex( hmac));


        System.out.println("hashtest = " + toHex(hash("The quick brown fox jumps over the lazy dogThe quick brown fox jumps over the lazy dogThe quick brown fox jumps over the lazy dog".getBytes())));


        System.out.println(toHex(Base64.getDecoder().decode("tnnArxj06cWHq44gCs1OSKk/jLY=")));
    }


    public static byte[] myMac(String key, String message) throws NoSuchAlgorithmException {
        int blockSize = 64;

        byte[] keyBytes = key.getBytes();
        byte[] messageBytes = message.getBytes();

        if (keyBytes.length > blockSize) {
            keyBytes = hash(keyBytes);
            System.out.println("toHex(keyBytes) = " + toHex(keyBytes));
            System.out.println("truncated key forst byte " + (keyBytes[0]));
        }

        System.out.println("\257".getBytes()[0]);

        if (keyBytes.length < blockSize) {
            byte[] newArray = new byte[blockSize];
            for (int i = 0; i < keyBytes.length; i++) {
                byte keyByte = keyBytes[i];
                newArray[i] = keyByte;
            }
            keyBytes = newArray;
        }

        System.out.println("key = " + toBase64(keyBytes));
        byte[] oKeyPad = new byte[blockSize];

        for (int i = 0; i < keyBytes.length; i++) {
            byte keyByte = keyBytes[i];
            oKeyPad[i] = (byte)(keyByte ^ 0x5c);
        }

        byte[] iKeyPad = new byte[blockSize];

        for (int i = 0; i < keyBytes.length; i++) {
            byte keyByte = keyBytes[i];
            iKeyPad[i] = (byte)(keyByte ^ 0x36);
        }


        System.out.println("iKeyPad length  = " + iKeyPad.length);

        System.out.println("oKeyPad = " + toBase64( oKeyPad));
        System.out.println("iKeyPad = " + toBase64(      iKeyPad));

        byte[] innerConcatenatedValue = concatenate(iKeyPad, messageBytes);

        System.out.println("innerConcatenatedValue");
        for (int i = 0; i < innerConcatenatedValue.length; i++) {
            byte b = innerConcatenatedValue[i];
            System.out.print((byte) b);
            System.out.print(" ");

        }
        System.out.println("");

        System.out.println("innerConcatenatedValue = " + toBase64(innerConcatenatedValue));
        System.out.println("innerConcatenatedValue.length = " + innerConcatenatedValue.length);
        byte[] innerHash = hash(innerConcatenatedValue);

        System.out.println("Base64 innerHash = " + toBase64(innerHash));
        System.out.println("hex innerHash = " + toHex(innerHash));

        byte[] hash = hash(concatenate(oKeyPad, innerHash));
        return hash;




    }

    private static byte[] concatenate(byte[] a, byte[] b) {
        byte[] c = new byte[a.length + b.length];
        for (int i = 0; i < a.length; i++) {
            byte abyte = a[i];
            c[i] = abyte;
        }
        for (int i = 0; i < b.length; i++) {
            byte bbyte = b[i];
            c[a.length + i] = bbyte;
        }

        return c;
    }

    private static byte[] hash(byte[] keyBytes) throws NoSuchAlgorithmException {
        return MessageDigest.getInstance("sha1").digest(keyBytes);
    }

    private static String toBase64(byte[] hashBytes) {
        return Base64.getEncoder().encodeToString(hashBytes);
    }

    private static String toHex(byte[] hashBytes) {
        StringBuffer sb = new StringBuffer();
        for (int i = 0; i < hashBytes.length; i++) {
            byte hashByte = hashBytes[i];
            sb.append(String.format("%02x", hashByte));
        }
        return sb.toString();
    }
}
