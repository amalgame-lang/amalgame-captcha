/*
 * facade-stub.h — empty runtime header for the captcha facade.
 *
 * The package's API is implemented in `facade.am` (pure Amalgame,
 * no @c blocks of its own — HMAC/random are delegated to
 * amalgame-crypto/amalgame-random); this file exists only because
 * the manifest's `[stdlib].header` field is currently required by
 * PackageRegistry.LoadFrom in amc. The user binary's #include of
 * this header is a no-op.
 */
