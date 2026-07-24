# System Architecture & Technical Structure

## Technology Stack
- **Language**: R (using `renv` for package dependency management)
- **Database Engine**: DuckDB (`duckdb`, `DBI`, `dbplyr`)
- **Data Manipulation**: `tidyverse` (`dplyr`, `tidyr`, `forcats`, `scales`)
- **Psychometrics & Factor Analysis**: `psych` (Exploratory Factor Analysis with ML estimation)
- **Multilevel Modeling**: `lme4`, `lmerTest`, `performance`, `broom.mixed`
- **Data Visualization**: `ggplot2`

## Modular Pipeline Architecture
1. `R/`: Centralized R modules:
   - `R/packages.R`: Package dependency manager.
   - `R/feature_engineering/recode_alunos.R`: Student recoding & scale functions.
   - `R/feature_engineering/recode_professores.R`: Teacher questionnaire item recoding.
   - `R/feature_engineering/compute_indices.R`: EFA (Violence & Climate) factor scores & school aggregations.
   - `R/utils/`: Ingestion, HTTP download, unzipping, and database helper functions.
2. `scripts/01_pipeline_raw.R`: Downloads raw INEP SAEB 2023 CSV files, filters Southern region (`ID_REGIAO == 4`), and writes raw tables (`alunos`, `professores`, `escolas`) to DuckDB (`data/db/saeb_sul_2023.duckdb`).
3. `scripts/02_build_features.R`: Feature engineering pipeline. Loads raw tables, applies recoding and EFA, computes school aggregates, and persists the clean `base_hlm` dataset in DuckDB.
4. `scripts/03_aed.R`: Exploratory data analysis scripts focused on school location, school type, administrative status, and student INSE levels.
5. `scripts/04_modeling_hlm.R`: Central multilevel modeling pipeline:
   - Loads pre-processed `base_hlm` directly from DuckDB.
   - Estimates HLM models M0 to M5 for LP and MT proficiencies.
   - Generates summary statistics and diagnostic figures in `outputs/`.
