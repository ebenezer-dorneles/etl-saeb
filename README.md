# Ambiente Escolar e Desempenho Acadêmico no Ensino Médio
### Uma análise multinível dos dados do SAEB 2023 — Região Sul do Brasil

> Monografia de Especialização em Estatística e Modelagem Quantitativa  
> Dados: SAEB 2023 (INEP/MEC) · Região Sul (PR, SC, RS) · Ensino Médio

---

## Resumo

Este projeto investiga se a **percepção de ambiente escolar insalubre** — captada separadamente por alunos e professores — está associada ao **desempenho em Língua Portuguesa e Matemática** no SAEB 2023, após controlar pelo nível socioeconômico individual e características das escolas.

A motivação teórica parte da literatura sobre **carga alostática** (Evans & Schamberg, 2009): ambientes escolares marcados por violência, insegurança e clima relacional deteriorado podem direcionar energia cognitiva para estratégias de sobrevivência e manejo do estresse, em detrimento do aprendizado. Isso significa que fatores estruturais e institucionais — não apenas a formação docente — são determinantes relevantes do desempenho escolar.

---

## Estrutura do Repositório

Pipeline em 4 estágios sequenciais, cada um lendo/escrevendo no mesmo banco DuckDB (não passam objetos R entre si):

```
.
├── R/
│   ├── packages.R                          # Lista central de dependências (instala e carrega)
│   ├── feature_engineering/
│   │   ├── recode_alunos.R                 # Recodificação e escalas do questionário do aluno
│   │   ├── recode_professores.R            # Recodificação do questionário do professor
│   │   └── compute_indices.R               # AFE (violência/clima) e agregação por escola
│   └── utils/
│       ├── download_microdata.R            # Download HTTP com retry (httr2)
│       ├── unzip_microdata.R               # Extração dos microdados
│       ├── clean_microdata_saeb_2023.R     # Limpeza dos CSVs brutos do SAEB 2023
│       └── database.R                      # save_table() — escrita idempotente no DuckDB
├── scripts/
│   ├── 01_pipeline_raw.R                   # Download + ingestão bruta → tabelas alunos/professores/escolas
│   ├── 02_build_features.R                 # Recodificação + AFE → tabela base_hlm
│   ├── 03_aed.R                             # Análise exploratória de dados
│   └── 04_modeling_hlm.R                    # Modelos HLM M0–M4 (LP e MT) + figuras
├── data/
│   ├── raw/                                # Microdados brutos baixados do INEP (SAEB, Censo Escolar, IBGE, IDEB)
│   └── db/
│       └── saeb_sul_2023.duckdb            # Banco DuckDB (tabelas brutas + base_hlm), gerado pelo pipeline
├── tests/testthat/                         # Testes unitários (um arquivo por módulo de R/)
├── outputs/                                # Figuras e relatórios gerados (não versionado — ver .gitignore)
├── .manifests/r-base/Dockerfile            # Imagem R reprodutível (rocker/r2u + pacotes do projeto)
├── docker-compose.yml                      # Serviço `r-base` montando o repositório em /workspace
└── README.md
```

---

## Dados

Os microdados são públicos e disponibilizados pelo [INEP](https://www.gov.br/inep/pt-br/areas-de-atuacao/avaliacao-e-exames-educacionais/saeb/resultados).

| Tabela | Fonte | N (Região Sul) |
|---|---|---|
| `alunos` | TS_ALUNO_34EM.csv | ~195 mil |
| `professores` | TS_PROFESSOR.csv | ~45 mil |
| `escolas` | TS_ESCOLA.csv | ~10 mil |

O banco DuckDB é gerado por `scripts/01_pipeline_raw.R`, que baixa os arquivos brutos, filtra a Região Sul (`ID_REGIAO == 4`, `ID_UF ∈ {41, 42, 43}`) e persiste as três tabelas localmente.

---

## Metodologia

### Construção dos índices de percepção de ambiente

Três índices foram construídos via **Análise Fatorial Exploratória (AFE)** com estimação ML:

| Índice | Fonte | Itens | α de Cronbach |
|---|---|---|---|
| Percepção de ambiente (aluno) | Questionário do aluno | Q23a–i, Q22f (8 itens) | 0,77 |
| Violência escolar | Questionário do professor (TX_Q135–Q147) | 13 itens | 0,85 |
| Clima relacional | Questionário do professor (TX_Q120, Q122, Q123, Q127–Q130) | 7 itens | 0,77 |

Os índices dos professores são **agregados por escola** (média) antes de entrar no modelo, representando a percepção coletiva do corpo docente sobre o ambiente.

### Modelo multinível (HLM)

Os alunos estão aninhados em escolas, tornando o **Hierarchical Linear Model** a abordagem adequada (Raudenbush & Bryk, 2002). A sequência de modelos estimada:

```
M0  Modelo nulo                     → ICC (justifica o HLM)
M1  + Controles individuais (N1)    → linha de base
M2  + Índice de ambiente do aluno   → efeito bruto da variável de interesse
M3  + Variáveis de escola (N2/N3)   → efeito líquido após controles institucionais
M4  + Slope aleatório               → o efeito varia entre escolas?
M5  Sub-índices separados (F1 e F2) → análise de sensibilidade
```

**Variável dependente:** Proficiência em LP e MT na escala SAEB (`PROFICIENCIA_LP_SAEB`, `PROFICIENCIA_MT_SAEB`)

**Hipóteses centrais:**

- **H1** — A percepção de ambiente insalubre pelo aluno está negativamente associada à proficiência, após controlar pelo INSE e características da escola.
- **H2** — O índice de violência escolar agregado dos professores tem efeito negativo adicional sobre o desempenho, além do efeito individual do aluno. *(Confirmado para Matemática; direção negativa mas não significativa para Língua Portuguesa — ver `outputs/03_paradoxo_violencia_docente.md`.)*
- **H3** — O efeito do ambiente percebido pelo aluno varia entre escolas (slope aleatório significativo), sugerindo moderação por fatores institucionais.

### Variáveis de controle

**Nível 1 — Aluno**

| Variável | Descrição |
|---|---|
| `inse` | Índice de Nível Socioeconômico (1–8) |
| `sexo` | Feminino = 1 |
| `raca_branca` | Autodeclaração |
| `reprovado` | Já foi reprovado |
| `abandonou` | Já abandonou a escola |
| `trabalha` | Horas de trabalho fora de casa |
| `escol_mae` | Escolaridade da mãe |
| `eng_pais` | Engajamento dos pais com a escola |

**Nível 2/3 — Escola**

| Variável | Descrição |
|---|---|
| `inse_escola` | INSE médio da escola (I–VIII → 1–8) |
| `publica` | Dependência administrativa |
| `rural` | Localização urbana/rural |
| `form_doc` | % docentes com formação adequada |
| `ln_n_alunos` | Porte da escola (log de matriculados) |
| `idx_violencia_escola` | Índice de violência (prof. agregado) |
| `idx_clima_escola` | Índice de clima relacional (prof. agregado) |

---

## Resultados Preliminares

| Indicador | LP | MT |
|---|---|---|
| ICC (modelo nulo) | 0,088 | 0,118 |
| Variância entre escolas | 8,8% | 11,8% |
| α do índice (aluno) | 0,77 | — |
| α do índice (violência prof.) | 0,85 | — |
| α do índice (clima prof.) | 0,77 | — |

O ICC entre 9% e 12% justifica o uso de HLM — quase 1/8 da variância de proficiência em Matemática está associada a diferenças entre escolas, não entre alunos.

### Efeito dos índices de ambiente docente (Modelo M3, coeficientes por 1 desvio-padrão)

| Coeficiente | LP | MT |
|---|---|---|
| `idx_violencia_escola` | −0,35 (n.s.) | **−0,81** (p = 0,023) |
| `idx_clima_escola` | **+1,74** (p < 0,001) | **+2,25** (p < 0,001) |
| `idx_ambiente_aluno` | **+2,26** (p < 0,001) | **+0,45** (p < 0,001) |

Uma versão anterior deste índice de violência apresentava coeficientes positivos e contra-intuitivos, causados por um erro de classificação de itens (itens de gestão institucional indevidamente atribuídos ao fator "clima", e ausência do item de maior gravidade — `TX_Q147`, tiroteio/bala perdida — no fator "violência"). O erro foi corrigido em `R/feature_engineering/recode_professores.R`; a investigação completa, incluindo hipóteses descartadas de viés de seleção e de outliers amostrais, está documentada em `outputs/03_paradoxo_violencia_docente.md`.

---

## Reprodutibilidade

### Pré-requisitos

- R ≥ 4.3
- Docker (recomendado — garante o conjunto de pacotes e o certificado SSL necessários para baixar os microdados do INEP)

### Pacotes R necessários

Centralizados em `R/packages.R` (instala automaticamente o que faltar) e espelhados em `DESCRIPTION` (Imports) e `.manifests/r-base/Dockerfile` (pacotes `r-cran-*`). Principais: `DBI`, `duckdb`, `dbplyr`, `dplyr`, `tidyr`, `ggplot2`, `psych`, `lme4`, `lmerTest`, `performance`, `broom.mixed`, `httr2`, `fs`, `here`, `glue`, `dotenv`, `cli`, `data.table`.

### Execução

Os scripts devem ser executados a partir da raiz do repositório (usam caminhos relativos como `data/db/...`), na ordem abaixo:

```bash
# 1. Download e ingestão dos microdados brutos do INEP → tabelas alunos/professores/escolas no DuckDB
Rscript scripts/01_pipeline_raw.R

# 2. Feature engineering: recodificação, AFE (violência/clima) e agregação por escola → tabela base_hlm
Rscript scripts/02_build_features.R

# 3. Análise exploratória de dados
Rscript scripts/03_aed.R

# 4. Modelagem multinível (HLM M0–M4) para LP e MT + figuras em outputs/
Rscript scripts/04_modeling_hlm.R
```

**Com Docker** (recomendado): suba o serviço com `docker-compose up -d` e rode cada script com:

```bash
docker compose exec r-base Rscript scripts/01_pipeline_raw.R
docker compose exec r-base Rscript scripts/02_build_features.R
docker compose exec r-base Rscript scripts/03_aed.R
docker compose exec r-base Rscript scripts/04_modeling_hlm.R
```

### Testes

```r
testthat::test_dir("tests/testthat")
```

---

## Referências Principais

### Metodologia estatística
- Raudenbush, S. W., & Bryk, A. S. (2002). *Hierarchical Linear Models* (2ª ed.). Sage.
- Barbosa, M. E., & Fernandes, C. (2000). Modelo multinível: uma aplicação a dados de avaliação educacional. *Estudos em Avaliação Educacional*, 22. https://doi.org/10.18222/eae02220002220
- Ferrão, M. E. (2003). *Introdução aos modelos de regressão multinível em educação.* Komedi.

### Clima escolar e desempenho
- Maxwell, B., et al. (2017). The impact of school climate and school identification on academic achievement: multilevel modeling with student and teacher data. *Frontiers in Psychology*, 8, 2069. https://doi.org/10.3389/fpsyg.2017.02069
- Ma, X., & Klinger, D. A. (2000). Hierarchical linear modelling of student and school effects on academic achievement. *Canadian Journal of Education*, 25(1), 41–55.
- Demirtas-Zorbaz, S., Akin-Arikan, C., & Terzi, R. (2021). Does school climate that includes students' views deliver academic achievement? *School Effectiveness and School Improvement*, 32(4), 543–563.

### Violência escolar e SAEB no Brasil
- Faria, A. C. L. (2020). *Violência nas escolas e desempenho dos estudantes do 3º ano do ensino médio no Brasil.* Dissertação (Mestrado) — UFV.
- Oliveira, R. V., & Ferreira, D. (2013). Violência e desempenho dos alunos nas escolas brasileiras: uma análise a partir do SAEB 2011. *Revista Econômica*, 15(1).
- Duarte, R. (2017). Influência da violência dentro e fora da escola na proficiência escolar dos alunos da cidade do Recife. *Revista Brasileira de Segurança Pública.*

### Base teórica: estresse e cognição
- Evans, G. W., & Schamberg, M. A. (2009). Childhood poverty, chronic stress, and adult working memory. *PNAS*, 106(16), 6545–6549. https://doi.org/10.1073/pnas.0811910106
- D'Amico, D., et al. (2020). The association between allostatic load and cognitive function: A systematic and meta-analytic review. *Psychoneuroendocrinology*, 122, 104855.

---

## Licença

Os microdados do SAEB são públicos e de livre uso, disponibilizados pelo INEP sob a [Lei de Acesso à Informação (Lei nº 12.527/2011)](http://www.planalto.gov.br/ccivil_03/_ato2011-2014/2011/lei/l12527.htm). O código deste repositório está disponível sob a licença [MIT](LICENSE).

---

*Especialização em Estatística e Modelagem Quantitativa · 2025*