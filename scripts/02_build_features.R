# =============================================================================
# FEATURE ENGINEERING PIPELINE — SAEB 2023 | REGIÃO SUL
# =============================================================================
# Lê as tabelas brutas do DuckDB, executa tratamentos, recodificações,
# AFE de professores e persiste a base pronta para modelagem no DuckDB.
# =============================================================================

source("R/packages.R")
source("R/feature_engineering/recode_alunos.R")
source("R/feature_engineering/recode_professores.R")
source("R/feature_engineering/compute_indices.R")

DB_PATH <- "data/db/saeb_sul_2023.duckdb"

if (!file.exists(DB_PATH)) {
  stop("Erro: Banco ", DB_PATH, " não encontrado. Execute o scripts/01_pipeline_raw.R primeiro.")
}

cli::cli_h1("Iniciando Feature Engineering Pipeline")

con <- DBI::dbConnect(duckdb::duckdb(), DB_PATH)

cli::cli_h2("1. Carregando dados brutos do DuckDB")
alunos_raw <- tbl(con, "alunos") |>
  filter(
    ID_REGIAO == 4,
    ID_UF %in% c(41L, 42L, 43L),
    IN_PRESENCA_LP == 1,
    IN_PRESENCA_MT == 1,
    IN_PROFICIENCIA_LP == 1,
    IN_PREENCHIMENTO_QUESTIONARIO == 1
  ) |>
  collect()

professores_raw <- tbl(con, "professores") |>
  filter(
    ID_REGIAO == 4,
    ID_UF %in% c(41L, 42L, 43L),
    IN_PREENCHIMENTO_QUESTIONARIO == 1
  ) |>
  collect()

escolas_raw <- tbl(con, "escolas") |>
  filter(
    ID_REGIAO == 4,
    ID_UF %in% c(41L, 42L, 43L)
  ) |>
  collect()

cli::cli_h2("2. Recodificando dados dos alunos")
alunos_clean <- process_alunos(alunos_raw)

cli::cli_h2("3. Processando dados de professores e AFE")
professores_proc <- process_professores(professores_raw)
teacher_results  <- compute_teacher_indices(professores_proc)
prof_escola      <- teacher_results$prof_escola

cli::cli_h2("4. Recodificando dados das escolas")
escolas_clean <- process_escolas(escolas_raw)

cli::cli_h2("5. Construindo base final HLM e aplicando filtragem listwise")
base_hlm_raw <- alunos_clean |>
  dplyr::inner_join(escolas_clean, by = "ID_ESCOLA") |>
  dplyr::left_join(prof_escola,   by = "ID_ESCOLA")

vars_modelo <- c(
  "proficiencia_lp", "proficiencia_mt",
  "idx_ambiente_aluno", "inse", "sexo", "raca_branca",
  "reprovado", "abandonou", "trabalha", "escol_mae", "eng_pais",
  "inse_escola", "publica", "rural", "form_doc", "ln_n_alunos",
  "idx_violencia_escola", "idx_clima_escola"
)

base_hlm <- base_hlm_raw |>
  tidyr::drop_na(dplyr::all_of(vars_modelo))

cli::cli_alert_success(glue::glue("Base HLM construída com {nrow(base_hlm)} alunos e {length(unique(base_hlm$ID_ESCOLA))} escolas."))

cli::cli_h2("6. Gravando tabelas processadas no DuckDB")
DBI::dbWriteTable(con, "base_hlm", base_hlm, overwrite = TRUE)
DBI::dbWriteTable(con, "professores_escola", prof_escola, overwrite = TRUE)

DBI::dbDisconnect(con, shutdown = TRUE)

cli::cli_h1("✅ Feature Engineering concluído com sucesso!")
