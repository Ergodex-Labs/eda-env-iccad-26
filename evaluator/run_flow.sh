#!/bin/bash
set -euo pipefail

FLOW=${FLOW:-/OpenROAD-flow-scripts/flow}
WS=${WS:-/workspace}
PROFILE=${PROFILE:-/task/profile.json}
MERGED=${MERGED:-/tmp/orfs-scripts-merged}
WORK_HOME=${WORK_HOME:-/tmp/orfs-work}
DESIGN_CONFIG=${DESIGN_CONFIG:-$WS/config.mk}

RX=$(python3 -c "import json;print(json.load(open('$PROFILE'))['editable_scripts_regex'])")

rm -rf "$MERGED"; mkdir -p "$MERGED"
for f in "$FLOW"/scripts/*; do
  base=$(basename "$f")
  if [[ "$base" =~ ^($RX)$ ]] && [[ -f "$WS/flow/scripts/$base" ]]; then
    cp "$WS/flow/scripts/$base" "$MERGED/$base"
    echo "orfs-agent-run: using WORKSPACE copy of $base" >&2
  else
    ln -s "$f" "$MERGED/$base"
  fi
done

if [[ "${1:-}" == "--print-scripts-dir" ]]; then
  echo "$MERGED"
  for f in "$MERGED"/*; do
    b=$(basename "$f")
    if [[ -L "$f" ]]; then echo "image     $b"; else echo "WORKSPACE $b"; fi
  done
  exit 0
fi

cd "$FLOW"
exec make DESIGN_CONFIG="$DESIGN_CONFIG" WORK_HOME="$WORK_HOME" \
  SCRIPTS_DIR="$MERGED" WS="$WS" "${@:-finish}"
