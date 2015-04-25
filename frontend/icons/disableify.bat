@echo OFF
setlocal enabledelayedexpansion

for %%f IN (*.png) DO (
  set "fname=%%f"
  if "!fname:disabled=!"=="%%f" (
    gm convert -modulate 100,0 !fname! "!fname:~0,-4!-disabled.png"
  )
)