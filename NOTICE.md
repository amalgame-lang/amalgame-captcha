# NOTICE — amalgame-captcha

## Authorship

Copyright 2026 Bastien Mouget. The Amalgame facade code in this
repository is original work — see `facade.am` and the
`amalgame.toml` manifest.

This package is part of the Amalgame ecosystem
([github.com/amalgame-lang/Amalgame](https://github.com/amalgame-lang/Amalgame)).
Built for CMSPress's public contact form, extracted as a standalone
package for reuse across other Amalgame/Mosaic sites.

## License

Licensed under the Apache License, Version 2.0 — see `LICENSE`.

## Third-party content

None. The facade is 100% pure-Amalgame, built on top of
`amalgame-crypto` (HMAC-SHA-256) and `amalgame-random` (challenge
generation) — no vendored third-party code, no external service
(deliberately: this package exists specifically to avoid depending
on a third-party CAPTCHA provider such as Google reCAPTCHA).
