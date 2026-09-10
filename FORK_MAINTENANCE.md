# Haemoglobin Launcher — fork maintenance

This repo is a fork of [PrismLauncher](https://github.com/PrismLauncher/PrismLauncher) (`develop` branch).

Goal: pull Prism updates regularly **without losing** Haemoglobin customizations.

## Branch model (important)

- `develop` — **pristine mirror of upstream.** Never commit custom code here.
  - Tracks `upstream/develop` (PrismLauncher).
  - Only operation: `git fetch upstream` + fast-forward merge.
- `main` — **Haemoglobin Launcher.** All your edits live here.
  - Branched from `develop`.
  - This should be the Default branch on GitHub.

Why this works: Git `merge` never silently overwrites. When you merge `develop` into `main`,
Git keeps both sides. Only when upstream touched the *exact same lines* you edited do you
get a conflict, which you resolve once manually.

```
upstream/develop (Prism)
      |
      v
local develop (pristine, fast-forward only)
      |
      +--merge--> main (Haemoglobin custom + Prism updates)
```

## Yes, make a GitHub fork

You need a GitHub fork for the auto-sync Action + sharing builds:

1. Go to https://github.com/PrismLauncher/PrismLauncher and click **Fork**.
   - Owner: `rubixus`
   - Repo name: `Haemoglobin-Launcher` (recommended — matches this branding)
   - Uncheck "Copy the `develop` branch only" if you want all branches, or leave checked.
   - Click Create.
2. Then in this folder, point `origin` at your fork (replace if different name):

```powershell
& "C:\Program Files\Git\cmd\git.exe" remote add origin https://github.com/rubixus/Haemoglobin-Launcher.git
& "C:\Program Files\Git\cmd\git.exe" push -u origin develop main
```

`upstream` already points to PrismLauncher:
```
upstream  https://github.com/PrismLauncher/PrismLauncher.git
```

3. On github.com/rubixus/Haemoglobin-Launcher → Settings → General → Default branch → set to `main`.
4. Authenticate `gh` once (needed for fork/PR commands):
```powershell
gh auth login
```

## Daily sync (automatic)

`.github/workflows/sync-upstream.yml` runs daily + on-demand:

- Fetches `upstream/develop`
- Fast-forwards local `develop`
- Merges `develop` into `main`
- Pushes if clean. If conflict → opens a PR `sync/upstream-develop` for you to resolve, **never force-pushes over your edits**.

Run manually: Actions tab → "Sync upstream" → Run workflow.

## Manual sync (local)

```powershell
# from repo root:
.\scripts\Sync-Upstream.ps1
# or with push:
.\scripts\Sync-Upstream.ps1 -Push
```

What the script does:
1. `git fetch upstream --prune`
2. `develop`: merge `upstream/develop` (fast-forward only — fails if you accidentally committed to develop, which is intentional)
3. `main`: merge `develop` (preserves your edits, may report conflicts)
4. `git submodule update --init --recursive`
5. Optionally push both branches.

If conflicts:
```powershell
& "C:\Program Files\Git\cmd\git.exe" status
# edit conflicted files, then:
& "C:\Program Files\Git\cmd\git.exe" add <files>
& "C:\Program Files\Git\cmd\git.exe" commit
```

## Where to put customizations (to minimize conflicts)

Safe (new files, almost never conflict):
- `custom/` — your branding, docs, scripts
- `scripts/` — your tooling
- `.github/workflows/sync-upstream.yml` — this file (unique name)

Low-risk (touched rarely by upstream):
- `program_info/CMakeLists.txt` — DisplayName, Domain, Git, ENVName (we already branded these)
- `CMakeLists.txt` — `Launcher_UPDATER_GITHUB_REPO`, `Launcher_BUG_TRACKER_URL`, API keys (emptied per Prism policy)

High-risk (upstream changes often — avoid unless needed):
- `launcher/*` UI/logic, `libraries/*`, `cmake/*`, `.github/workflows/build.yml`

Rule: keep upstream edits in small, commented blocks like:
```cmake
# HAEMOGLOBIN: <reason>
...
# END HAEMOGLOBIN
```
This makes conflict resolution trivial.

## Prism fork policy (you must follow)

From Prism README:
- Make clear your fork is not Prism Launcher and not endorsed by them.
- Change API keys in `CMakeLists.txt` to your own or `""`. We already emptied MSA + CurseForge.
  CurseForge explicitly requires a new key for derivative work — get one if you want CurseForge support.
- If you build without removing keys you accept Microsoft + CurseForge ToS.

## Full rebrand (AppID + binary rename) — deferred intentionally

We kept `Launcher_APP_BINARY_NAME=prismlauncher` and `AppID=org.prismlauncher.PrismLauncher` for now
because `program_info/` file lookups (`*.ico`, `*.qrc.in`, `*.desktop.in`, `*.svg`) use those names.
Renaming requires duplicating assets:
- `prismlauncher.ico` → `haemoglobinlauncher.ico`, etc.
- `org.prismlauncher.PrismLauncher.*` → `org.haemoglobin.HaemoglobinLauncher.*`
Do that as a separate commit when you have icons ready. UI already shows "Haemoglobin Launcher".
