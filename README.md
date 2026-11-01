# PCL CE — Local Build

Documentation and build tooling for a **personal, locally compiled** build of
[Plain Craft Launcher Community Edition (PCL CE)](https://github.com/PCL-Community/PCL-CE),
an open-source launcher for Minecraft: Java Edition.

> This repository is not affiliated with, endorsed by, or distributed on behalf of the
> upstream PCL CE project, Mojang Studios, or Microsoft. It documents a personal build
> and the build steps required to reproduce it.

---

## Purpose

The launcher is compiled locally from the upstream source tree. This repository contains
only the build script and the technical documentation needed for the Microsoft application
registration used by that build. No launcher binaries are distributed here.

## Microsoft account sign-in

The launcher authenticates Microsoft accounts exclusively through the OAuth 2.0
**device code flow**, registered as a public client:

| Step | Endpoint | Purpose |
| --- | --- | --- |
| 1 | `login.microsoftonline.com/consumers/oauth2/v2.0/devicecode` | Request a device code and user code |
| 2 | `login.microsoftonline.com/consumers/oauth2/v2.0/token` | Poll for the access token after the user signs in |
| 3 | `user.auth.xboxlive.com/user/authenticate` | Exchange the Microsoft token for an Xbox Live token |
| 4 | `xsts.auth.xboxlive.com/xsts/authorize` | Authorize against the Minecraft relying party |
| 5 | `api.minecraftservices.com/authentication/login_with_xbox` | Exchange the XSTS token for a Minecraft token |
| 6 | `api.minecraftservices.com/entitlements/mcstore` | Verify game ownership before launching |
| 7 | `api.minecraftservices.com/minecraft/profile` | Retrieve UUID, name and skin |

Game ownership is verified on every launch. An account without a valid entitlement
cannot start a game instance.

## Application registration

| Setting | Value |
| --- | --- |
| Client type | Public client (device code flow) |
| Client secret | None issued or stored |
| Redirect URI | None (not used by the device code flow) |
| Scopes | `XboxLive.signin`, `offline_access` |
| Account type | Personal Microsoft accounts |

## Security posture

- The application never handles the user's Microsoft password. Sign-in and consent
  always happen in the user's own browser on Microsoft-hosted pages.
- No client secret is embedded in or shipped with the build.
- Access and refresh tokens are persisted only in the local configuration file on the
  user's own machine, and are sent only to Microsoft and Mojang endpoints.
- No authentication data is transmitted to any server operated by the author.
- No telemetry containing account identifiers is collected.

## Building

Requirements: Windows 10 or later, [.NET 10 SDK](https://dotnet.microsoft.com/download).

```powershell
# Build Release for x64
.\build.ps1 -Configuration Release -Platform x64

# Optionally inject the Microsoft OAuth client ID at build time
.\build.ps1 -Configuration Release -MsClientId "<your-client-id>"
```

The build script sets the `PCL_WRITE_SECRET` / `PCL_MS_CLIENT_ID` environment variables
consumed by the source generator in `PCL.Core.SourceGenerators`, then invokes
`dotnet build` on the solution.

Output: `Plain Craft Launcher 2\bin\<Configuration>\net10.0-windows\`

## License

The launcher source is distributed under its own terms: `Plain Craft Launcher 2/` uses a
[custom license](https://github.com/PCL-Community/PCL-CE/blob/dev/Plain%20Craft%20Launcher%202/LICENCE),
all other directories use Apache License 2.0. This repository contains no launcher source
code and grants no rights beyond those of the upstream project.

## Disclaimer

Minecraft is a trademark of Mojang Synergies AB. This is not an official Minecraft product,
and it is not approved by or associated with Mojang or Microsoft.
