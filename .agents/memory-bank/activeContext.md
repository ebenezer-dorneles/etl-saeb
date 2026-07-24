# Active Context & Project Status

## Current State
- Codebase refactored into a 4-stage modular architecture.
- Modular feature engineering layer created under `R/feature_engineering/`.
- Pre-processed HLM dataset (`base_hlm`) persisted in DuckDB (`data/db/saeb_sul_2023.duckdb`).
- Sequenced scripts created: `01_pipeline_raw.R`, `02_build_features.R`, `03_aed.R`, `04_modeling_hlm.R`.
- Documentation (`README.md` & Memory Bank) updated.

## Active Focus
- Maintain accurate synchronization between data queries, scripts, and documentation (`questions.md` / `README.md`).
- Ensure robust HLM modeling with listwise deletion across nested models M0–M5.
