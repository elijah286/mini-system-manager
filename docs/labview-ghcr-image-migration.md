# LabVIEW CI image migration to GHCR

## Why this change

The CI workflows now use a pre-baked LabVIEW image from GHCR so environment provisioning happens at image build time instead of in every CI run.

## Changed files

- `.github/docker/labview-ci.Dockerfile`
  - New reproducible image definition based on `nationalinstruments/labview:latest-windows`.
  - Installs VI Analyzer support package at build time with non-interactive `nipkg` flags.
  - Includes optional VIPC hook support via `.github/labview/vipm/`.

- `.github/workflows/build-labview-image.yml`
  - New workflow that builds and pushes image tags to GHCR.
  - Triggers: manual dispatch, Dockerfile/vipm-path changes on `main`, monthly schedule.
  - Publishes digest in workflow summary.

- `.github/workflows/masscompile-windows-container.yml`
- `.github/workflows/run-vi-analyzer-windows-container.yml`
- `.github/workflows/vidiff-windows-container.yml`
- `.github/workflows/vi-snapshots.yml`
  - Image source changed to `ghcr.io/elijah286/mini-system-manager-labview:2026`.
  - Removed tar cache (`actions/cache` + `docker save`/`docker load`) and switched to direct pull.

- `.github/labview/vipm/README.md`
  - Documents optional VIPC dependency installation contract.

- `README.md`
  - Added explanation of Dockerfile-in-repo and image-in-GHCR split.

## Rebuild instructions

1. Run workflow: `Build LabVIEW CI Image`.
2. Optionally override `labview_tag` in `workflow_dispatch` input (default is `2026`).
3. Verify the workflow summary for the pushed digest.
4. Confirm package visibility in GitHub repo Packages tab.

## Rollback plan

If GHCR image availability fails or the new image is broken:

1. Revert workflow image env values in:
   - `.github/workflows/masscompile-windows-container.yml`
   - `.github/workflows/run-vi-analyzer-windows-container.yml`
   - `.github/workflows/vidiff-windows-container.yml`
   - `.github/workflows/vi-snapshots.yml`
   back to:
   - `nationalinstruments/labview:latest-windows`

2. If needed, restore old tar-cache steps in those workflows (cache/load/save blocks).

3. Disable or ignore `.github/workflows/build-labview-image.yml` until the image definition is corrected.

4. Re-run the affected CI workflows on `windows-2022`.

## Notes

- Keep all Windows container workflows on `windows-2022`.
- NI hardware drivers are still out of scope for container runtime.
