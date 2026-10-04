#!/usr/bin/env bash
# Print a Markdown report of packages that are behind upstream (or whose
# source URL check failed), for scripts/ci-issue.sh sync. Prints nothing when
# everything is current. Packages with UPSTREAM_HOLD="<reason>" in package.env
# are listed as held and never make the report non-empty on their own.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
checker="${repo_root}/scripts/check-upstream-versions.sh"
checker_args=()
if "${checker}" --help 2>&1 | grep -q -- --changed-only; then
  checker_args+=(--changed-only)
fi
check_output="$("${checker}" "${checker_args[@]}")"

hold_reason() {
  local env_file="${repo_root}/packages/$1/package.env"
  [[ -f "${env_file}" ]] || return 0
  # shellcheck disable=SC1090
  (UPSTREAM_HOLD=""; source "${env_file}"; printf '%s' "${UPSTREAM_HOLD}")
}

# Read columns by header name; checkers in different repositories print
# different column sets (SOURCE is optional).
rows="$(awk 'NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i; next }
  NF { printf "%s\t%s\t%s\t%s\t%s\n", $col["PACKAGE"], $col["LOCAL"], $col["UPSTREAM"],
       $col["STATUS"], ("SOURCE" in col) ? $col["SOURCE"] : "-" }' <<<"${check_output}")"

actionable=()
held=()
while IFS=$'\t' read -r package local_version upstream_version status source; do
  [[ -n "${package}" ]] || continue
  # Current packages are noise unless their source check failed.
  if [[ "${status}" == "same" || "${status}" == "manual" ]]; then
    [[ "${source}" == missing* || "${source}" == unknown* ]] || continue
  fi
  row="| \`${package}\` | ${local_version} | ${upstream_version} | ${status} | ${source} |"
  reason="$(hold_reason "${package}")"
  if [[ -n "${reason}" ]]; then
    held+=("| \`${package}\` | ${local_version} | ${upstream_version} | ${reason} |")
  else
    actionable+=("${row}")
  fi
done <<<"${rows}"

[[ ${#actionable[@]} -gt 0 ]] || exit 0

echo "Packages behind upstream or with a failing source check:"
echo
echo "| Package | Local | Upstream | Status | Source |"
echo "|---|---|---|---|---|"
printf '%s\n' "${actionable[@]}"
if [[ ${#held[@]} -gt 0 ]]; then
  echo
  echo "Held on purpose (\`UPSTREAM_HOLD\` in \`package.env\`):"
  echo
  echo "| Package | Local | Upstream | Reason |"
  echo "|---|---|---|---|"
  printf '%s\n' "${held[@]}"
fi
echo
echo "Run \`/fedora-rpm-maintenance\` in a session to prepare the update."
