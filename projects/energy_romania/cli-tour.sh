#!/usr/bin/env bash
#
# cli-tour.sh — a guided tour of the `specforge` command-line interface,
# run against this example project (the Romanian power grid).
#
#     ./cli-tour.sh
#
# Requires the `specforge` CLI on your PATH (see https://docs.imiron.io).
#
# NOTE: the bulk-label step edits Energy.lilo in place. Revert it with:
#     git checkout -- Energy.lilo

set -euo pipefail

# Operate on this script's own directory, so the data-file paths resolve no
# matter where the tour is invoked from.
cd "$(dirname "${BASH_SOURCE[0]}")"

bold=$'\033[1m'; dim=$'\033[2m'; cyan=$'\033[36m'; reset=$'\033[0m'

printf '%sTip:%s install gum for a better interactive experience and run ./cli-tour-gum.sh\n\n' "$cyan" "$reset"

# A section banner.
section() {
  if [ "${section_started:-0}" -eq 1 ] && [ -t 0 ]; then
    printf '\n%sPress return to continue...%s' "$dim" "$reset"
    read -r _
  fi
  section_started=1
  printf '\n%s━━━ %s ━━━%s\n' "$cyan" "$1" "$reset"
  if [ $# -gt 1 ]; then printf '%s%s%s\n' "$dim" "$2" "$reset"; fi
}

# Echo a specforge command, then run it. We append `--verbosity none` (unless
# the call sets its own verbosity) so the tour shows each command's own output
# rather than info-level logging. Some commands exit non-zero to *report
# findings* (lint warnings, a failed validate); that is expected here, so we
# don't let `set -e` abort the tour.
run() {
  printf '\n%s$ specforge %s%s\n\n' "$bold" "$*" "$reset"
  local args=("$@")
  [[ " $* " == *" --verbosity "* ]] || args+=(--verbosity none)
  specforge "${args[@]}" || true
}

# ===========================================================================
# 1. Orientation
# ===========================================================================

section "Version & help" "Which build are we driving, and how to discover commands?"
run --version
run --help                 # top-level: every command
run monitor --help         # each sub-command has its own help

section "Environment health" "Is the toolchain (SMT solver, LLM) wired up?"
run doctor check-solver --verbosity info   # doctor reports at info level
run doctor check-llm --verbosity info

section "Built-in documentation" "Lilo + tooling reference, shipped in the binary."
run doc                    # list pages; print one with: specforge doc cli

# ===========================================================================
# 2. Static / structural checks
# ===========================================================================

section "Typecheck" "Parse + type-check every .lilo file."
run check

section "Lint" "Fast, solver-free project diagnostics."
run lint

section "Analyze" "Solver-backed analyses: consistency & redundancy." \
                  "Scoped to one spec to stay quick — drop --spec for the whole system."
run analyze --system Energy --spec surplusAtNight --timeout-seconds 15

# ===========================================================================
# 3. Spec search & governance
# ===========================================================================

section "Search the spec database" "The same query engine as the VS Code extension."
run search --query 'label:safety'
run search --query 'reviewed:true AND owner:"grid-ops"'   # custom #[field(...)] metadata

section "Validate query containment" "Governance rules: is query A ⊆ query B?"
run validate                                              # runs the rules in specforge.toml
# An ad-hoc rule that FAILS, listing the offenders:
run validate --antecedent 'label:renewable' --consequent 'label:production'

section "Bulk-label" "Add a label to every spec matching a query — edits source in place."
run bulk-label --query 'label:renewable' --label 'green-energy'
printf '%s  Energy.lilo was modified:%s\n' "$dim" "$reset"
git --no-pager diff --stat -- Energy.lilo 2>/dev/null || true

# ===========================================================================
# 4. Data-driven: schema, monitoring, evaluation, export
# ===========================================================================

section "Schema / data template" "Generate a CSV header matching the system's signals."
run schema -s Energy --template csv --only signals

section "Monitor a spec against data" \
        "Same spec & trace, two parameter sets — the verdict moves with the params."
# `surplusHealthy` needs surplus >= surplusMargin (300<MW> in summer, 800<MW> in
# winter), so the robustness at the violating point tightens from summer to
# winter. We monitor a short window (--start/--end) to keep the output readable.
run monitor Energy first60.csv --params summer.json surplusHealthy --robustness --start 0 --end 2
run monitor Energy first60.csv --params winter.json surplusHealthy --robustness --start 0 --end 2

section "Evaluate a derived signal" \
        "Compute a def over the trace — headroom depends on peakFactor."
run eval Energy first60.csv --params summer.json headroom   # peakFactor = 1.2
run eval Energy first60.csv --params winter.json headroom   # peakFactor = 1.3

section "Export a spec" "Interop: emit a spec for RTAMT (an STL monitoring library)."
run export Energy daytimeSolarDominance ExpRTAMT

# ===========================================================================
# Done
# ===========================================================================

section "Tour complete"
printf 'The %sbulk-label%s step modified Energy.lilo in place. To revert it:\n\n' "$bold" "$reset"
printf '    %sgit checkout -- Energy.lilo%s\n\n' "$bold" "$reset"
