# =============================================================================
# ANÁLISE EXPLORATÓRIA — NÍVEL 2 (ESCOLA)
# =============================================================================
# Caracteriza os preditores de nível 2 usados no M3/M4 (INSE médio, formação
# docente, porte, localização, índices de violência/clima) e sua relação com
# a proficiência média por escola — insumo para as seções 4.1/4.4/5.1/5.2 da
# monografia.
# =============================================================================

source("R/packages.R")

DB_PATH <- "data/db/saeb_sul_2023.duckdb"

if (!file.exists(DB_PATH)) {
  stop("Erro: Banco ", DB_PATH, " não encontrado. Execute o scripts/02_build_features.R primeiro.")
}

fs::dir_create("outputs")

con <- DBI::dbConnect(duckdb::duckdb(), DB_PATH, read_only = TRUE)

cli::cli_h1("AED — Nível Escola")

# -----------------------------------------------------------------------------
# 1. CARREGAMENTO E AGREGAÇÃO POR ESCOLA
# -----------------------------------------------------------------------------
cli::cli_h2("1. Carregamento e agregação por escola")

base_hlm <- tbl(con, "base_hlm") |> collect()

DBI::dbDisconnect(con, shutdown = TRUE)

escolas_df <- base_hlm |>
  dplyr::group_by(ID_ESCOLA) |>
  dplyr::summarise(
    n_alunos_amostra   = dplyr::n(),
    proficiencia_lp    = mean(proficiencia_lp, na.rm = TRUE),
    proficiencia_mt    = mean(proficiencia_mt, na.rm = TRUE),
    inse_escola        = dplyr::first(inse_escola),
    publica            = dplyr::first(publica),
    rural              = dplyr::first(rural),
    form_doc           = dplyr::first(form_doc),
    ln_n_alunos        = dplyr::first(ln_n_alunos),
    idx_violencia_escola = dplyr::first(idx_violencia_escola),
    idx_clima_escola   = dplyr::first(idx_clima_escola),
    .groups = "drop"
  ) |>
  dplyr::mutate(
    rural_lbl = dplyr::if_else(rural == 1, "Rural", "Urbana")
  )

cli::cli_alert_info(glue::glue("{nrow(escolas_df)} escolas na base final (base_hlm)."))

# -----------------------------------------------------------------------------
# 2. DISTRIBUIÇÃO DOS PREDITORES DE NÍVEL 2
# -----------------------------------------------------------------------------
cli::cli_h2("2. Distribuição dos preditores de nível 2")

vars_nivel2 <- c("inse_escola", "form_doc", "ln_n_alunos", "idx_violencia_escola", "idx_clima_escola")

print(summary(escolas_df[, vars_nivel2]))

p_dist_nivel2 <- escolas_df |>
  dplyr::select(dplyr::all_of(vars_nivel2)) |>
  tidyr::pivot_longer(dplyr::everything(), names_to = "variavel", values_to = "valor") |>
  ggplot(aes(x = valor, fill = variavel)) +
  geom_histogram(bins = 30, color = "white") +
  facet_wrap(~variavel, scales = "free") +
  scale_fill_brewer(palette = "Set3") +
  labs(title = "Distribuição dos preditores de nível 2 (por escola)", x = NULL, y = "Nº de escolas") +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("outputs/fig_03c_distribuicao_nivel2.png", p_dist_nivel2, width = 10, height = 6, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03c_distribuicao_nivel2.png")

cli::cli_h2("2.1 Localização (rural x urbana) e rede (pública x privada)")
tab_rural <- escolas_df |>
  dplyr::count(rural_lbl) |>
  dplyr::mutate(percentual = scales::percent(n / sum(n)))
print(tab_rural)

tab_publica <- escolas_df |>
  dplyr::count(publica) |>
  dplyr::mutate(percentual = scales::percent(n / sum(n)))
print(tab_publica)

# -----------------------------------------------------------------------------
# 3. MATRIZ DE CORRELAÇÃO ENTRE PREDITORES DE NÍVEL 2 E PROFICIÊNCIA MÉDIA
# -----------------------------------------------------------------------------
cli::cli_h2("3. Matriz de correlação (nível 2)")

vars_cor <- c("proficiencia_lp", "proficiencia_mt", vars_nivel2)
mat_cor <- cor(escolas_df[, vars_cor], use = "pairwise.complete.obs")
print(round(mat_cor, 3))

cor_df <- as.data.frame(as.table(mat_cor))
names(cor_df) <- c("var1", "var2", "correlacao")

p_cor <- ggplot(cor_df, aes(x = var1, y = var2, fill = correlacao)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(correlacao, 2)), size = 3) +
  scale_fill_gradient2(low = "#B2182B", mid = "white", high = "#2166AC", midpoint = 0, limits = c(-1, 1)) +
  labs(title = "Correlação entre preditores de nível 2 e proficiência média por escola", x = NULL, y = NULL) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("outputs/fig_03c_matriz_correlacao.png", p_cor, width = 8, height = 7, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03c_matriz_correlacao.png")

# -----------------------------------------------------------------------------
# 4. PROFICIÊNCIA MÉDIA X ÍNDICES DE NÍVEL 2 (DISPERSÃO)
# -----------------------------------------------------------------------------
cli::cli_h2("4. Proficiência média x índices de nível 2")

p_scatter <- escolas_df |>
  dplyr::select(ID_ESCOLA, proficiencia_lp, proficiencia_mt, dplyr::all_of(vars_nivel2)) |>
  tidyr::pivot_longer(dplyr::all_of(vars_nivel2), names_to = "preditor", values_to = "valor") |>
  tidyr::pivot_longer(c(proficiencia_lp, proficiencia_mt), names_to = "disciplina", values_to = "proficiencia") |>
  ggplot(aes(x = valor, y = proficiencia)) +
  geom_point(alpha = 0.15, size = 0.8) +
  geom_smooth(method = "loess", color = "#D55E00", se = TRUE) +
  facet_grid(disciplina ~ preditor, scales = "free_x") +
  labs(title = "Proficiência média por escola x preditores de nível 2", x = NULL, y = "Proficiência média") +
  theme_minimal()

ggsave("outputs/fig_03c_proficiencia_vs_nivel2.png", p_scatter, width = 14, height = 6, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03c_proficiencia_vs_nivel2.png")

# -----------------------------------------------------------------------------
# 5. COMPARAÇÃO RURAL X URBANA
# -----------------------------------------------------------------------------
cli::cli_h2("5. Comparação rural x urbana")

vars_comparacao <- c("proficiencia_lp", "proficiencia_mt", vars_nivel2)

for (v in vars_comparacao) {
  teste <- t.test(escolas_df[[v]] ~ escolas_df$rural_lbl)
  medias <- escolas_df |>
    dplyr::group_by(rural_lbl) |>
    dplyr::summarise(media = mean(.data[[v]], na.rm = TRUE), .groups = "drop")
  cli::cli_alert_info(glue::glue(
    "{v}: Urbana={round(medias$media[medias$rural_lbl == 'Urbana'], 3)} | ",
    "Rural={round(medias$media[medias$rural_lbl == 'Rural'], 3)} | ",
    "p={format.pval(teste$p.value, digits = 3)}"
  ))
}

p_rural <- escolas_df |>
  dplyr::select(rural_lbl, dplyr::all_of(vars_nivel2)) |>
  tidyr::pivot_longer(dplyr::all_of(vars_nivel2), names_to = "variavel", values_to = "valor") |>
  ggplot(aes(x = rural_lbl, y = valor, fill = rural_lbl)) +
  geom_boxplot() +
  facet_wrap(~variavel, scales = "free_y") +
  scale_fill_brewer(palette = "Set2") +
  labs(title = "Preditores de nível 2: rural x urbana", x = NULL, y = NULL) +
  theme_minimal() +
  theme(legend.position = "none")

ggsave("outputs/fig_03c_rural_vs_urbana.png", p_rural, width = 10, height = 6, dpi = 150)
cli::cli_alert_success("Figura salva: outputs/fig_03c_rural_vs_urbana.png")

cli::cli_h1("✅ AED — Nível Escola concluída")
