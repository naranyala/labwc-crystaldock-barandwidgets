#!/bin/bash
set -euo pipefail
# Patch sfwbar bar.c for glassmorphism
sed -i 's/old_style/glassmorphism/' sources/sfwbar/src/gui/bar.c
