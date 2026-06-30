# ghostty-git Automation

The `ghostty-git snapshot` GitHub Actions workflow checks upstream Ghostty
`main` once per day and can also be run manually.

It performs this sequence:

1. Resolve `ghostty-org/ghostty` `HEAD`.
2. Compare it with `%global commit` in `packages/ghostty-git/ghostty-git.spec`.
3. Exit without changes if the commit is already current.
4. Update the snapshot macros when upstream changed.
5. Run the package checks and generate an SRPM.
6. Commit and push the snapshot bump.
7. Trigger and watch the COPR `ghostty-git` package build.

## Required Secret

Add a repository Actions secret named `COPR_CONFIG` containing the full contents
of the COPR CLI config file for an account allowed to build in
`mineiro/ghostty`.

On a configured machine, that is usually:

```bash
cat ~/.config/copr
```

The workflow writes this secret back to `~/.config/copr` inside the Actions
runner before calling `copr-cli`.

## Failure Alerts

GitHub already marks failed scheduled workflow runs and sends notifications
according to repository/user notification settings. The workflow also opens, or
comments on, a GitHub issue titled `ghostty-git automation failed` when any step
fails. This uses the built-in `GITHUB_TOKEN`; no extra secret is needed.
