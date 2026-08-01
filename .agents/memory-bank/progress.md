# Progress & History Tracker

## Milestones & Status
- [x] Initial project setup & README documentation updated.
- [x] DuckDB pipeline setup for SAEB 2023 South region (`scripts/01_pipeline_raw.R`).
- [x] Feature Engineering pipeline & DuckDB persistence (`scripts/02_build_features.R`).
- [x] Exploratory Data Analysis modularized (`scripts/03_aed.R`).
- [x] Multilevel modeling script structure M0–M5 (`scripts/04_modeling_hlm.R`).
- [x] Memory Bank & README updated for the 4-phase refactoring.
- [x] Unit tests suite fully implemented and verified under Docker for both features and utilities.
- [x] TDD refactoring completed (RED/GREEN) to align variable mappings (violence and climate) with INEP dictionary.

- [x] Run full model validation and output artifact generation (Results and paths analyzed in `outputs/02_resultados_e_caminhos.md`).
- [x] **Investigação do Paradoxo da Violência Docente (2026-08-01):** causa raiz encontrada — erro de classificação de itens (não confundimento residual). Corrigido em `c2d09f4`; pipeline recalculado; `idx_violencia_escola` agora negativo (sig. em MT), `idx_clima_escola` positivo forte. Ver `outputs/03_paradoxo_violencia_docente.md`.
- [x] **Avaliação do Viés de Seleção (2026-08-01):** testado diretamente — escolas sem professor respondente (12,7% do total) têm INSE levemente menor (p=0,0013) e porte levemente maior (p=0,0027), mas proporção rural idêntica (p=0,96). Efeito pequeno, não explica o paradoxo; documentado como limitação menor em `outputs/02_resultados_e_caminhos.md` (Seção 8.1) e `outputs/03_paradoxo_violencia_docente.md`.
- [x] **Teste de outliers em escolas com poucos professores respondentes (2026-08-01):** hipótese descartada — SD do índice é menor (não maior) em escolas com 1–2 respondentes, e excluir essas escolas do M3 não altera o coeficiente de violência. Ver `outputs/03_paradoxo_violencia_docente.md`.
- [ ] Update `questions.md` with final calculated metrics if requested.

## Future Research Paths & Extensões (Progress to be achieved)
### Curto Prazo (Para a Monografia)
- [ ] **Moderação por INSE (Interação Entre-Níveis):** Testar se a percepção de ambiente é mais relevante em escolas mais vulneráveis (`z_idx_amb_aluno * z_inse_escola`).
- [ ] **Centramento na Média do Grupo (CWC):** Centrar as variáveis de nível 1 na média do grupo para separar precisamente os efeitos *within* e *between* escolas.
- [ ] **Análise por Turno/Série:** Avaliar a moderação por turno (matutino vs. noturno).
- [ ] **Tratamento do Rank Deficiency:** O aviso em `publica` ocorre porque, na amostra final (listwise deletion), praticamente todas as escolas são da rede pública (`publica` é quase constante) — a coluna é descartada automaticamente pelo `lme4`. Resolver via análise estratificada ou substituição por `rede` com mais categorias (federal/estadual/municipal/privada), se houver variância suficiente antes do listwise deletion.


### Médio Prazo (Artigos Pós-Monografia)
- [ ] **Expansão Nacional/Comparação Regional:** Comparar Região Sul com Norte e Nordeste.
- [ ] **Modelos de Equações Estruturais Multinível (ML-SEM):** Analisar mediação (ex. ambiente -> engajamento -> desempenho) usando `lavaan`.
- [ ] **Triangulação com Dados Objetivos:** Cruzar dados do SAEB com Atlas da Violência e dados de infraestrutura física do Censo Escolar.
- [ ] **Séries Históricas:** Replicar a análise para as edições de 2019 e 2021 (painel de escola).
- [ ] **Análise de Invariância de Medida:** Testar invariância de medida do índice de ambiente entre os estados (PR, SC, RS).

