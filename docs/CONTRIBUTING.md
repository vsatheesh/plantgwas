# `vsatheesh/plantgwas`: Contributing guidelines

Hi there!
Thanks for taking an interest in improving plantgwas.

plantgwas is an open-source Nextflow pipeline for plant GWAS and genomic prediction. It is a standalone project, not an nf-core pipeline. It is built on the nf-core pipeline template and follows nf-core code conventions (schema-validated parameters, nf-test, shared modules, lint), because they make a pipeline easier to test and to run on different systems.

This page covers:

- [Contribution quick start](#contribution-quick-start)
- [Pipeline-specific guidelines](#pipeline-specific-guidelines): setup, test data, and how the project is organised
- [Code conventions](#code-conventions): how to add a step, name channels, set parameters and resources

## Contribution quick start

- [ ] Install Nextflow, [nf-test](https://www.nf-test.com), and [nf-core tools](https://github.com/nf-core/tools). The nf-core tools are a development aid for linting and modules; people who only run the pipeline do not need them.
- [ ] Check whether a GitHub [issue](https://github.com/vsatheesh/plantgwas/issues) about your idea already exists. If not, create one so that others know you are working on it.
- [ ] [Fork](https://help.github.com/en/github/getting-started-with-github/fork-a-repo) the [vsatheesh/plantgwas repository](https://github.com/vsatheesh/plantgwas) to your GitHub account.
- [ ] Create a branch on your fork and make your changes following the [code conventions](#code-conventions).
- [ ] Update the relevant documentation in the `docs/` folder, update `nextflow_schema.json` for any new parameter, and update `CITATIONS.md` for any new tool.
- [ ] Run and update the tests. See [Testing](#testing).
- [ ] [Lint](#lint-tests) your code.
- [ ] Open a pull request (PR) against the `main` branch and request a review.

If you are not used to this workflow with Git, see the [GitHub documentation](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests) or [Git resources](https://try.github.io/).

## Pipeline-specific guidelines

### Setting up

You need Nextflow and one way to fetch the analysis tools. Analysis tools such as bcftools are never installed by hand. Every module declares a container image and a conda recipe, and Nextflow downloads them on the first run. Pick the profile that matches your machine:

| Where you work | Profile |
| --- | --- |
| HPC cluster | `-profile singularity` or `-profile apptainer` |
| Laptop or workstation | `-profile docker` |
| No container engine | `-profile conda` |

Docker is not required. Please do not add a step that works only with Docker.

### Without installing anything: GitHub Codespaces

You can contribute without a local environment by using [GitHub Codespaces](https://github.com/codespaces), an online developer environment that runs in your browser with VS Code and a terminal. The repository includes a devcontainer configuration with Nextflow and nf-core tools pre-installed.

To get started, open the repository in [Codespaces](https://github.com/vsatheesh/plantgwas/codespaces).

### Where things are

- `docs/architecture.md`: the design of the pipeline: its stages, subworkflows and the reasoning behind them. Read this before proposing a new stage.
- `docs/usage.md` and `docs/output.md`: user-facing documentation.
- `assets/schema_input.json`: the samplesheet definition. Changing a column means changing this file and the channel code in `subworkflows/local/` together.
- `tests/testdata/`: small test data with a known answer key (see below).

### Test data

Test data is kept small and made on purpose. A test VCF should contain records that each exercise one filter, with the expected result written down in an answer key (`tests/testdata/test_panel_expected.tsv`). When a result is wrong, it then points at one filter, not at a thousand SNPs. Keep values away from exact thresholds, so that a `>` versus `>=` difference between tools cannot change the answer.

When you add a stage, add a case to the test data that exercises it on its own.

### Branches and releases

There is one long-lived branch, `main`. Open PRs against it. The project has no releases yet. Once it does, this section will describe the release process.

### License

plantgwas is released under the [MIT License](../LICENSE). By contributing, you agree that your contribution is licensed under the same terms.

## Code conventions

### Testing

Once you have made your changes, run the pipeline with nf-test to test them locally. Use the profile that fits your machine (`+docker`, `+singularity` or `+conda`). For additional information, use the `--verbose` flag to view the Nextflow console log output.

```bash
nf-test test --tag test --profile +docker --verbose
```

If you have added new functionality, update the test assertions in the `.nf.test` files in the `tests/` directory. Update the snapshots with:

```bash
nf-test test --tag test --profile +docker --verbose --update-snapshots
```

When you open a pull request, GitHub Actions runs automatic tests. Pull requests are typically reviewed once these tests pass.

Two types of tests run:

#### Lint tests

The pipeline follows the [nf-core pipeline guidelines](https://nf-co.re/docs/specifications/overview), checked with nf-core tools:

```bash
nf-core pipelines lint <pipeline_directory>
```

If you see failures or warnings, follow the linked documentation printed to the screen. Warnings are acceptable while a part of the pipeline is still under construction; failures are not.

#### Pipeline tests

The pipeline is run on a minimal set of test data to check that it runs through and exits successfully. Any failure fails the automated tests. These tests run with the latest available version of Nextflow and the minimum version required by the pipeline code.

### Add a new pipeline step

To contribute a new step to the pipeline:

- [ ] Define the corresponding [input channel](#channel-naming-schemes) into your new process from the expected previous process channel.
- [ ] Install a module with `nf-core modules install`, or write a local module (see [default processes resource requirements](#default-processes-resource-requirements)), and add it to the target `<workflow>.nf`. Do not edit files under `modules/nf-core/`; set tool options in `conf/modules.config` instead.
- [ ] Define the output channel if needed. Mix the version output channel into `ch_versions` and relevant files into `ch_multiqc`.
- [ ] Add new or updated parameters to `nextflow.config` with a [default value](#default-parameter-values).
- [ ] Add new or updated parameters and relevant help text to `nextflow_schema.json`.
- [ ] Add validation for relevant parameters to the pipeline utilities section of the `subworkflows/local/utils_nfcore_plantgwas_pipeline/main.nf` subworkflow.
- [ ] Perform local tests to validate that the new code works as expected.
  - [ ] If applicable, add a new test in the `tests` directory.
- [ ] Update `usage.md`, `output.md`, and `CITATIONS.md` as appropriate.
- [ ] [Lint](#lint-tests) the code.
- [ ] Update any diagrams or pipeline images as necessary.
- [ ] Update the MultiQC config `assets/multiqc_config.yml` so relevant suffixes, file name cleanup, and module plots are in the appropriate order.
- [ ] If applicable, create a [MultiQC](https://seqera.io/multiqc/) module.
- [ ] Add a description of the output files and, if relevant, images from the MultiQC report to `docs/output.md`.

To update the minimum required Nextflow version, see [Nextflow version bumping](#nextflow-version-bumping).

### Channel naming schemes

Use the following naming schemes for channels to make the channel flow easier to understand:

- Initial process channel: `ch_output_from_<process>`
- Intermediate and terminal channels: `ch_<previousprocess>_for_<nextprocess>`

### Default parameter values

Parameters should be initialised and defined with default values within the `params` scope in `nextflow.config`. They should also be documented in the pipeline JSON schema.

To update `nextflow_schema.json`, run:

```bash
nf-core pipelines schema build
```

The schema builder interface that loads in your browser should automatically update the defaults in the parameter documentation.

### Default processes resource requirements

If you write a local module, specify a default set of resource requirements for the process.

Sensible defaults for process resource requirements (CPUs, memory, time) are defined in `conf/base.config`. Specify these with generic `withLabel:` selectors, so they can be shared across multiple processes and steps of the pipeline.

Use the standard labels from the template (`process_single`, `process_low`, `process_medium`, `process_high`, and so on) where possible. They define resource defaults for single-core processes, for modules that require a GPU, and for different levels of multi-core configurations with increasing memory requirements.

Values assigned within these labels can be passed to a tool using the `${task.cpus}` and `${task.memory}` Nextflow variables in the `script:` block of a module. The installed `modules/nf-core/bcftools/view/main.nf` is an example.

### Nextflow version bumping

If you use a new feature from core Nextflow, bump the minimum required Nextflow version in the pipeline with:

```bash
nf-core pipelines bump-version --nextflow . <min_nf_version>
```

### Images and figures

Keep figures in `docs/images/`. Prefer SVG, or PNG at a readable size, and check that they are legible on both light and dark GitHub themes.
