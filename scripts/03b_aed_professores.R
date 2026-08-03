# =============================================================================
# ANÁLISE EXPLORATÓRIA — QUESTIONÁRIO DOCENTE (VIOLÊNCIA E CLIMA RELACIONAL)
# =============================================================================
# Caracteriza os itens do questionário de professores usados na AFE (violência
# escolar e clima relacional), valida a adequação fatorial (KMO, Bartlett,
# análise paralela) e descreve a distribuição dos índices resultantes — a
# nível de professor e agregados por escola.
# =============================================================================

source("R/packages.R")
source("R/feature_engineering/recode_alunos.R")
source("R/feature_engineering/recode_professores.R")
source("R/feature_engineering/compute_indices.R")

DB_PATH <- "data/db/saeb_sul_2023.duckdb"

if (!file.exists(DB_PATH)) {
  stop("Erro: Banco ", DB_PATH, " não encontrado. Execute o scripts/01_pipeline_raw.R primeiro.")
}

fs::dir_create("outputs")

con <- DBI::dbConnect(duckdb::duckdb(), DB_PATH, read_only = TRUE)

cli::cli_h1("AED — Questionário Docente")

# -----------------------------------------------------------------------------
# 1. CARREGAMENTO E RECODIFICAÇÃO
# -----------------------------------------------------------------------------
cli::cli_h2("1. Carregamento e recodificação")

professores_raw <- tbl(con, "professores") |>
  filter(
    ID_REGIAO == 4,
    ID_UF %in% c(41L, 42L, 43L),
    IN_PREENCHIMENTO_QUESTIONARIO == 1
  ) |>
  collect()

DBI::dbDisconnect(con, shutdown = TRUE)

professores_proc <- process_professores(professores_raw)
professores_df   <- professores_proc$df
itens_violencia  <- professores_proc$itens_violencia
itens_clima      <- professores_proc$itens_clima
todos_itens      <- c(itens_violencia, itens_clima)

cli::cli_alert_info(glue::glue("{nrow(professores_df)} professores respondentes carregados."))

# -----------------------------------------------------------------------------
# 2. DISTRIBUIÇÃO DE RESPOSTAS POR ITEM
# -----------------------------------------------------------------------------
cli::cli_h2("2. Distribuição de respostas por item (1=Nunca/Discordo ... 4=Sempre/Concordo)")

dist_itens <- professores_df |>
  dplyr::select(dplyr::all_of(todos_itens)) |>
  tidyr::pivot_longer(dplyr::everything(), names_to = "item", values_to = "resposta") |>
  dplyr::filter(!is.na(resposta)) |>
  dplyr::count(item, resposta) |>
  dplyr::group_by(item) |>
  dplyr::mutate(
    percentual = n / sum(n),
    dimensao = dplyr::if_else(item %in% itens_violencia, "Violência", "Clima Relacional")
  ) |>
  dplyr::ungroup()

print(dist_itens |> dplyr::arrange(dimensao, item, resposta), n = 100)

p_dist_itens <- dist_itens |>
  ggplot(aes(x = item, y = percentual, fill = factor(resposta))) +
  geom_col(position = "fill") +
  coord_flip() +
  facet_wrap(~dimensao, scales = "free_y") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
  scale_fill_brewer(palette = "RdYlBu", direction = -1, name = "Resposta") +
  labs(
    title = "Distribuição de respostas por item — questionário docente",
    x = NULL, y = "Percentual"
  ) +
  theme_minimal()

ggsave("outputs/fig_03b_distribuicao_itens.png", p_dist_itens, width = 10, height = 6, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03b_distribuicao_itens.png")

# -----------------------------------------------------------------------------
# 3. ADEQUAÇÃO FATORIAL (KMO, BARTLETT, ANÁLISE PARALELA)
# -----------------------------------------------------------------------------
cli::cli_h2("3. Adequação fatorial")

mat_prof <- professores_df[, todos_itens] |> na.omit()
cli::cli_alert_info(glue::glue("Matriz completa (listwise) para diagnóstico: {nrow(mat_prof)} professores."))

kmo_result <- psych::KMO(mat_prof)
print(kmo_result)

bartlett_result <- psych::cortest.bartlett(cor(mat_prof), n = nrow(mat_prof))
print(bartlett_result)

png("outputs/fig_03b_analise_paralela.png", width = 900, height = 700, res = 150)
parallel_result <- psych::fa.parallel(mat_prof, fm = "ml", fa = "fa", n.iter = 20)
dev.off()
cli::cli_alert_success("Figura salva: outputs/fig_03b_analise_paralela.png")
cli::cli_alert_info(glue::glue("Análise paralela sugere {parallel_result$nfact} fator(es) (modelo usa 2, por dimensão teórica)."))

# -----------------------------------------------------------------------------
# 4. CONSISTÊNCIA INTERNA (ALFA DE CRONBACH)
# -----------------------------------------------------------------------------
cli::cli_h2("4. Consistência interna por subescala")

alpha_violencia <- psych::alpha(professores_df[, itens_violencia], check.keys = TRUE)
alpha_clima     <- psych::alpha(professores_df[, itens_clima], check.keys = TRUE)

cli::cli_alert_info(glue::glue(
  "Alfa de Cronbach — Violência ({length(itens_violencia)} itens): {round(alpha_violencia$total$raw_alpha, 3)}"
))
cli::cli_alert_info(glue::glue(
  "Alfa de Cronbach — Clima Relacional ({length(itens_clima)} itens): {round(alpha_clima$total$raw_alpha, 3)}"
))

# -----------------------------------------------------------------------------
# 5. ÍNDICES FATORIAIS: DISTRIBUIÇÃO A NÍVEL DE PROFESSOR E DE ESCOLA
# -----------------------------------------------------------------------------
cli::cli_h2("5. Índices fatoriais (AFE)")

teacher_results     <- compute_teacher_indices(professores_proc)
professores_scored  <- teacher_results$professores_df
prof_escola         <- teacher_results$prof_escola

print(summary(professores_scored[, c("idx_violencia_prof", "idx_clima_prof")]))

p_idx_prof <- professores_scored |>
  dplyr::select(idx_violencia_prof, idx_clima_prof) |>
  tidyr::pivot_longer(dplyr::everything(), names_to = "indice", values_to = "escore") |>
  dplyr::filter(!is.na(escore)) |>
  ggplot(aes(x = escore, fill = indice)) +
  geom_density(alpha = 0.6) +
  facet_wrap(~indice, scales = "free") +
  scale_fill_brewer(palette = "Set2") +
  labs(
    title = "Distribuição dos escores fatoriais (nível professor)",
    x = "Escore fatorial", y = "Densidade"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("outputs/fig_03b_indices_professor.png", p_idx_prof, width = 9, height = 5, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03b_indices_professor.png")

cli::cli_h2("5.1 Correlação entre os índices agregados por escola")
cor_idx <- cor(prof_escola$idx_violencia_escola, prof_escola$idx_clima_escola, use = "complete.obs")
cli::cli_alert_info(glue::glue("Correlação idx_violencia_escola x idx_clima_escola: {round(cor_idx, 3)}"))

# -----------------------------------------------------------------------------
# 6. RESPONDENTES POR ESCOLA (SUPORTE À ANÁLISE DE VIÉS DE SELEÇÃO)
# -----------------------------------------------------------------------------
cli::cli_h2("6. Número de professores respondentes por escola")

print(summary(prof_escola$n_professores))

tab_n_prof <- prof_escola |>
  dplyr::mutate(faixa = dplyr::case_when(
    n_professores == 1    ~ "1",
    n_professores == 2    ~ "2",
    n_professores %in% 3:5 ~ "3-5",
    n_professores > 5     ~ "6+"
  )) |>
  dplyr::count(faixa) |>
  dplyr::mutate(percentual = scales::percent(n / sum(n)))

print(tab_n_prof)

p_n_prof <- prof_escola |>
  ggplot(aes(x = n_professores)) +
  geom_histogram(binwidth = 1, fill = "#4C72B0", color = "white") +
  labs(
    title = "Professores respondentes por escola",
    x = "Nº de professores respondentes", y = "Nº de escolas"
  ) +
  theme_minimal()

ggsave("outputs/fig_03b_n_professores_por_escola.png", p_n_prof, width = 8, height = 5, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03b_n_professores_por_escola.png")

cli::cli_h1("✅ AED — Questionário Docente concluída")
