# Project Brief: Ambiente Escolar e Desempenho Acadêmico no Ensino Médio

## Core Overview
Specialization Monograph Project analyzing the relationship between school environment perception (students & teachers) and academic performance (Portuguese & Mathematics) in SAEB 2023 for Southern Brazil (PR, SC, RS) using Multilevel Linear Modeling (HLM/LMM).

## Key Objectives
- Investigate student & teacher perception of school climate / violence and its impact on standardized test scores (`PROFICIENCIA_LP_SAEB`, `PROFICIENCIA_MT_SAEB`).
- Control for student Socioeconomic Index (`INSE`), demographics, and school-level characteristics.
- Test allostatic load hypotheses (Evans & Schamberg, 2009).

## Primary Data Sources
- **SAEB 2023 Microdata (INEP/MEC)**:
  - `alunos`: TS_ALUNO_34EM.csv (~195k records in South region)
  - `professores`: TS_PROFESSOR.csv (~45k records in South region)
  - `escolas`: TS_ESCOLA.csv (~10k records in South region)
- Stored/Persisted locally in DuckDB database: `data/db/saeb_sul_2023.duckdb`.
