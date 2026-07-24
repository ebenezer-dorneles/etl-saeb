#' Recodificações e Auxiliares para Nível do Aluno

letra_para_num <- function(x) {
  dplyr::recode(as.character(x),
    "A" = 1L, "B" = 2L, "C" = 3L, "D" = 4L,
    .default = NA_integer_
  )
}

inverter <- function(x, max = 4L) (max + 1L) - x

nivel_para_num <- function(x) {
  dplyr::recode(trimws(as.character(x)),
    "Nível I"    = 1L, "Nivel I"    = 1L,
    "Nível II"   = 2L, "Nivel II"   = 2L,
    "Nível III"  = 3L, "Nivel III"  = 3L,
    "Nível IV"   = 4L, "Nivel IV"   = 4L,
    "Nível V"    = 5L, "Nivel V"    = 5L,
    "Nível VI"   = 6L, "Nivel VI"   = 6L,
    "Nível VII"  = 7L, "Nivel VII"  = 7L,
    "Nível VIII" = 8L, "Nivel VIII" = 8L,
    .default = NA_integer_
  )
}

#' Recodificação completa da tabela de alunos
process_alunos <- function(alunos_raw) {
  alunos_clean <- alunos_raw |>
    dplyr::transmute(
      ID_ALUNO,
      ID_ESCOLA = as.character(ID_ESCOLA),
      ID_UF     = factor(ID_UF, levels = c(41, 42, 43), labels = c("PR", "SC", "RS")),
      proficiencia_lp = as.numeric(PROFICIENCIA_LP_SAEB),
      proficiencia_mt = as.numeric(PROFICIENCIA_MT_SAEB),
      inse            = as.numeric(NU_TIPO_NIVEL_INSE),
      sexo            = dplyr::if_else(TX_RESP_Q01 == "B", 1L, 0L, missing = NA_integer_),
      raca_branca     = dplyr::if_else(TX_RESP_Q04 == "A", 1L, 0L, missing = NA_integer_),
      reprovado       = dplyr::if_else(TX_RESP_Q19 == "B", 1L, 0L, missing = NA_integer_),
      abandonou       = dplyr::if_else(TX_RESP_Q20 == "B", 1L, 0L, missing = NA_integer_),
      trabalha        = letra_para_num(TX_RESP_Q21d),
      escol_mae       = letra_para_num(TX_RESP_Q08),
      eng_pais        = rowMeans(
        cbind(
          letra_para_num(TX_RESP_Q10b),
          letra_para_num(TX_RESP_Q10c),
          letra_para_num(TX_RESP_Q10e),
          letra_para_num(TX_RESP_Q10f)
        ),
        na.rm = TRUE
      ),
      idx_ambiente_aluno = rowMeans(
        cbind(
          letra_para_num(TX_RESP_Q23d),
          letra_para_num(TX_RESP_Q23c),
          letra_para_num(TX_RESP_Q23h),
          letra_para_num(TX_RESP_Q23i),
          letra_para_num(TX_RESP_Q22f),
          letra_para_num(TX_RESP_Q23b),
          letra_para_num(TX_RESP_Q23a),
          letra_para_num(TX_RESP_Q23e)
        ),
        na.rm = TRUE
      )
    )

  return(alunos_clean)
}
