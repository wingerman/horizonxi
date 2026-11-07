#!/usr/bin/env bash
# Copy one character's LuAshitacast profiles plus common/ into a HorizonXI install.
# usage: scripts/deploy.sh <Name_Id> [GameDir]
set -euo pipefail
CHAR="${1:?usage: deploy.sh <Name_Id> [GameDir]}"
GAME="${2:-${HXI_GAME_DIR:-/mnt/g/horizonxi/HorizonXI/Game}}"
REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/luashitacast/$CHAR"
[ -d "$SRC" ] || { echo "no such character folder: $SRC" >&2; exit 1; }
DST="$GAME/config/addons/luashitacast"
mkdir -p "$DST/$CHAR" "$DST/common"
cp "$SRC"/*.lua "$DST/$CHAR/"
ls "$REPO"/luashitacast/common/*.lua >/dev/null 2>&1 && cp "$REPO"/luashitacast/common/*.lua "$DST/common/"
echo "deployed $CHAR to $DST"
echo "in game: /lac reload"
