# =============================================================================
# ANÁLISE EXPLORATÓRIA — NÍVEL 1 (ALUNO)
# =============================================================================
# Caracteriza a variável dependente e os preditores de nível 1 usados no
# M1/M2, incluindo gaps de desempenho por subgrupo (tamanho de efeito) e a
# relação bivariada entre percepção de ambiente e proficiência — insumo para
# as seções 4.1/4.3/5.4 da monografia.
# =============================================================================

source("R/packages.R")

DB_PATH <- "data/db/saeb_sul_2023.duckdb"

if (!file.exists(DB_PATH)) {
  stop("Erro: Banco ", DB_PATH, " não encontrado. Execute o scripts/02_build_features.R primeiro.")
}

fs::dir_create("outputs")

con <- DBI::dbConnect(duckdb::duckdb(), DB_PATH, read_only = TRUE)

cli::cli_h1("AED — Nível Aluno")

# -----------------------------------------------------------------------------
# 1. CARREGAMENTO
# -----------------------------------------------------------------------------
cli::cli_h2("1. Carregamento")

base_hlm <- tbl(con, "base_hlm") |> collect()

DBI::dbDisconnect(con, shutdown = TRUE)

cli::cli_alert_info(glue::glue("{nrow(base_hlm)} alunos em {length(unique(base_hlm$ID_ESCOLA))} escolas."))

# -----------------------------------------------------------------------------
# 2. DISTRIBUIÇÃO DA PROFICIÊNCIA
# -----------------------------------------------------------------------------
cli::cli_h2("2. Distribuição da proficiência (LP e MT)")

print(summary(base_hlm[, c("proficiencia_lp", "proficiencia_mt")]))

p_prof <- base_hlm |>
  dplyr::select(ID_UF, proficiencia_lp, proficiencia_mt) |>
  tidyr::pivot_longer(c(proficiencia_lp, proficiencia_mt), names_to = "disciplina", values_to = "proficiencia") |>
  ggplot(aes(x = proficiencia, fill = ID_UF)) +
  geom_density(alpha = 0.5) +
  facet_wrap(~disciplina, scales = "free") +
  scale_fill_brewer(palette = "Set2", name = "UF") +
  labs(title = "Distribuição da proficiência por disciplina e UF", x = "Proficiência (escala SAEB)", y = "Densidade") +
  theme_minimal()

ggsave("outputs/fig_03d_distribuicao_proficiencia.png", p_prof, width = 10, height = 5, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03d_distribuicao_proficiencia.png")

# -----------------------------------------------------------------------------
# 3. GAPS DE DESEMPENHO POR SUBGRUPO (TAMANHO DE EFEITO)
# -----------------------------------------------------------------------------
cli::cli_h2("3. Gaps de desempenho por subgrupo (Cohen's d)")

cohens_d <- function(x, g) {
  g <- as.factor(g)
  grupos <- levels(g)
  x1 <- x[g == grupos[1]]
  x2 <- x[g == grupos[2]]
  n1 <- length(x1); n2 <- length(x2)
  sd_pooled <- sqrt(((n1 - 1) * var(x1, na.rm = TRUE) + (n2 - 1) * var(x2, na.rm = TRUE)) / (n1 + n2 - 2))
  (mean(x1, na.rm = TRUE) - mean(x2, na.rm = TRUE)) / sd_pooled
}

subgrupos <- list(
  raca_branca = c("0" = "Não-branca", "1" = "Branca"),
  sexo        = c("0" = "Masculino", "1" = "Feminino"),
  trabalha    = NULL,
  reprovado   = c("0" = "Não reprovou", "1" = "Já reprovou")
)

gaps <- purrr::map_dfr(c("raca_branca", "sexo", "reprovado"), function(var) {
  dplyr::tibble(
    variavel = var,
    d_lp = cohens_d(base_hlm$proficiencia_lp, base_hlm[[var]]),
    d_mt = cohens_d(base_hlm$proficiencia_mt, base_hlm[[var]])
  )
})

print(gaps)

tab_medias <- base_hlm |>
  dplyr::select(raca_branca, sexo, reprovado, proficiencia_lp, proficiencia_mt) |>
  tidyr::pivot_longer(c(raca_branca, sexo, reprovado), names_to = "variavel", values_to = "grupo") |>
  dplyr::group_by(variavel, grupo) |>
  dplyr::summarise(
    media_lp = mean(proficiencia_lp, na.rm = TRUE),
    media_mt = mean(proficiencia_mt, na.rm = TRUE),
    n = dplyr::n(),
    .groups = "drop"
  )

print(tab_medias)

# -----------------------------------------------------------------------------
# 4. PERCEPÇÃO DE AMBIENTE (ALUNO) X PROFICIÊNCIA
# -----------------------------------------------------------------------------
cli::cli_h2("4. Percepção de ambiente do aluno x proficiência")

base_hlm_tercil <- base_hlm |>
  dplyr::mutate(
    tercil_ambiente = dplyr::ntile(idx_ambiente_aluno, 3),
    tercil_ambiente = factor(tercil_ambiente, levels = 1:3, labels = c("Baixo", "Médio", "Alto"))
  )

tab_tercil <- base_hlm_tercil |>
  dplyr::group_by(tercil_ambiente) |>
  dplyr::summarise(
    media_lp = mean(proficiencia_lp, na.rm = TRUE),
    media_mt = mean(proficiencia_mt, na.rm = TRUE),
    n = dplyr::n(),
    .groups = "drop"
  )
print(tab_tercil)

p_ambiente <- base_hlm |>
  dplyr::select(idx_ambiente_aluno, proficiencia_lp, proficiencia_mt) |>
  tidyr::pivot_longer(c(proficiencia_lp, proficiencia_mt), names_to = "disciplina", values_to = "proficiencia") |>
  ggplot(aes(x = idx_ambiente_aluno, y = proficiencia)) +
  geom_point(alpha = 0.05, size = 0.5) +
  geom_smooth(method = "loess", color = "#D55E00", se = TRUE) +
  facet_wrap(~disciplina, scales = "free_y") +
  labs(
    title = "Percepção de ambiente do aluno x proficiência",
    x = "Índice de ambiente (percepção do aluno)", y = "Proficiência"
  ) +
  theme_minimal()

ggsave("outputs/fig_03d_ambiente_aluno_vs_proficiencia.png", p_ambiente, width = 10, height = 5, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03d_ambiente_aluno_vs_proficiencia.png")

# -----------------------------------------------------------------------------
# 5. MATRIZ DE CORRELAÇÃO ENTRE PREDITORES DE NÍVEL 1
# -----------------------------------------------------------------------------
cli::cli_h2("5. Matriz de correlação entre preditores de nível 1")

vars_nivel1 <- c(
  "proficiencia_lp", "proficiencia_mt", "inse", "idx_ambiente_aluno",
  "escol_mae", "eng_pais", "sexo", "raca_branca", "reprovado", "trabalha"
)

mat_cor1 <- cor(base_hlm[, vars_nivel1], use = "pairwise.complete.obs")
print(round(mat_cor1, 3))

cor_df1 <- as.data.frame(as.table(mat_cor1))
names(cor_df1) <- c("var1", "var2", "correlacao")

p_cor1 <- ggplot(cor_df1, aes(x = var1, y = var2, fill = correlacao)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(correlacao, 2)), size = 2.8) +
  scale_fill_gradient2(low = "#B2182B", mid = "white", high = "#2166AC", midpoint = 0, limits = c(-1, 1)) +
  labs(title = "Correlação entre preditores de nível 1", x = NULL, y = NULL) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/fig_03d_matriz_correlacao_nivel1.png", p_cor1, width = 8, height = 7, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03d_matriz_correlacao_nivel1.png")

# -----------------------------------------------------------------------------
# 6. INSE INDIVIDUAL X PERCEPÇÃO DE AMBIENTE
# -----------------------------------------------------------------------------
cli::cli_h2("6. INSE individual x percepção de ambiente")

tab_inse <- base_hlm |>
  dplyr::group_by(inse) |>
  dplyr::summarise(
    media_ambiente = mean(idx_ambiente_aluno, na.rm = TRUE),
    n = dplyr::n(),
    .groups = "drop"
  )
print(tab_inse)

cli::cli_h1("✅ AED — Nível Aluno concluída")
