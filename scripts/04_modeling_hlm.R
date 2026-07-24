# =============================================================================
# MODELAGEM MULTINÍVEL (HLM) — SAEB 2023 | REGIÃO SUL | ENSINO MÉDIO
# =============================================================================
# Lê a tabela 'base_hlm' pré-processada do DuckDB e estima os modelos M0 a M5
# para Língua Portuguesa e Matemática.
# =============================================================================

source("R/packages.R")

dir.create("outputs", showWarnings = FALSE)
DB_PATH <- "data/db/saeb_sul_2023.duckdb"

if (!file.exists(DB_PATH)) {
  stop("Erro: Banco ", DB_PATH, " não encontrado. Execute o scripts/02_build_features.R primeiro.")
}

cli::cli_h1("Iniciando Modelagem Multinível (HLM)")

# -----------------------------------------------------------------------------
# 1. CARREGAMENTO DA BASE HLM DO DUCKDB
# -----------------------------------------------------------------------------
con <- DBI::dbConnect(duckdb::duckdb(), DB_PATH, read_only = TRUE)
base_hlm <- tbl(con, "base_hlm") |> collect()
DBI::dbDisconnect(con, shutdown = TRUE)

cli::cli_alert_info(glue::glue("Base HLM carregada: {nrow(base_hlm)} alunos em {length(unique(base_hlm$ID_ESCOLA))} escolas."))

# -----------------------------------------------------------------------------
# 2. FUNÇÃO DE AJUSTE DOS MODELOS M0 A M5
# -----------------------------------------------------------------------------
rodar_sequencia_hlm <- function(df, dep_var = "proficiencia_lp") {
  
  f_m0 <- as.formula(paste(dep_var, "~ 1 + (1 | ID_ESCOLA)"))
  f_m1 <- as.formula(paste(dep_var, "~ inse + sexo + raca_branca + reprovado + abandonou + trabalha + escol_mae + eng_pais + (1 | ID_ESCOLA)"))
  f_m2 <- as.formula(paste(dep_var, "~ inse + sexo + raca_branca + reprovado + abandonou + trabalha + escol_mae + eng_pais + idx_ambiente_aluno + (1 | ID_ESCOLA)"))
  f_m3 <- as.formula(paste(dep_var, "~ inse + sexo + raca_branca + reprovado + abandonou + trabalha + escol_mae + eng_pais + idx_ambiente_aluno + inse_escola + publica + rural + form_doc + ln_n_alunos + idx_violencia_escola + idx_clima_escola + (1 | ID_ESCOLA)"))
  f_m4 <- as.formula(paste(dep_var, "~ inse + sexo + raca_branca + reprovado + abandonou + trabalha + escol_mae + eng_pais + idx_ambiente_aluno + inse_escola + publica + rural + form_doc + ln_n_alunos + idx_violencia_escola + idx_clima_escola + (1 + idx_ambiente_aluno | ID_ESCOLA)"))

  cli::cli_h2(glue::glue("Ajustando modelos para: {dep_var}"))
  
  m0 <- lmer(f_m0, data = df, REML = FALSE)
  m1 <- lmer(f_m1, data = df, REML = FALSE)
  m2 <- lmer(f_m2, data = df, REML = FALSE)
  m3 <- lmer(f_m3, data = df, REML = FALSE)
  m4 <- suppressWarnings(lmer(f_m4, data = df, REML = FALSE))

  icc_val <- performance::icc(m0)$ICC_conditional

  return(list(
    m0 = m0, m1 = m1, m2 = m2, m3 = m3, m4 = m4,
    icc = icc_val
  ))
}

# -----------------------------------------------------------------------------
# 3. EXECUÇÃO PARA LÍNGUA PORTUGUESA E MATEMÁTICA
# -----------------------------------------------------------------------------
res_lp <- rodar_sequencia_hlm(base_hlm, "proficiencia_lp")
res_mt <- rodar_sequencia_hlm(base_hlm, "proficiencia_mt")

cli::cli_h2("Resultados Principais:")
cat("ICC Língua Portuguesa: ", round(res_lp$icc, 3), "\n")
cat("ICC Matemática:        ", round(res_mt$icc, 3), "\n")

# -----------------------------------------------------------------------------
# 4. GERAR GRÁFICO DE COEFICIENTES DO MODELO M3 (LP)
# -----------------------------------------------------------------------------
coef_m3_lp <- broom.mixed::tidy(res_lp$m3, effects = "fixed") |>
  dplyr::filter(term != "(Intercept)") |>
  dplyr::mutate(
    term = dplyr::recode(term,
      "idx_ambiente_aluno"   = "Percepção ambiente (aluno)",
      "idx_violencia_escola" = "Violência escola (prof. agreg.)",
      "idx_clima_escola"     = "Clima relacional (prof. agreg.)",
      "inse"                 = "INSE (aluno)",
      "inse_escola"          = "INSE médio da escola",
      "publica"              = "Escola pública",
      "rural"                = "Escola rural",
      "form_doc"             = "% Docentes form. adequada",
      "ln_n_alunos"          = "Porte da escola (log n)",
      "sexo"                 = "Sexo (Feminino=1)",
      "raca_branca"          = "Raça (Branca=1)",
      "reprovado"            = "Já reprovou",
      "abandonou"            = "Já abandonou",
      "trabalha"             = "Trabalha fora",
      "escol_mae"            = "Escolaridade da mãe",
      "eng_pais"             = "Engajamento dos pais"
    )
  )

p_coef <- ggplot(coef_m3_lp, aes(x = estimate, y = reorder(term, estimate))) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray50") +
  geom_point(size = 3, color = "#2c3e50") +
  geom_errorbarh(aes(xmin = estimate - 1.96 * std.error, xmax = estimate + 1.96 * std.error), height = 0.2, color = "#2c3e50") +
  labs(
    title = "Efeitos Fixos no Desempenho em Língua Portuguesa (Modelo M3)",
    subtitle = "SAEB 2023 — Região Sul | Coeficientes com IC 95%",
    x = "Estimativa do Coeficiente (Escala SAEB)",
    y = NULL
  ) +
  theme_minimal()

ggsave("outputs/fig_02_coeficientes_m3_lp.png", p_coef, width = 9, height = 6, dpi = 300)
cli::cli_alert_success("Gráfico de coeficientes salvo em outputs/fig_02_coeficientes_m3_lp.png")

cli::cli_h1("✅ Modelagem Multinível finalizada com sucesso!")
