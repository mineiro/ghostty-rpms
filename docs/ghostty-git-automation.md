# ghostty-git Automation

The `ghostty-git snapshot` GitHub Actions workflow checks upstream Ghostty
`main` twice a week, on Monday and Thursday at 06:17 UTC (cron
`17 6 * * 1,4`), and can also be run manually.

## Invariant

`main` only ever receives a snapshot bump whose exact commit already built
successfully in COPR on every enabled chroot. A failed snapshot never lands on
`main`, so `main` always points at the last good snapshot and the next run
retries from there.

## Sequence

1. Resolve `ghostty-org/ghostty` `HEAD`.
2. Compare it with `%global commit` in `packages/ghostty-git/ghostty-git.spec`
   on `main`.
3. Exit without changes if the commit is already current.
4. Update the snapshot macros when upstream changed.
5. Run the package checks, generate an SRPM, and run `rpmbuild -bp`.
6. Commit the bump and push it to a throwaway candidate branch,
   `ghostty-git-candidate/<shortcommit>-<run id>`. `main` is not touched.
7. Submit a COPR SCM build pinned to that candidate commit with
   `copr-cli buildscm --commit <sha> --method make_srpm`, using the same clone
   URL, subdirectory and spec as the `ghostty-git` package entry. The package
   entry's own settings (committish `main`) are not changed.
8. Watch the build, then require that it built `ghostty-git` at the expected
   snapshot version and that every chroot reports `succeeded`.
9. Fast-forward `main` to the candidate commit with a plain (non-force) push,
   then delete the candidate branch. If `main` moved while the build ran, the
   push is rejected, the run fails, and the next run starts again from the new
   `main`.

If any step fails, `main` is left untouched and the candidate branch is kept
for diagnosis; delete it once it is no longer useful. Because the next run
compares upstream against `main`, it automatically retries the snapshot
(or a newer one), including after a packaging fix has been pushed to `main`.

COPR still publishes the RPMs from chroots that succeeded within a partially
failed build. The invariant above is about the packaging repository, not about
COPR's per-chroot publication.

## Manual builds

`copr-cli build-package mineiro/ghostty --name ghostty-git` builds whatever
`main` currently points at, which under the invariant is the last good
snapshot. To try an unpublished commit without moving `main`, push it to a
branch and use the same `copr-cli buildscm ... --commit <sha>` call as the
workflow.

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
fails. The comment links the run and COPR build, names the candidate commit and
branch, and states whether `main` was updated. This uses the built-in
`GITHUB_TOKEN`; no extra secret is needed.
