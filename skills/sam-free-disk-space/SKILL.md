---
name: sam-free-disk-space
description: >-
  Diagnose what is filling macOS disk space and safely reclaim it — Docker build
  cache/images, Xcode DerivedData, accumulated iOS Simulator devices and runtimes,
  Cursor's bloated state.vscdb chat history, and Claude Desktop's sandbox VM bundle.
  Use when the machine feels slow, disk is nearly full, or the user asks what's
  eating storage / to clean up / to prune Docker, Xcode, simulators, Cursor, or Claude.
---

Find what's actually consuming disk, then reclaim it in order of safety: fully
regenerable caches first, then app-specific bloat that needs a quick confirm.
Never guess — measure before and after every step, and never touch something
without knowing what it is first.

## 1. Diagnose

```bash
df -h /                                   # overall free space
du -sh /Users/$USER/Library/* | sort -rh  # biggest top-level offenders
```

Drill into whatever is largest with `du -sh DIR/*/ | sort -rh` recursively —
don't assume the categories below are the only culprits; this machine's biggest
one (Cursor's state db) wasn't obvious from folder size alone; find it by
following where the bytes actually are, then adjust the categories below.

Commonly the big four are, in `~/Library`:
- `Developer/CoreSimulator/Devices` + `Developer/Xcode` — stale simulators/builds
- `Containers/com.docker.docker` — Docker VM disk (images + build cache)
- `Application Support/Cursor/User/globalStorage/state.vscdb` — chat/agent history bloat
- `Application Support/Claude/vm_bundles` — code-sandbox VM image

## 2. Docker — safe, no confirmation needed

Reclaimable build cache and dangling/untagged images never affect running
containers or volumes. Check first, then prune:

```bash
docker ps -a                    # confirm what's actually in use
docker system df                # see reclaimable amounts
docker builder prune -af        # build cache — always safe
docker image prune -a -f        # only removes images with zero containers (running or stopped)
```

Do **not** run `docker container prune` or `docker volume prune` without
checking each one by hand — stopped containers are often intentional
(compose init/preflight steps) and volumes hold real data. Skip unless asked.

## 3. Xcode + iOS Simulators — safe, no confirmation needed

DerivedData always regenerates on next build:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

Simulators and runtimes accumulate one full copy per Xcode/iOS update
(~8GB per runtime). To keep only the newest:

```bash
xcrun simctl list devices -j          # devices grouped by runtime identifier
xcrun simctl runtime list -j          # installed runtime images with sizes + identifiers
```

Identify the latest runtime identifier (highest iOS version), then:
1. `xcrun simctl delete <udid>` for every device on a non-latest runtime.
2. `xcrun simctl runtime delete <identifier>` for every non-latest runtime image.
   This is **async** — it reports "Deleting" in `runtime list` for a bit; poll
   until only the latest remains before reporting space freed.
3. Trim `~/Library/Developer/Xcode/iOS DeviceSupport/` to the newest build only
   (`ls -la` it, `rm -rf` the older-dated folders).

## 4. Cursor — confirm before quitting the app

Cursor's `state.vscdb` grows unbounded because the `cursorDiskKV` table never
prunes old chat/agent messages (`bubbleId:*` keys). Confirm the size first:

```bash
sqlite3 "$DB" "SELECT name, sum(pgsize) FROM dbstat GROUP BY name ORDER BY 2 DESC;"
```
(`DB=~/Library/Application Support/Cursor/User/globalStorage/state.vscdb`)

If `cursorDiskKV` dominates, ask the user before quitting Cursor (it's a live
app they may be mid-session in). Once confirmed:

```bash
osascript -e 'tell application "Cursor" to quit'
# poll `pgrep -x Cursor` until it exits
rm -f "$DB" "$DB.backup" "$DB-wal" "$DB-shm"
open -a "Cursor"
```

`settings.json` and `keybindings.json` live in separate files in the same
`User/` folder and are untouched — only chat/composer history and UI cache
are lost. Verify they still exist after, and confirm Cursor relaunches clean.

## 5. Claude Desktop — confirm before deleting

`~/Library/Application Support/Claude/vm_bundles/claudevm.bundle` is the local
code-execution sandbox VM (often ~12GB: a `rootfs.img` plus a compressed
backup). It rebuilds automatically next time that feature runs, but deleting
it means a rebuild delay on next use — ask the user first, don't assume they
want it gone just because it's large. Check `pgrep -x Claude` is empty (or ask
them to quit it) before deleting, since it's live app state.

## 6. Verify

```bash
df -h /
```

Report a before/after table per category (what was found, what was freed) —
not just a final total. The point is the user understands what was eating
space, not just that space came back.
