# GitLab CI


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


## Triggers

The [`./workflow.yml`](./workflow.yml) instructs GitLab to create a pipeline when:
- a tag is pushed;
- a merge request targets the default branch;
- a commit is pushed to the default branch;
- a non-default-branch commit message ends with `RUN_CI_PIPELINE`;
- a pipeline is started manually from the GitLab web UI.


## Artifact Output

Packages produced during pipelines are stored at:<br>
`https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/{BranchName_or_Tag}/{Platform}/{build_variant}/DishSW_ContactHolder-{ProjectVersion}.{PackageExtension}`,

where:
- `BranchName_or_Tag` is name of a branch or a tag, which triggered the pipeline;
- `Platform` is a substring of the Dockerfile name, which was used to build the used image; e.g. [`Dockerfile.Ubuntu24AMD__build`](../Docker/Dockerfile.Ubuntu24AMD__build) yields Platform=`Ubuntu24AMD`;
- `build_variant` is the argument, passed to [`build.py --build_variant`](../../build.py);
- `PackageExtension` is determined by a used package generator. Set of package generators is defined in `CMagneto__PACKAGE_GENERATORS` variable inside `CMakePresets.json` file of chosen build variant.

The resulting URL may look like:<br>
[https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/Makefiles_GCC/DishSW_ContactHolder-0.0.1.deb](https://gitlab.com/api/v4/projects/71534203/packages/generic/dishsoftware/contactholder/v1.0.0/Ubuntu24AMD/Makefiles_GCC/DishSW_ContactHolder-0.0.1.deb) .
