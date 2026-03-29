# GitLab CI Notes

## Files

- `workflow.yml`
  Creates a pipeline only for:
  - tags;
  - pushes to the default branch;
  - merge requests that target the default branch;
  - commits whose message ends with `RUN_CI_PIPELINE`.

- `pipeline.yml`
  Defines stages and includes the shared job templates and platform-dependent job DAG files.

- `job_templates.yml`
  Defines reusable job templates and trigger-specific rule templates.

- `platform_dependent_job_DAGs/*.yml`
  Defines the concrete jobs for each supported platform.

## Current pipeline behaviour

### Merge request targeting the default branch

The merge-request pipeline runs the same `on_main__*` jobs as a direct push to the default branch.

It runs:
- package build jobs;
- package installation / package run validation jobs;
- package upload jobs.

It does not run:
- test coverage job.

Intent:
- validate the project before merge;
- publish branch-specific packages for the merge-request branch.

### Push to the default branch after merge

The default-branch pipeline also runs the `on_main__*` jobs.

It runs:
- package build jobs;
- package installation / package run validation jobs;
- package upload jobs;
- test coverage job.

Intent:
- validate and publish the actual merged state of the default branch;
- collect coverage for the default branch.

### Tag pipeline

For tags, the release-style flow runs:
- package build;
- package installation / package run validation;
- package upload.

### Explicit pipeline creation on any branch

If a commit message ends with `RUN_CI_PIPELINE`, `workflow.yml` creates a pipeline even on branches that normally would not create one.

In that case, the branch-scoped jobs decide what runs inside the pipeline according to their own `rules:`.

## Trigger-specific templates in `job_templates.yml`

The current reusable rule templates are:

- `.on_tag`
  For tag pipelines.

- `.on_main`
  For:
  - push pipelines on the default branch;
  - merge-request pipelines that target the default branch.

- `.on_branch`
  For non-tag pipelines that are neither:
  - push to the default branch;
  - nor merge request to the default branch.

## About duplicate work around a merge

With GitLab Free and the current project settings:
- an MR targeting the default branch gets a merge-request pipeline;
- after the MR is merged, the push to the default branch gets another pipeline.

Because both contexts use `.on_main`, most main-oriented jobs run in both pipelines.

This is the simple standalone setup of `SeedProject`.

## Test coverage

The coverage job is different from the other main-oriented jobs.

It runs only when:
- `CI_COMMIT_BRANCH == CI_DEFAULT_BRANCH`

So it runs on a direct push to the default branch, including the push created by merge, but not in a merge-request pipeline.

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
