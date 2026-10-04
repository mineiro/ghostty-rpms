#!/usr/bin/env bash
# Keep one GitHub issue per tracked condition in sync with CI results, so a
# failing scheduled check is visible (and emailed) instead of sitting as a red
# run, and the issue closes itself once the check recovers.
#
#   ci-issue.sh alert <label> <title> failing|passing [body-file]
#     failing: open the issue, or comment on the open one with the body.
#     passing: comment and close the open issue, if any.
#
#   ci-issue.sh sync <label> <title> <body-file>
#     Non-empty body: open the issue, or replace its body and comment when the
#     content changed. Empty body: close the open issue, if any.
#
#   ci-issue.sh run-summary
#     Print the current run's failed jobs and their error annotations, as a
#     Markdown body for "alert ... failing".
#
# Requires: gh with GH_TOKEN (issues: write); GITHUB_REPOSITORY.
set -euo pipefail

usage() {
  sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

if [[ "${1:-}" == "run-summary" ]]; then
  repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is not set}"
  echo "Failed jobs:"
  echo
  gh run view "${GITHUB_RUN_ID:?}" --repo "${repo}" --json jobs \
    --jq '.jobs[] | select(.conclusion == "failure") | "\(.databaseId)\t\(.name)"' |
    while IFS=$'\t' read -r job_id job_name; do
      echo "- **${job_name}**"
      gh api "repos/${repo}/check-runs/${job_id}/annotations" \
        --jq '.[] | select(.annotation_level == "failure") | "  - \(.message | split("\n")[0])"' |
        grep -v 'Process completed with exit code' | head -n 20 || true
    done
  exit 0
fi

[[ $# -ge 3 ]] || usage
mode="$1"
label="$2"
title="$3"
repo="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is not set}"
run_url="${GITHUB_SERVER_URL:-https://github.com}/${repo}/actions/runs/${GITHUB_RUN_ID:-0}"

ensure_label() {
  gh label create "${label}" --repo "${repo}" --color B60205 \
    --description "Managed by CI (scripts/ci-issue.sh)" --force >/dev/null
}

open_issue_number() {
  gh issue list --repo "${repo}" --state open --label "${label}" \
    --json number,title --jq "map(select(.title == \"${title}\")) | .[0].number // empty"
}

close_if_open() {
  local number="$1" comment="$2"
  [[ -n "${number}" ]] || return 0
  gh issue close "${number}" --repo "${repo}" --comment "${comment}"
}

case "${mode}" in
  alert)
    [[ $# -ge 4 ]] || usage
    state="$4"
    body_file="${5:-}"
    number="$(open_issue_number)"
    case "${state}" in
      failing)
        body="$(cat "${body_file:-/dev/null}" 2>/dev/null || true)"
        body="${body:-Check failed.}"$'\n\n'"Run: ${run_url}"
        if [[ -n "${number}" ]]; then
          gh issue comment "${number}" --repo "${repo}" --body "${body}"
        else
          ensure_label
          gh issue create --repo "${repo}" --label "${label}" --title "${title}" --body "${body}"
        fi
        ;;
      passing)
        close_if_open "${number}" "Recovered: ${run_url}"
        ;;
      *) usage ;;
    esac
    ;;
  sync)
    [[ $# -ge 4 ]] || usage
    body="$(cat "$4")"
    number="$(open_issue_number)"
    if [[ -z "${body}" ]]; then
      close_if_open "${number}" "Resolved: ${run_url}"
      exit 0
    fi
    body+=$'\n\n'"Last checked: ${run_url}"
    if [[ -z "${number}" ]]; then
      ensure_label
      gh issue create --repo "${repo}" --label "${label}" --title "${title}" --body "${body}"
      exit 0
    fi
    current="$(gh issue view "${number}" --repo "${repo}" --json body --jq .body)"
    # Compare without the run link so an unchanged list stays quiet.
    if [[ "${current%$'\n\nLast checked: '*}" != "${body%$'\n\nLast checked: '*}" ]]; then
      gh issue edit "${number}" --repo "${repo}" --body "${body}"
      gh issue comment "${number}" --repo "${repo}" --body "Updated: ${run_url}"
    else
      gh issue edit "${number}" --repo "${repo}" --body "${body}"
    fi
    ;;
  *)
    usage
    ;;
esac
