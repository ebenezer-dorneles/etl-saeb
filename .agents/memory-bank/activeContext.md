# Active Context & Project Status

## Current State
- Codebase refactored into a 4-stage modular architecture.
- Modular feature engineering layer created under `R/feature_engineering/`.
- Pre-processed HLM dataset (`base_hlm`) persisted in DuckDB (`data/db/saeb_sul_2023.duckdb`).
- Sequenced scripts created: `01_pipeline_raw.R`, `02_build_features.R`, `03_aed.R`, `04_modeling_hlm.R`.
- HLM model results and research limitations/paths fully documented in `outputs/02_resultados_e_caminhos.md`.
- **"Paradoxo do indicador de violência docente" resolvido (2026-08-01):** causa raiz era um erro de classificação de itens em `recode_professores.R` (já corrigido no commit `c2d09f4`), não confundimento residual. Pipeline recalculado (`base_hlm` regenerado); com os itens corretos, `idx_violencia_escola` tem efeito negativo (significativo em MT, p=0,023; direção correta mas n.s. em LP) e `idx_clima_escola` tem efeito positivo forte (p<0,001 em ambas). Detalhes completos, incluindo as hipóteses de viés de seleção (2B) e outliers (2C) testadas e descartadas como causa, em `outputs/03_paradoxo_violencia_docente.md`.
- Documentation (`README.md`, `outputs/01_tratamento_de_dados.md`, `outputs/02_resultados_e_caminhos.md`, `outputs/mngV1.md` & Memory Bank) atualizada para refletir os números corrigidos.

## Active Focus
- Maintain accurate synchronization between data queries, scripts, and documentation (`questions.md` / `README.md`).
- Address memory-bank research path checklist items as new phases are requested.
- Revisar o texto da monografia (fora deste repositório, se houver) que ainda cite os coeficientes antigos de violência/clima (+0,80 / +1,49) — precisam ser substituídos pelos valores corrigidos.

