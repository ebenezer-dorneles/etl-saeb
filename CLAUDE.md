# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

R data pipeline and multilevel modeling (HLM) analysis for a graduate thesis (Especialização em Estatística e Modelagem Quantitativa) studying whether perceived school environment (violence, relational climate) is associated with academic performance on SAEB 2023 (INEP/MEC), Região Sul do Brasil (PR, SC, RS). See `README.md` for the full methodology, hypotheses (H1–H3), and variable dictionary — read it before making changes to feature engineering or modeling code, since variable names and model formulas must stay consistent with what's documented there.

## Environment

- R ≥ 4.3, package deps declared in `DESCRIPTION` (Imports) and mirrored in `R/packages.R` (auto-installs anything missing) and `.manifests/r-base/Dockerfile` (apt `r-cran-*` packages). If you add a dependency, update all three.
- `renv/` is present for dependency locking.
- `.env` holds `LINK_SAEB_2023` (loaded via `dotenv::load_dot_env()`); required by `scripts/01_pipeline_raw.R`.
- Docker: `docker-compose.yml` builds `.manifests/r-base` (rocker/r2u base) and mounts the repo at `/workspace`. Run scripts inside it with `docker exec -it r-base Rscript scripts/<script>.R`. This is the expected way to get a reproducible package set including a custom CA cert needed to reach INEP's download servers.

## Commands

Run a script (working directory must be the repo root, scripts use relative paths like `data/db/...`):
```bash
Rscript scripts/01_pipeline_raw.R      # download + ingest raw INEP microdata into DuckDB
Rscript scripts/02_build_features.R    # recoding, EFA, school aggregation -> base_hlm table
Rscript scripts/03_aed.R               # exploratory data analysis
Rscript scripts/04_modeling_hlm.R      # fit HLM models M0-M5, write outputs/
```
Or via Docker: `docker exec -it r-base Rscript scripts/<script>.R`.

Run the full test suite:
```r
testthat::test_dir("tests/testthat")
```
Run a single test file (each test file `source()`s the R file it covers directly, so this works standalone):
```r
testthat::test_file("tests/testthat/test-recode-alunos.R")
```
Note: `tests/testthat.R` references a package named `workspace` via `library(workspace)` / `test_check("workspace")` — this does not match `DESCRIPTION` (`Package: etl.educ`) and is not the way tests are actually run in this repo; use `test_dir`/`test_file` as above.

## Architecture

Four-stage sequential pipeline, each stage reading/writing DuckDB (`data/db/saeb_sul_2023.duckdb`) rather than passing objects in memory between scripts:

1. **`scripts/01_pipeline_raw.R`** — downloads INEP SAEB 2023 microdata zip, unzips, cleans, filters to Região Sul (`ID_REGIAO == 4`, `ID_UF %in% c(41, 42, 43)`), writes raw tables `alunos`, `professores`, `escolas` to DuckDB. Uses `R/utils/download_microdata.R`, `unzip_microdata.R`, `clean_microdata_saeb_2023.R`, `database.R`.
2. **`scripts/02_build_features.R`** — reads raw tables, applies recoding (`R/feature_engineering/recode_alunos.R`, `recode_professores.R`), runs Exploratory Factor Analysis (ML estimation via `psych`) for teacher-reported violence and climate indices (`R/feature_engineering/compute_indices.R`), aggregates teacher indices to the school level (mean), and persists the model-ready `base_hlm` table back to the same DuckDB file.
3. **`scripts/03_aed.R`** — exploratory analysis (read-only DuckDB connection).
4. **`scripts/04_modeling_hlm.R`** — loads `base_hlm`, fits nested `lme4`/`lmerTest` models M0→M5 (null → individual controls → student environment index → school-level controls → random slope → sub-index sensitivity) separately for Língua Portuguesa and Matemática proficiency, writes figures/tables to `outputs/`.

Shared code lives under `R/`:
- `R/packages.R` — single source of truth for package list; installs anything missing then loads all via `library()`. Sourced at the top of every script.
- `R/utils/` — I/O and infra helpers (HTTP download with retry via `httr2`, zip extraction, microdata cleaning, DuckDB table save/index via `save_table()`).
- `R/feature_engineering/` — pure(r) transformation functions (letter/roman-numeral recoding, score inversion, EFA, school-level aggregation) that are unit tested independently of the pipeline scripts.

Downstream stages assume upstream DuckDB tables already exist and `stop()` early with a Portuguese error message if the expected `.duckdb` file is missing (e.g. run `01_pipeline_raw.R` before `02_build_features.R`).

`data/db/` holds two DuckDB files — `saeb_sul_2023.duckdb` (the active SAEB pipeline output above) and `educ_sul.duckdb` (older/other dataset) — don't confuse them.

## Conventions

- Scripts and most in-code messages/comments are in Portuguese (pt-BR); match this when editing script bodies, `cli::cli_h1/h2` section headers, and error messages. Code identifiers mix English (function/file names) and Portuguese (variable/column names matching INEP's dictionary, e.g. `ID_REGIAO`, `idx_violencia_escola`).
- Tables are always written idempotently: `save_table()` drops-and-recreates rather than appending, so re-running a stage is safe.
- Tests `source(here::here("R/..."))` the single file under test rather than loading the package — keep new test files following that pattern, and use `here::here()` for paths so tests work regardless of invocation directory.
- Conventional commit scopes in use: `data`, `escolas` (see `.vscode/settings.json`); recent commit history also uses scopes like `compute-indices`, `recode-professores`, `progress`.
- A memory bank at `.agents/memory-bank/` (`activeContext.md`, `progress.md`, `systemPatterns.md`) tracks project state, milestones, and architecture from the agent's perspective — check it for current focus/open threads and keep it updated when completing significant milestones, same spirit as this file but project-status-oriented rather than static reference.
