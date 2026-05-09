# `ignite-sh` — password + Duo SSH

Sibling of `ignite` for any HPC that uses **password + Duo push** (no Microsoft device-code flow). Tested against NYU Shanghai HPC, but the flow is generic — point it at any host where you'd otherwise type a password and tap a Duo notification.

## Setup (once)

**1. SSH config** — add to `~/.ssh/config` (replace `YOUR_NETID`; `nyushhpc` can be any alias):

```
Host nyushhpc
  HostName hpclogin.shanghai.nyu.edu
  User YOUR_NETID
  PubkeyAuthentication no
  PreferredAuthentications keyboard-interactive,password
  ControlMaster auto
  ControlPersist 14d
  ControlPath ~/.ssh/cm/%C
  ServerAliveInterval 60
```

```bash
mkdir -p ~/.ssh/cm
```

**2. Install** (from this repo):

```bash
chmod +x ignite-sh
sudo ln -sf "$(pwd)/ignite-sh" /usr/local/bin/ignite-sh
```

**3. Store password in macOS Keychain** (service name = `ignite-<alias>`):

```bash
security add-generic-password -a YOUR_NETID -s ignite-nyushhpc -w
```

## Use

```bash
ignite-sh           # auth once → tap Duo on phone → done for 14 days
ssh nyushhpc        # no password, no Duo
```

Works the same in VS Code / Cursor Remote-SSH, `rsync`, `scp`, etc. — anything that resolves the `nyushhpc` alias reuses the master.

Verbosity: `ignite-sh quiet` | `ignite-sh` | `ignite-sh vv` (debug).

## Any other host

`ignite-sh <alias>` works for any password + Duo host. The script reads the user from `ssh -G <alias>` and looks up `ignite-<alias>` in Keychain.

Example — NCSA Delta (`dtai-login.delta.ncsa.illinois.edu`):

```
Host dtai
  HostName dtai-login.delta.ncsa.illinois.edu
  User <USER_ID>
  PubkeyAuthentication no
  PreferredAuthentications keyboard-interactive,password
  ControlMaster auto
  ControlPersist 14d
  ControlPath ~/.ssh/cm/%C
  ServerAliveInterval 60
```

```bash
security add-generic-password -a yxu21 -s ignite-dtai -w
ignite-sh dtai
```

Then `ssh dtai` reuses the master, same as `nyushhpc`.
