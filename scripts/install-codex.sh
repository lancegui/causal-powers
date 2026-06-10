#!/usr/bin/env bash
#
# install-codex.sh — install Causal Powers into OpenAI Codex.
#
# Copies the skills into a directory Codex scans and installs the always-on
# discipline as a managed block in AGENTS.md. Idempotent: re-run any time to
# update (it git-pulls the cached clone and re-copies). Works from a clone or
# piped straight from the web.
#
# Copy-paste — USER scope (all your projects):
#   curl -fsSL https://raw.githubusercontent.com/lancegui/causal-powers/main/scripts/install-codex.sh | bash
#
# PROJECT scope (checked into one repo, for your team):
#   curl -fsSL https://raw.githubusercontent.com/lancegui/causal-powers/main/scripts/install-codex.sh | bash -s -- --project .
#
# From a local clone:
#   ./scripts/install-codex.sh            # user scope
#   ./scripts/install-codex.sh --project /path/to/repo
#   ./scripts/install-codex.sh --uninstall
#
# Then restart Codex (or run /skills). Requires: bash, git, python3.

set -euo pipefail

REPO_URL="https://github.com/lancegui/causal-powers"
CACHE="${CAUSAL_POWERS_HOME:-$HOME/.causal-powers}"
BEGIN="<!-- causal-powers:begin (managed by install-codex.sh — do not edit between markers) -->"
END="<!-- causal-powers:end -->"

SCOPE="user"; PROJECT_DIR=""; UNINSTALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project)    SCOPE="project"; PROJECT_DIR="${2:-$PWD}"; shift 2 ;;
    --project=*)  SCOPE="project"; PROJECT_DIR="${1#*=}"; shift ;;
    --uninstall)  UNINSTALL=1; shift ;;
    -h|--help)    sed -n '3,28p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

die() { echo "ERROR: $*" >&2; exit 1; }
command -v git >/dev/null     || die "git not found"
command -v python3 >/dev/null || die "python3 not found"

# --- locate the source: a clone we're inside, else clone/update the cache ------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/../skills" ]; then
  SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
else
  if [ -d "$CACHE/repo/.git" ]; then
    echo "Updating cached clone at $CACHE/repo ..."
    git -C "$CACHE/repo" pull --quiet --ff-only || echo "  (pull skipped; using existing clone)"
  else
    echo "Cloning $REPO_URL -> $CACHE/repo ..."
    mkdir -p "$CACHE"; git clone --quiet "$REPO_URL" "$CACHE/repo"
  fi
  SRC="$CACHE/repo"
fi
[ -d "$SRC/skills" ] || die "skills/ not found in $SRC"

# --- resolve target dirs (per Codex docs) -------------------------------------
if [ "$SCOPE" = "project" ]; then
  [ -n "$PROJECT_DIR" ] || PROJECT_DIR="$PWD"
  PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
  SKILLS_DIR="$PROJECT_DIR/.agents/skills"
  AGENTS_FILE="$PROJECT_DIR/AGENTS.md"
else
  SKILLS_DIR="$HOME/.agents/skills"
  AGENTS_FILE="${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
fi

# --- uninstall ----------------------------------------------------------------
if [ "$UNINSTALL" -eq 1 ]; then
  for d in "$SRC/skills"/*/; do rm -rf "$SKILLS_DIR/$(basename "$d")"; done
  if [ -f "$AGENTS_FILE" ]; then
    python3 - "$AGENTS_FILE" "$BEGIN" "$END" <<'PY'
import sys
f,b,e=sys.argv[1],sys.argv[2],sys.argv[3]
t=open(f).read()
if b in t and e in t:
    open(f,"w").write(t.split(b)[0].rstrip("\n")+("\n" if t.split(b)[0].strip() else "")+t.split(e,1)[1].lstrip("\n"))
PY
  fi
  echo "Uninstalled Causal Powers skills from $SKILLS_DIR and the managed block from $AGENTS_FILE."
  exit 0
fi

# --- copy skills (robust; no symlink-following assumptions) -------------------
mkdir -p "$SKILLS_DIR" "$(dirname "$AGENTS_FILE")"
n=0
for d in "$SRC/skills"/*/; do
  name="$(basename "$d")"
  rm -rf "$SKILLS_DIR/$name"
  cp -R "$d" "$SKILLS_DIR/$name"
  n=$((n+1))
done
echo "Installed $n skills -> $SKILLS_DIR"

# --- install/refresh the always-on discipline as a managed block (idempotent) -
python3 - "$AGENTS_FILE" "$SRC/hooks/session-context.md" "$BEGIN" "$END" <<'PY'
import sys
agents, src, begin, end = sys.argv[1:5]
block = open(src).read().rstrip("\n")
managed = f"{begin}\n{block}\n{end}\n"
try: cur = open(agents).read()
except FileNotFoundError: cur = ""
if begin in cur and end in cur:
    new = cur.split(begin)[0] + managed + cur.split(end, 1)[1]
    action = "Refreshed"
else:
    sep = "" if (cur == "" or cur.endswith("\n")) else "\n"
    pad = "\n" if cur.strip() else ""
    new = cur + sep + pad + managed
    action = "Added"
open(agents, "w").write(new)
print(f"{action} the Causal Powers discipline block in {agents}")
PY

echo
echo "Done. Restart Codex (or run /skills) to pick up the skills."
echo "  • Skills trigger off their descriptions, or invoke explicitly: \$using-causal-powers"
echo "  • Always-on discipline loaded from: $AGENTS_FILE"
echo "  • Tool mapping (Task->spawn_agent, etc.): $SKILLS_DIR/using-causal-powers/references/codex-tools.md"
echo "  • Update later: re-run this script.  Remove: re-run with --uninstall"
