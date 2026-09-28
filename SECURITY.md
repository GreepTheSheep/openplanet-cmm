# Security Policy

## Supported versions

Only the latest version of the Community Matchmaking plugin published on [Openplanet](https://openplanet.dev/plugin/cmm) is supported.
Older releases, modified builds and forks are not supported.

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Report vulnerabilities privately through [GitHub Security Advisories](https://github.com/GreepTheSheep/openplanet-cmm/security/advisories/new).

Include as much of the following as possible:

- A description of the vulnerability and its impact
- The plugin version (copy the build info via the version number at the bottom right of the CMM window)
- Steps to reproduce, including a proof of concept if available
- Any suggested fix or mitigation

You should receive an acknowledgement within **72 hours**.
Please allow time for a fix to be developed and released before any public disclosure.

## Scope

In scope:

- The plugin source (`src/`): UI, authentication, socket and API layers, models
- The backend API and the server controller

Out of scope:

- Openplanet itself and the Trackmania client — report those upstream
- Modified, repackaged or unofficial builds downloaded outside of the official Openplanet plugin page

## How the plugin handles your account

The plugin authenticates you using your Openplanet token via [its Auth API](https://openplanet.dev/docs/reference/auth).
That token is the credential used to talk to the CMM backend:

- It is held in memory in `Auth::AccountToken` for the duration of the session and is **never persisted to disk** by the plugin.
- It is sent as a `Bearer` token in the `Authorization` header of every request made to the configured base URL (`src/Utils/API.as`).
- It is logged in clear text **only when Openplanet Developer signature is active** (`src/Utils/Auth.as`).
  **__Do not share Openplanet logs taken from a Developer-mode session with anyone you do not trust.__**
- It is sent once over the TCP socket as the connection header (`src/Utils/Socket.as`).
  Sockets are TLS-encrypted when the base URL is `https://`.

### Base URL

The plugin talks to `Setting_BaseURL` (production: `https://tm-communitymatchmaking-api.greep.fr`).
On release builds this value is fixed.

It can only be changed in Developer mode or builds compiled with the `CMM_ALLOW_CHANGE_SETTINGS` or `CMM_DEV_BUILD` defines (see `src/Settings/Advanced.as`).

Changing the base URL points your session token at another server.
Only change it if you host your own backend or trust the operator.
A define (`CMM_DISALLOW_SOCKETS`) exists to disable the TCP socket entirely and rely on HTTP polling only.

## Handling secrets

No credential (Openplanet secret, backend token, database or registry password)
should ever be committed to this repository. The plugin contains no embedded
secret: authentication always relies on your own Openplanet token.

If you find a committed secret, treat it as compromised and report it privately as described above.

## Security measures in place

- Openplanet JWT tokens are validated server-side against the Openplanet API.
- Requests to a URL outside the configured base URL do not carry the authorization header.
- The TCP socket is bound to your account by your session token, one socket per account (newest wins).
- All socket messages are parsed defensively; malformed data is ignored.