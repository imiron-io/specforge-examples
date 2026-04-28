#!/usr/bin/env bash
#
# cli-tour.sh — a guided tour of the `specforge` command-line interface.
# By default, runs as an interactive TUI if `gum` is installed.
# Pass `--no-gum` to force the original, linear script execution.
#
#     ./cli-tour.sh [--no-gum]
#
# Requires the `specforge` CLI on your PATH (see https://docs.imiron.io).
#

set -euo pipefail

# Operate on this script's own directory
cd "$(dirname "${BASH_SOURCE[0]}")"

# ===========================================================================
# 0. Argument Parsing & Environment Detection
# ===========================================================================

FORCE_NO_GUM=0
LILO_REVERTED=0 # Track whether the user has already cleaned up the bulk-label edit

for arg in "$@"; do
  case $arg in
    --no-gum)
      FORCE_NO_GUM=1
      ;;
  esac
done

if [ "$FORCE_NO_GUM" -eq 0 ] && command -v gum >/dev/null 2>&1; then
  HAS_GUM=1
else
  HAS_GUM=0
  bold=$'\033[1m'; dim=$'\033[2m'; cyan=$'\033[36m'; reset=$'\033[0m'
  if [ "$FORCE_NO_GUM" -eq 0 ]; then
    printf '\n%sNote:%s gum is not installed. Continuing in basic mode.\n' "$cyan" "$reset"
    printf '%sInstall gum for a better interactive experience:%s https://github.com/charmbracelet/gum\n\n' "$dim" "$reset"
  fi
fi

# ===========================================================================
# Helper Functions (Adaptive)
# ===========================================================================

section() {
  # 1. Pause to let the user read the previous output (if a section is active)
  if [ "${section_started:-0}" -eq 1 ]; then
    if [ "$HAS_GUM" -eq 1 ]; then
      echo ""
      # The gum UI pauses here, keeping previous command output on screen
      gum confirm "Proceed to next section?" --affirmative "Next" --negative "Main Menu" || return 2
    else
      echo ""
      printf '%sPress return ⏎ to continue...%s' "$dim" "$reset"
      read -r _
    fi
  fi
  section_started=1

  # 2. Clear and print the new banner
  if [ "$HAS_GUM" -eq 1 ]; then
    clear
    gum style --border double --margin "1" --padding "0 2" --border-foreground 212 --foreground 212 "$1"
    if [ $# -gt 1 ]; then 
      gum style --foreground 241 "$2"
      echo ""
    fi
  else
    printf '\n%s━━━ %s ━━━%s\n' "$cyan" "$1" "$reset"
    if [ $# -gt 1 ]; then printf '%s%s%s\n' "$dim" "$2" "$reset"; fi
  fi
}

run() {
  if [ "$HAS_GUM" -eq 1 ]; then
    gum style --foreground 82 "$ specforge $*"
    gum style --foreground 241 "(Press return ⏎ to run)"
    read -r _
  else
    printf '\n%s$ specforge %s%s\n' "$bold" "$*" "$reset"
    printf '%s(Press return ⏎ to run)%s' "$dim" "$reset"
    read -r _
    echo ""
  fi

  local args=("$@")
  [[ " $* " == *" --verbosity "* ]] || args+=(--verbosity none)
  
  specforge "${args[@]}" || true
  
  if [ "$HAS_GUM" -eq 1 ]; then echo ""; fi
}

# Pauses at the very end of a standalone module before kicking back to the menu
end_pause() {
  if [ "$HAS_GUM" -eq 1 ]; then
    echo ""
    gum confirm "Module complete." --affirmative "Main Menu" --negative "Exit" || exit 0
  else
    echo ""
    printf '%sPress return ⏎ to return to menu...%s' "$dim" "$reset"
    read -r _
  fi
}

# ===========================================================================
# Tour Modules (Note the `|| return 2` to safely abort back to menu)
# ===========================================================================

run_orientation() {
  section "1. Orientation" "Which build are we driving, and how to discover commands?" || return 2
  run --version
  run --help
  run monitor --help

  section "Environment health" "Is the toolchain (SMT solver, LLM) wired up?" || return 2
  run doctor check-solver --verbosity info
  run doctor check-llm --verbosity info

  section "Built-in documentation" "Lilo + tooling reference, shipped in the binary." || return 2
  run doc
}

run_static_checks() {
  section "2. Static / structural checks" "Parse + type-check every .lilo file." || return 2
  run check

  section "Lint" "Fast, solver-free project diagnostics." || return 2
  run lint

  section "Analyze" "Solver-backed analyses: consistency & redundancy." || return 2
  run analyze --system Energy --spec surplusAtNight --timeout-seconds 15
}

run_spec_search() {
  section "3. Spec search & management" "The same query engine as the VS Code extension." || return 2
  run search --query 'label:safety'
  run search --query 'reviewed:true AND owner:"grid-ops"'

  section "Validate query containment" "is query A ⊆ query B?" || return 2
  run validate
  run validate --antecedent 'label:renewable' --consequent 'label:production'

  section "Bulk-label" "Add a label to every spec matching a query — edits source in place." || return 2
  run bulk-label --query 'label:renewable' --label 'green-energy'
  
  if [ "$HAS_GUM" -eq 1 ]; then
    gum style --foreground 241 "  Energy.lilo was modified:"
  else
    printf '%s  Energy.lilo was modified:%s\n' "$dim" "$reset"
  fi
  git --no-pager diff --stat -- Energy.lilo 2>/dev/null || true

  # -------------------------------------------------------------------------
  # Interactive Revert Prompt
  # -------------------------------------------------------------------------
  if [ "$HAS_GUM" -eq 1 ]; then
    echo ""
    if gum confirm "Energy.lilo was edited. Revert?" --affirmative "Yes, revert" --negative "Keep changes"; then
      git checkout -- Energy.lilo >/dev/null 2>&1
      LILO_REVERTED=1
      gum style --foreground 82 "  ✓ Reverted Energy.lilo"
    else
      LILO_REVERTED=0
      gum style --foreground 241 "  Changes kept."
    fi
  else
    echo ""
    printf '%sEnergy.lilo was edited. Revert? [Y/n] %s' "$cyan" "$reset"
    read -r revert_ans
    if [[ "$revert_ans" =~ ^([nN][oO]|[nN])$ ]]; then
      LILO_REVERTED=0
      printf '%s  Changes kept.%s\n' "$dim" "$reset"
    else
      git checkout -- Energy.lilo >/dev/null 2>&1
      LILO_REVERTED=1
      printf '%s  ✓ Reverted Energy.lilo%s\n' "$bold" "$reset"
    fi
  fi
}

run_data_driven() {
  section "4. Data-driven: schema, monitoring, evaluation, export" "Generate a CSV header matching the system's signals." || return 2
  run schema -s Energy --template csv --only signals

  section "Monitor a spec against data" "Same spec & trace, two parameter sets." || return 2
  run monitor Energy first60.csv --params summer.json surplusHealthy --robustness --start 0 --end 2
  run monitor Energy first60.csv --params winter.json surplusHealthy --robustness --start 0 --end 2

  section "Evaluate a derived signal" "Compute a def over the trace." || return 2
  run eval Energy first60.csv --params summer.json headroom
  run eval Energy first60.csv --params winter.json headroom

  section "Export a spec" "Interop: emit a spec for RTAMT." || return 2
  run export Energy daytimeSolarDominance ExpRTAMT
}

finish_tour() {
  if [ "$HAS_GUM" -eq 1 ]; then
    clear
    gum style --border double --margin "1" --padding "1 2" --border-foreground 82 --foreground 212 "Tour complete!"
    
    # Only show the nag if they haven't reverted it yet
    if [ "$LILO_REVERTED" -eq 0 ]; then
      echo "The bulk-label step modified Energy.lilo in place. To revert it:"
      gum style --foreground 82 "    git checkout -- Energy.lilo"
      echo ""
    fi
    
    gum confirm "Ready to exit?" --affirmative "Exit" --show-help=false || true
  else
    section "Tour complete" || true
    if [ "$LILO_REVERTED" -eq 0 ]; then
      printf 'The %sbulk-label%s step modified Energy.lilo in place. To revert it:\n\n' "$bold" "$reset"
      printf '    %sgit checkout -- Energy.lilo%s\n\n' "$bold" "$reset"
    else
      printf 'Tour finished successfully. No uncommitted changes left behind.\n\n'
    fi
  fi
}

# ===========================================================================
# Execution Control
# ===========================================================================

if [ "$HAS_GUM" -eq 1 ]; then
  # Interactive Menu Mode
  while true; do
    clear
    section_started=0 # Reset for each fresh execution from the menu
    
    gum style --border normal --margin "1" --padding "1 2" --border-foreground 69 --foreground 69 "Specforge Interactive Tour"
    
    CHOICE=$(gum choose \
      "1. Orientation" \
      "2. Static / structural checks" \
      "3. Spec search & management" \
      "4. Data-driven tools" \
      "Run Full Tour" \
      "Exit")

    case "$CHOICE" in
      "1. Orientation")            run_orientation || continue ; end_pause || exit 0 ;;
      "2. Static / structural checks") run_static_checks || continue ; end_pause || exit 0 ;;
      "3. Spec search & management") run_spec_search || continue ; end_pause || exit 0 ;;
      "4. Data-driven tools")      run_data_driven || continue ; end_pause || exit 0 ;;
      "Run Full Tour")
        # In full tour, end_pause is skipped so sections flow natively into one another
        run_orientation || continue
        run_static_checks || continue
        run_spec_search || continue
        run_data_driven || continue
        finish_tour
        exit 0
        ;;
      "Exit")
        clear
        exit 0
        ;;
    esac
  done

else
  # Linear Fallback Mode
  section_started=0
  run_orientation
  run_static_checks
  run_spec_search
  run_data_driven
  finish_tour
fi
