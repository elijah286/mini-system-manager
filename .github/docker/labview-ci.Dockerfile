# escape=`
FROM nationalinstruments/labview:latest-windows

SHELL ["powershell", "-NoLogo", "-NoProfile", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Feed/package values are ARGs so they are explicit and easy to revise per LabVIEW major version.
ARG NIPM_FEED_NAME=LV2026
ARG NIPM_FEED_URL=https://download.ni.com/support/nipkg/products/ni-l/ni-labview-2026/26.1/released
ARG VIA_SUPPORT_PACKAGE=ni-viawin-labview-support

# Copy optional VIPC automation assets from the repo.
COPY .github/labview/vipm/ C:/vipm/

# Install VI Analyzer support package at image build-time (not runtime in CI jobs).
# nipkg install is idempotent — if the package is already present it exits cleanly.
RUN if (-not (Get-Command nipkg -ErrorAction SilentlyContinue)) { throw 'nipkg was not found in the LabVIEW base image.' }; `
    nipkg feed-add --name=$env:NIPM_FEED_NAME $env:NIPM_FEED_URL; `
    nipkg update; `
    nipkg install --accept-eulas -y --passive $env:VIA_SUPPORT_PACKAGE; `
    if (Test-Path 'C:\ProgramData\National Instruments\NI Package Manager\cache') { `
      Remove-Item -Path 'C:\ProgramData\National Instruments\NI Package Manager\cache\*' -Force -Recurse -ErrorAction SilentlyContinue `
    }

# Optional VIPC support hook.
# If VIPC files exist, an installer script must be present so dependencies are handled explicitly.
RUN $vipcFiles = Get-ChildItem -Path 'C:\vipm' -Filter '*.vipc' -Recurse -ErrorAction SilentlyContinue; `
    if ($vipcFiles -and $vipcFiles.Count -gt 0) { `
      if (Test-Path 'C:\vipm\install-vipc.ps1') { `
        Write-Host 'VIPC files detected. Running C:\vipm\install-vipc.ps1 ...'; `
        powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File 'C:\vipm\install-vipc.ps1' `
      } else { `
        throw 'VIPC files were detected in C:\vipm but install-vipc.ps1 was not provided.' `
      } `
    } else { `
      Write-Host 'No VIPC dependencies were provided. Skipping VIPM install hook.' `
    }
