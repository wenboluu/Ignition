# Ignition (🔥+🪵=🗽)

SSH to NYU Torch (HPC) in one command, then reuse that connection from your terminal and IDE for hours—without doing Microsoft device-code auth again.

**Two goals:**

1. **Get through Microsoft auth once.** The HPC login node requires the Microsoft device-code flow (open a URL, enter a PIN). This script automates that, making the first connection effortless.
2. **Keep one SSH connection alive and reuse it.** We set up a *persisting* underlying SSH connection (via `ControlMaster` / `ControlPersist` in your SSH config). For a long time afterward, every new session—another terminal, VS Code Remote, etc.—reuses that same connection. No separate auth run, no extra PIN. That’s why the config below is involved.

## Platforms

- [x] macOS
- [ ] Linux
- [ ] Windows

Fully supported on macOS, but Linux and Windows are untested. Any help with testing on Linux and Windows would be appreciated.

## Prerequisites

- **Expect** — `brew install expect` (macOS) or your distro’s `expect` package (Linux). On Windows you’d need Expect for Windows or WSL.
- **SSH** — Standard OpenSSH client.
- **Platform (for paste + Enter):**
  - **macOS:** built-in (no extra install).
  - **Linux:** `xdotool` (X11) or `ydotool` (Wayland) for sending keys to the browser.
  - **Windows:** PowerShell (built-in).

## 1. SSH config

The config below does two things: it defines the *torch* hpc host, and it turns on **connection sharing**. That way, after you run `ignite` once, every other SSH connection to the same host (terminal, VS Code, Cursor, etc.) reuses the same authenticated session—no extra auth. The extra options are what make that persistence work.

Create the control socket directory, then add the block:

```bash
mkdir -p ~/.ssh/cm
```

Then add (adjust `User` to your NYU NetID):

```
Host torch
  Hostname login.torch.hpc.nyu.edu
  User YOUR_NETID
  StrictHostKeyChecking no
  ServerAliveInterval 60
  ForwardAgent yes
  UserKnownHostsFile /dev/null
  LogLevel ERROR
  # Reuse one authenticated connection for all sessions
  ControlMaster auto
  ControlPersist 8h
  ControlPath ~/.ssh/cm/%C
  ServerAliveInterval 60
  ServerAliveCountMax 3
```

- Replace `YOUR_NETID` with your Torch username (e.g. `yl22`).

**What those options do (briefly):**

| Option | Purpose |
|--------|--------|
| `ControlMaster auto` | Reuse an existing SSH connection when you run `ssh torch` again instead of opening a new one. |
| `ControlPersist 8h` | Keep the shared connection alive for 8 hours after the last session, so later logins skip device auth. |
| `ControlPath ~/.ssh/cm/%C` | Path for the connection socket; `%C` is a hash so each host gets its own socket under `~/.ssh/cm/`. |
| `ServerAliveInterval 60` | Send a keep-alive every 60 seconds so the connection isn’t dropped by firewalls when idle. |
| `ServerAliveCountMax 3` | After 3 unanswered keep-alives, treat the connection as dead and disconnect. |

## 2. Run

### 2.1 Make the script executable:
Once, from this repo’s directory
```bash
cd path/to/ignite
chmod +x ignite
```

### 2.1.5 Optional — run `ignite` from anywhere:

**Option A — Add this directory to PATH** (if the repo is e.g. `~/bin`):

```bash
# In ~/.zshrc or ~/.bashrc
export PATH="$PATH:$HOME/bin"
```

Then reload your shell (`source ~/.zshrc` or open a new terminal). You can run `ignite` from any directory.

**Option B — Symlink into a directory already on PATH** (e.g. `/usr/local/bin`):

```bash
ln -sf "$(pwd)/ignite" /usr/local/bin/ignite
```

(Use the full path to this repo if you’re not in it.) Then `ignite` is available everywhere.

### 2.2 Run `ignite`:

```bash
ignite
```

(From this directory, or from any directory if you added it to PATH.)

**What happens:**

1. SSH starts to **torch**.
2. On “Authenticate with PIN …”, the script opens the login URL and copies the PIN to the clipboard.
3. ~1s later it sends **Paste** + **3× Enter** to the focused window — focus the browser first.
4. After `browser_auth_wait` seconds (default 4), it sends **Enter** to SSH and hands control to you.

### 2.3 Verbosity:
- `quiet` or `q` (only errors and outcome)
- `verbose` or `v` (default)
- `vv` (very verbose)

**Examples:**
```bash
ignite quiet
ignite vv
```

(Options use words like `quiet` instead of `-q` because Expect treats leading dashes as its own flags.)


## 3. Using the connection from VS Code / Cursor

Once you’ve run `ignite` and the connection is up, that same connection is reused by anything that uses your SSH config.

- **VS Code / Cursor Remote-SSH:** Use “Connect to Host…” (or the Remote Explorer) and choose **torch** (the same host name from your config). They will use the existing connection; you won’t be prompted for device auth again until the connection expires (e.g. after 8 hours or a reboot).
- **Another terminal:** Run `ssh torch` (or `ssh torch` and then your usual commands). Same underlying connection.
- **Other tools:** Anything that uses `ssh torch` (e.g. `rsync`, `scp`, Git over SSH) will also reuse the connection as long as it’s still alive.

So: run `ignite` once to get through Microsoft auth and establish the persistent connection; then use **torch** as the host everywhere. The “cumbersome” config is what makes this possible.

## 4. Tuning

1. **Delay before sending Enter to SSH:** Change `set browser_auth_wait 4` (near the top) to the number of seconds you generally need to finish login in the browser (e.g., set it to `10` if you often need more time).
2. **Delay between opening the URL and simulating Paste:** Change `set paste_delay 1` (default is 1 second) if you want to make the script paste the PIN sooner or give yourself more time to switch focus to your browser.
3. **Interval between each simulated Enter after Paste:** Change `set press_enter_interval 0.15` (default is 0.15 seconds) to adjust how quickly each Enter key press is sent after pasting.

All these settings appear near the top of `ignite`. Adjust them if you want to make the flow faster or slower for your own pace.

## Notes

- The script uses your **default browser** and simulates Paste + Enter; it does not install or drive a separate browser.
- First run may prompt you to accept the host key; with the config above, later runs reuse the same connection while it’s alive.
