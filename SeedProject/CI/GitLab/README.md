# GitLab CI Notes

## GitLab project settings expected by this setup

Enabled:
- `Pipelines must succeed`
- merge method: `Merge commit with semi-linear history`
- direct pushes to the default branch are prohibited by repository policy

Not used:
- merged results pipelines
- merge trains

Reason:
- this setup is intended to work on GitLab Free;
- semi-linear history forces an outdated merge-request branch to be updated and retested before merge;
- the default branch should be updated through merge requests, not by direct pushes.
