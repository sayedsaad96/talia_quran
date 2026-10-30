# Local patch

Based on `flutter_secure_storage` 11.2.0 from pub.dev, under the included upstream LICENSE. The upstream package's workspace resolution is omitted so this standalone path dependency can resolve in Talia.

New Android RSA-OAEP keys request only the private-key decrypt purpose: some Keymaster implementations otherwise create an encrypt-only key that cannot unwrap stored keys. Public-key wrapping, existing aliases, and ciphertext formats remain unchanged. Existing unusable keys and ciphertext are not recovered by this patch.

Remove this fork when an upstream release includes a compatible fix and the application's existing data and supported Android devices have been verified against it.
