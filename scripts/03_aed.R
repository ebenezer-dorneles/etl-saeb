# =============================================================================
# ANÁLISE EXPLORATÓRIA DE DADOS — SAEB 2023 | ENSINO MÉDIO | REGIÃO SUL
# =============================================================================

source("R/packages.R")

con <- DBI::dbConnect(
  duckdb::duckdb(),
  "data/db/saeb_sul_2023.duckdb",
  read_only = TRUE
)

# -----------------------------------------------------------------------------
# 1. CARREGAMENTO
# -----------------------------------------------------------------------------

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

DBI::dbDisconnect(con, shutdown = TRUE)

dplyr::glimpse(alunos_raw)

# -----------------------------------------------------------------------------
# 2. PERGUNTAS EXPLORATÓRIAS
# -----------------------------------------------------------------------------

cli::cli_h2("1. Distribuição de escolas Urbanas e Rurais por Estado")
alunos_raw %>% 
  group_by(ID_LOCALIZACAO, ID_UF) %>% 
  summarise(total = n(), .groups = "drop") %>% 
  group_by(ID_UF) %>% 
  mutate(percentual_uf = scales::percent(total / sum(total))) %>% 
  ungroup() %>% 
  mutate(percentual_estado = scales::percent(total / sum(total))) %>% 
  mutate(ID_LOCALIZACAO = case_when(
    ID_LOCALIZACAO == 1 ~ 'Urbana',
    ID_LOCALIZACAO == 2 ~ 'Rural',
    .default  = 'Outro'
  )) %>% 
  mutate(ID_UF = case_when(
    ID_UF == 41L ~ 'Parana',
    ID_UF == 42L ~ 'Santa Catarina',
    ID_UF == 43L ~ 'Rio Grande do Sul',
    .default = 'Outro'
  )) %>% 
  print()


cli::cli_h2("2. Quantidade de alunos por Tipo de Ensino e por Estado")
alunos_raw %>% 
  group_by(ID_SERIE, ID_UF) %>% 
  summarise(total = n(), .groups = "drop") %>% 
  group_by(ID_UF) %>% 
  mutate(percentual_uf = scales::percent(total / sum(total))) %>% 
  ungroup() %>% 
  mutate(percentual_estado = scales::percent(total / sum(total))) %>% 
  mutate(ID_UF = case_when(
    ID_UF == 41L ~ 'Parana',
    ID_UF == 42L ~ 'Santa Catarina',
    ID_UF == 43L ~ 'Rio Grande do Sul',
    .default = 'Outro'
  )) %>% 
  mutate(ID_SERIE = case_when(
    ID_SERIE == 12 ~ "3ª/4ª séries do Ensino Médio Tradicional",
    ID_SERIE == 13 ~ "3ª/4ª séries do Ensino Médio Integrado",
    .default = "Outro"
  )) %>% 
  print()


cli::cli_h2("3. Porcentagem de escolas públicas vs privadas por Estado")
alunos_raw %>% 
  group_by(IN_PUBLICA, ID_UF) %>% 
  summarise(total = n(), .groups = "drop") %>% 
  group_by(ID_UF) %>% 
  mutate(percentual_uf = scales::percent(total / sum(total))) %>% 
  ungroup() %>% 
  mutate(percentual_estado = scales::percent(total / sum(total))) %>% 
  mutate(IN_PUBLICA = case_when(
    IN_PUBLICA == 1 ~ 'Publica',
    IN_PUBLICA == 0 ~ 'Privada',
    .default  = 'Outro'
  )) %>% 
  mutate(ID_UF = case_when(
    ID_UF == 41L ~ 'Parana',
    ID_UF == 42L ~ 'Santa Catarina',
    ID_UF == 43L ~ 'Rio Grande do Sul',
    .default = 'Outro'
  )) %>% 
  print()


cli::cli_h2("4. Nível Socioeconômico dos estudantes (INSE)")
p_inse <- alunos_raw %>% 
  group_by(NU_TIPO_NIVEL_INSE) %>% 
  summarise(total = n(), .groups = "drop") %>% 
  mutate(
    percentual = total / sum(total),
    NU_TIPO_NIVEL_INSE_STR = factor(
      NU_TIPO_NIVEL_INSE,
      levels = 1:7,
      labels = c('Muito Baixo', 'Baixo', 'Médio Baixo', 'Médio', 'Médio Alto', 'Alto', 'Muito Alto')
    )
  ) %>% 
  drop_na(NU_TIPO_NIVEL_INSE_STR) %>% 
  ggplot(aes(x = NU_TIPO_NIVEL_INSE_STR, y = percentual, fill = NU_TIPO_NIVEL_INSE_STR)) + 
    geom_col() + 
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) + 
    labs(
      subtitle = "Nível Socioeconômico dos Estudantes (SAEB 2023 - Região Sul)",
      x = "Nível Socioeconômico",
      y = "Percentual"
    ) + 
    scale_fill_brewer(palette = "Set3") + 
    theme_minimal() + 
    theme(
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "none"
    )

print(p_inse)
