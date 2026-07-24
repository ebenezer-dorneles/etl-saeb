# System Architecture & Technical Structure

## Technology Stack
- **Language**: R (using `renv` for package dependency management)
- **Database Engine**: DuckDB (`duckdb`, `DBI`, `dbplyr`)
- **Data Manipulation**: `tidyverse` (`dplyr`, `tidyr`, `forcats`, `scales`)
- **Psychometrics & Factor Analysis**: `psych` (Exploratory Factor Analysis with ML estimation)
- **Multilevel Modeling**: `lme4`, `lmerTest`, `performance`, `broom.mixed`
- **Data Visualization**: `ggplot2`

## Data Pipeline Architecture
1. `scripts/pipeline.R`: Downloads raw INEP SAEB 2023 CSV files, filters Southern region (`ID_REGIAO == 4`), and writes tables (`alunos`, `professores`, `escolas`) to DuckDB (`data/db/saeb_sul_2023.duckdb`).
2. `scripts/aed.R`: Exploratory data analysis scripts focused on school location (Urban/Rural), school type (Tradicional/Integrado), administrative status (Public/Private), and student INSE levels.
3. `scripts/professores.R` / `scripts/diagnostico_nas.R`: Diagnostics on missing values, item recoding, and teacher questionnaire factor analysis.
4. `scripts/main.R`: Central modeling pipeline:
   - Recodes items & scales.
   - Fits Exploratory Factor Analysis (EFA) for climate & violence indices.
   - Merges student, teacher, and school level metrics into a unified HLM dataset with consistent listwise deletion across nested models.
   - Estimates HLM models M0 to M5 for LP and MT proficiencies.
   - Generates summary tables and diagnostic figures into `outputs/`.
