# Tech Context & Dependencies

## R Package Dependencies (`renv`)
- `DBI`, `duckdb`, `dbplyr`
- `dplyr`, `tidyr`, `ggplot2`, `scales`, `forcats`
- `psych` (EFA / Cronbach's Alpha)
- `lme4`, `lmerTest` (Hierarchical Linear Models)
- `performance` (ICC, R-squared metrics)
- `broom.mixed` (Tidy model summaries)

## Environment Requirements
- Local R runtime with DuckDB support.
- Local storage for microdata in `data/db/saeb_sul_2023.duckdb`.
