# VIPM/VIPC dependency hook

This folder is reserved for future VIPC dependency automation in the pre-baked LabVIEW CI image.

Supported pattern:
- Add one or more `.vipc` files here.
- Add an optional `install-vipc.ps1` script in this same folder.

During Docker image build, the Dockerfile checks this folder:
- If no `.vipc` files are present, the build continues with no VIPM step.
- If `.vipc` files are present and `install-vipc.ps1` exists, that script is executed.
- If `.vipc` files are present but no installer script exists, the build fails so dependencies are not silently skipped.

This keeps the image build reproducible and allows VIPC dependency installation to be introduced when the project is ready.
