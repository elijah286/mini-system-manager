# LabVIEW CI/CD Pipeline Setup — AI Assistant Prompt

You are helping a user set up a CI/CD pipeline for a LabVIEW project using GitHub Actions and the `nationalinstruments/labview` Docker container. This pipeline will run headless LabVIEW operations inside Windows containers on GitHub-hosted runners.

---

## Before you begin — ask the user these questions

Before generating any files, ask the user the following questions to tailor the pipeline to their project:

1. **Repository info**: What is the GitHub repository URL? (needed for Pages URLs and API calls)
2. **Branch strategy**: What is the main/default branch name? (e.g., `main`, `master`, `develop`)
3. **LabVIEW file types**: Does the project use `.vi`, `.ctl`, `.lvproj`, `.lvlib`, `.lvclass`, or other LabVIEW file types? Which should be tracked by CI?
4. **Which CI stages do you want?**
   - **Mass Compile** — compiles all VIs to catch broken dependencies
   - **VI Analyzer** — runs static analysis tests against configurable rules
   - **VIDiff** — generates visual comparison reports showing what changed in each VI between commits
5. **VI Analyzer rules**: Do you have a preferred set of VI Analyzer tests, or should we start with a default set? (Broken VI, Separate Compiled Code, Platform Portability, Toolkit Usage, Error Cluster Wired)
6. **Report hosting**: Do you want HTML reports published to GitHub Pages so they're viewable in a browser? (Recommended)
7. **Commit status links**: Do you want clickable "Details" links on each commit in the GitHub UI that go directly to the reports? (Recommended)
8. **PR comments**: For VIDiff, do you want the bot to automatically comment on pull requests with links to the diff reports?
9. **Retroactive analysis**: Do you want to run the pipeline against historical commits to build up a history of reports? If so, how far back?

---

## Critical requirements and lessons learned

### Runner selection — MUST use `windows-2022`

```yaml
runs-on: windows-2022   # DO NOT use windows-latest
```

**`windows-latest` resolves to Windows Server 2025, which has a broken Docker daemon.** Docker commands will fail with:

```
failed to connect to the docker API at npipe:////./pipe/docker_engine;
check if the path is correct and if the daemon is running
```

Always pin to `windows-2022` explicitly.

### Container image

```yaml
env:
  LABVIEW_CONTAINER_IMAGE: nationalinstruments/labview:latest-windows
```

This is the official NI container with LabVIEW and LabVIEWCLI pre-installed. The workspace is mounted into the container at `C:\workspace`.

### Volume mounting

The GitHub Actions workspace is mounted into the container:

```yaml
docker run --rm -v "${{ github.workspace }}:C:\workspace" ${{ env.LABVIEW_CONTAINER_IMAGE }} ...
```

All paths inside the container must use `C:\workspace` as the root, not relative paths. **Relative paths like `"."` will resolve to LabVIEW's internal working directory, not your project files.**

### VI Analyzer configuration — use absolute container paths

In the `.viancfg` config file, the `<Path>` element must use the absolute container mount point:

```xml
<ItemsToAnalyze>
  <Item>
    <Path>"C:\workspace"</Path>
    <Removed>FALSE</Removed>
  </Item>
</ItemsToAnalyze>
```

**Do NOT use `"."` or any relative path** — VI Analyzer will find 0 VIs to analyze.

### Retroactive runs — restore CI scripts from main

When running against historical commits (via `workflow_dispatch` with a `commit_sha` input), those old commits won't contain the `.github/labview/` scripts. After checking out the historical commit, restore the CI scripts:

```yaml
- name: Restore CI scripts from main
  if: github.event.inputs.commit_sha != ''
  shell: bash
  run: git checkout origin/main -- .github/labview .github/workflows
```

This requires `fetch-depth: 0` on the checkout step so `origin/main` is available.

### GitHub Pages setup

1. Pages must be enabled on the repository, configured to deploy from the `gh-pages` branch
2. Enable via Settings → Pages, or via API:
   ```bash
   gh api repos/OWNER/REPO/pages -X POST -f build_type=legacy -f source='{"branch":"gh-pages","path":"/"}'
   ```
3. Use `peaceiris/actions-gh-pages@v4` with `keep_files: true` to accumulate reports over time
4. Reports are accessible at `https://OWNER.github.io/REPO/`

### Commit status links

Use the GitHub Statuses API to post clickable "Details" links on commits:

```bash
curl -s -X POST \
  -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${{ github.repository }}/statuses/${COMMIT_SHA}" \
  -d '{"state":"success","target_url":"REPORT_URL","description":"View report","context":"Report Name"}'
```

Requires `statuses: write` permission on the workflow.

---

## Pipeline architecture

The pipeline consists of **4 workflow files** and **3 PowerShell scripts**:

### Workflow files (`.github/workflows/`)

| File | Purpose | Triggers | Runner |
|---|---|---|---|
| `masscompile-windows-container.yml` | Compile all VIs to catch broken dependencies | PR, push to main, manual | `windows-2022` |
| `run-vi-analyzer-windows-container.yml` | Run static analysis, deploy HTML report to Pages, post commit status | PR, push to main, manual (with optional `commit_sha`) | `windows-2022` |
| `vidiff-windows-container.yml` | Generate VIDiff comparison reports for changed VIs | PR, push to main, manual (with `base_sha`/`head_sha`) | `windows-2022` |
| `vidiff-deploy.yml` | Deploy VIDiff reports to Pages, comment on PRs, post commit status | Triggered by `workflow_run` completion of VIDiff | `ubuntu-latest` |

### PowerShell scripts (`.github/labview/`)

| File | Purpose | LabVIEWCLI Operation |
|---|---|---|
| `masscompile.ps1` | Mass compile all VIs in workspace | `MassCompile` |
| `run-vi-analyzer.ps1` | Run VI Analyzer with config file | `RunVIAnalyzer` |
| `vidiff.ps1` | Generate diff reports for modified/added/deleted VIs | `CreateComparisonReport`, `PrintToSingleFileHtml` |

### Config files

| File | Purpose |
|---|---|
| `.github/labview/via-configs/via-config-default.viancfg` | VI Analyzer test configuration (which rules to run) |

---

## File-by-file implementation

### 1. Mass Compile workflow

**Purpose**: Compiles every VI in the repository to catch broken subVI references, missing dependencies, and compile errors.

**Key details**:
- Triggers on PRs and pushes that change LabVIEW files
- Uses path filters to avoid unnecessary runs on non-VI changes
- Simple pass/fail — no report deployment needed (failures show in the action log)

### 2. VI Analyzer workflow

**Purpose**: Runs configurable static analysis tests and publishes an HTML report to GitHub Pages.

**Key details**:
- Deploys report directly to Pages (no separate deploy workflow needed since it's a single file)
- Posts a commit status with a clickable link to the report
- Supports `commit_sha` input for retroactive analysis of historical commits
- Uses `if: always()` on report/deploy/status steps so they run even if analysis finds issues
- Report URL pattern: `https://OWNER.github.io/REPO/vi-analyzer/vi-analyzer/SHORT_SHA/`

### 3. VIDiff workflow

**Purpose**: Generates visual side-by-side comparison reports for every VI that changed between two commits.

**Key details**:
- Checks out both the base and head commits into separate directories (`base/` and `pr/`)
- Mounts both into the container (`C:\workspace` and `C:\workspace-base`)
- Handles three cases: Modified (comparison report), Added (snapshot), Deleted (snapshot of old version)
- Uses magic-byte checking (`LVIN`/`LVCC`) to skip non-LabVIEW files that have `.vi` extensions
- Saves metadata (PR number, head SHA, platform) as an artifact for the deploy workflow
- Supports `base_sha`/`head_sha` inputs for retroactive diff generation

### 4. VIDiff Deploy workflow

**Purpose**: Runs on `ubuntu-latest` after VIDiff completes. Deploys reports to Pages and posts notifications.

**Key details**:
- Triggered by `workflow_run` completion (not direct triggers) — this is required because the VIDiff workflow runs on Windows but Pages deployment is simpler on Linux
- Downloads report and metadata artifacts from the triggering run
- Reads `head_sha` from metadata (not from `github.event.workflow_run.head_sha`) to correctly target historical commits
- Generates an `index.html` listing all report files
- When only one report exists, the commit status links directly to it; when multiple, links to the index
- For PRs: posts/updates a comment with a table of report links
- Report URL pattern: `https://OWNER.github.io/REPO/vidiff/push-SHORT_SHA/windows/` or `.../pr-NUMBER/windows/`

---

## Permissions required

```yaml
permissions:
  contents: write      # Push to gh-pages branch
  pages: write         # GitHub Pages deployment
  statuses: write      # Post commit status links
  pull-requests: write # Comment on PRs (VIDiff deploy only)
```

---

## Triggering retroactive runs

To build up a history of reports for existing commits:

### VI Analyzer (per-commit)
```bash
# Get all commits that changed LabVIEW files
git log --format='%H' --reverse origin/main -- '*.vi' '*.ctl' | while read sha; do
  gh workflow run "Run VI Analyzer - Windows Container" -f commit_sha="$sha"
done
```

### VIDiff (consecutive pairs)
```bash
COMMITS=($(git log --format='%H' --reverse origin/main -- '*.vi' '*.ctl'))
PREV=""
for sha in "${COMMITS[@]}"; do
  if [ -n "$PREV" ]; then
    gh workflow run "VIDiff Report - Windows Container" -f base_sha="$PREV" -f head_sha="$sha"
  fi
  PREV="$sha"
done
```

**Note**: Each run takes ~15 minutes due to Docker image pull + LabVIEW startup. GitHub Actions has concurrency limits, so large batches will queue.

---

## Adapting to the user's project

When implementing this pipeline, adapt the following to the specific project:

- **LabVIEW version**: The container tag and `$LabVIEWPath` in scripts reference a specific LabVIEW version. Check what's available at `nationalinstruments/labview` on Docker Hub.
- **Path filters**: Adjust the `paths:` filters in workflow triggers to match the project's LabVIEW file types and directory structure.
- **VI Analyzer rules**: Customize the `.viancfg` file with the appropriate tests for the project. The full list of available tests is in LabVIEW's VI Analyzer tool.
- **Excluded directories**: If certain directories (e.g., third-party libraries) should be excluded from analysis, add `<ExclusionData>` entries to the VI Analyzer config.
- **Report styling**: The HTML report templates can be customized with project branding.
- **Branch protection**: Consider requiring the Mass Compile and VI Analyzer status checks to pass before merging PRs.

---

## Common issues and fixes

| Problem | Cause | Fix |
|---|---|---|
| Docker daemon not found | Runner is `windows-latest` (Server 2025) | Pin to `windows-2022` |
| 0 VIs analyzed | VI Analyzer config uses relative path `"."` | Use `"C:\workspace"` |
| Script not found in container | Historical commit doesn't have CI scripts | Add "Restore CI scripts from main" step |
| Wrong commit gets status link | `github.event.workflow_run.head_sha` points to HEAD, not the dispatched commit | Save actual `head_sha` in metadata artifact, read it in deploy workflow |
| GitHub Pages 404 | Pages not enabled on repo | Enable via Settings → Pages or `gh api` |
| Report links go to index instead of report | Status URL points to directory | Check report count; link directly when only one file |
