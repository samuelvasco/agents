#!/usr/bin/env bash
# Link personal skills and rules from ~/.agents into each agent's scan dirs.
# Idempotent. Only replaces symlinks that already point back here.
#
#   ~/.agents/skills/<name>/SKILL.md
#   ~/.agents/rules/<name>.mdc
#
# Usage: bash ~/.agents/sync.sh [--dry-run]

set -euo pipefail

ROOT="$HOME/.agents"
SRC_SKILLS="$ROOT/skills"
SRC_RULES="$ROOT/rules"

SKILL_TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.cursor/skills"
)

RULE_TARGETS=(
  "$HOME/.claude/rules"
  "$HOME/.cursor/rules"
)

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

run() { [ "$DRY_RUN" -eq 1 ] && { echo "  would: $*"; return 0; }; "$@"; }

owned_link() {
  local link="$1"
  local dest
  dest=$(readlink "$link")
  case "$dest" in
    "$ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

link_path() {
  local source="$1"
  local link="$2"
  local name
  name=$(basename "$source")

  if [ -L "$link" ]; then
    [ "$(readlink "$link")" = "$source" ] && return 0
    if owned_link "$link"; then
      run rm "$link"
    else
      echo "  SKIP   $name — symlink is not owned, not overwriting"
      conflicts=$((conflicts + 1))
      return 0
    fi
  elif [ -e "$link" ]; then
    echo "  SKIP   $name — a real file/directory is already there, not overwriting"
    conflicts=$((conflicts + 1))
    return 0
  fi

  run ln -s "$source" "$link"
  echo "  link   $name"
  linked=$((linked + 1))
}

prune_owned_links() {
  local target="$1"
  local prefix="$2"
  local link dest
  for link in "$target"/*; do
    [ -L "$link" ] || continue
    dest=$(readlink "$link")
    case "$dest" in
      "$prefix"/*) [ -e "$dest" ] || { echo "  prune  $(basename "$link")"; run rm "$link"; pruned=$((pruned + 1)); } ;;
    esac
  done
}

linked=0
pruned=0
conflicts=0

[ -d "$SRC_SKILLS" ] || { echo "error: no skills directory at $SRC_SKILLS" >&2; exit 1; }

for target in "${SKILL_TARGETS[@]}"; do
  echo "$target"
  run mkdir -p "$target"
  prune_owned_links "$target" "$SRC_SKILLS"
  for skill in "$SRC_SKILLS"/*/; do
    [ -f "${skill}SKILL.md" ] || continue
    name=$(basename "$skill")
    link_path "${skill%/}" "$target/$name"
  done
done

if [ -d "$SRC_RULES" ]; then
  for target in "${RULE_TARGETS[@]}"; do
    echo "$target"
    run mkdir -p "$target"
    prune_owned_links "$target" "$SRC_RULES"
    for rule in "$SRC_RULES"/*; do
      [ -f "$rule" ] || continue
      case "$rule" in
        *.mdc | *.md) ;;
        *) continue ;;
      esac
      link_path "$rule" "$target/$(basename "$rule")"
    done
  done
fi

echo
echo "linked $linked, pruned $pruned, skipped $conflicts"
