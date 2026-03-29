# GitLab CI Notes

This directory contains the GitLab CI configuration for the `CMagneto` repo.

## Files

- `workflow.yml`
  Creates a pipeline only for:
  - tags;
  - pushes to the default branch;
  - merge requests that target the default branch;
  - commits whose message ends with `RUN_CI_PIPELINE`.

- `pipeline.yml`
  Defines which jobs run inside the created pipeline.

## Current pipeline behaviour

### Merge request targeting the default branch

This is the main validation pipeline for `CMagneto`.

It runs:
- `run_unit_and_integration_tests`

It does not run:
- `sync__seed_project__to__seed_project_repo`
- `trigger__seed_project__pipeline`
- `wait__seed_project__pipeline`

Intent:
- validate `CMagneto` before merge;
- prevent merge when the root-repo tests fail.

### Push to the default branch after merge

This is the post-merge synchronization pipeline.

It runs:
- `sync__seed_project__to__seed_project_repo`
- `trigger__seed_project__pipeline`
- `wait__seed_project__pipeline`

It does not run:
- `run_unit_and_integration_tests`

Intent:
- avoid rerunning the same expensive root-repo tests after merge;
- sync the real merged `SeedProject/` state into the downstream SeedProject repo;
- run the downstream SeedProject pipeline on that merged state.

### Tag pipeline

For tags, both parts run:
- `run_unit_and_integration_tests`
- the SeedProject sync/trigger/wait flow

### Explicit pipeline creation on any branch

If a commit message ends with `RUN_CI_PIPELINE`, `workflow.yml` creates a pipeline even on branches that normally would not create one.

In that case:
- `run_unit_and_integration_tests` runs;
- the SeedProject sync/trigger/wait flow does not run unless the ref is also a tag.

## Rule reuse inside `pipeline.yml`

The hidden template job `.seed_project__post_merge_rules` contains the shared `rules:` block used by:
- `sync__seed_project__to__seed_project_repo`
- `trigger__seed_project__pipeline`
- `wait__seed_project__pipeline`

This keeps the three post-merge SeedProject jobs in sync and reduces copy-pasted rule blocks.

## Important detail about `optional: true`

`sync__seed_project__to__seed_project_repo` has:

```yml
needs:
  - job: run_unit_and_integration_tests
    artifacts: false
    optional: true
```

Meaning:
- if `run_unit_and_integration_tests` exists in the current pipeline, the sync job waits for it;
- if the test job is not created at all, the sync job still runs.

This matters mainly for tags:
- in tag pipelines the sync job should wait for the test job;
- in post-merge pushes to the default branch the test job is intentionally omitted.

## Downstream SeedProject repo behaviour

The downstream SeedProject repo is treated as a mirror of the local `SeedProject/` subtree.

The sync script:
- copies files from `SeedProject/`;
- replaces the downstream `CI/GitLab/workflow.yml` with `test_project__workflow_replacement.yml`;
- commits the result;
- force-pushes the target ref in the downstream repo.

The downstream repo keeps its own standalone `job_templates.yml` and decides on its own which jobs to run.

This means the downstream branch is not meant to carry independent manual changes.

## Settings of CMagneto GitLab project expected by this setup

Enabled:
- `Pipelines must succeed`
- merge method: `Merge commit with semi-linear history`
- direct pushes to the default branch are prohibited by repository policy

Not used:
- merged results pipelines
- merge trains

Reason:
- this repo currently targets GitLab Free;
- semi-linear history forces an outdated merge-request branch to be updated and retested before merge;
- the default branch should be updated through merge requests, not by direct pushes.
