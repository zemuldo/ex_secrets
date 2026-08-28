# Changelog

## 0.4.0

### Changed

- **Widened the HTTPoison requirement to `~> 1.8 or ~> 2.0 or ~> 3.0`.**
  HTTPoison 3.0 is the first release to require hackney 4.x, and hackney 1.x
  carries four open advisories — an SSRF allowlist bypass in
  `hackney_url:normalize/2`, CR/LF injection via query parameters and via an
  unvalidated `domain`, and a missing timeout on the `ssl:connect/2`
  post-handshake upgrade. Pinning `~> 1.8` held every application depending on
  this library on the vulnerable line, whether or not it used a remote provider.

  The range spans all three majors: the surface used here (`HTTPoison.get/3`,
  `post/4`, `%HTTPoison.Response{}`) is unchanged across them, so existing
  consumers need no change and new ones can resolve hackney 4.x.

### Fixed

- `ExSecrets.Providers.DotEnv` raised twice when `.env` was missing
  (`raise(raise(...))`), so the error surfaced was an `ArgumentError` about the
  exception struct rather than the intended `InvalidConfiguration`.
