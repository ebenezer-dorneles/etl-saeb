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
  itens_aluno_negativos <- c(
    "TX_RESP_Q23a", "TX_RESP_Q23b", "TX_RESP_Q23c", "TX_RESP_Q23d",
    "TX_RESP_Q23e", "TX_RESP_Q23f", "TX_RESP_Q23g", "TX_RESP_Q23h", "TX_RESP_Q23i"
  )

  alunos_df <- alunos_raw |>
    dplyr::mutate(
      dplyr::across(dplyr::all_of(itens_aluno_negativos), letra_para_num),
      TX_RESP_Q22f_num = letra_para_num(TX_RESP_Q22f),
      TX_RESP_Q22f_inv = inverter(TX_RESP_Q22f_num, max = 4L)
    )

  itens_aluno_idx <- c(itens_aluno_negativos, "TX_RESP_Q22f_inv")
  alunos_df$idx_ambiente_aluno <- rowMeans(alunos_df[, itens_aluno_idx], na.rm = FALSE)

  alunos_clean <- alunos_df |>
    dplyr::transmute(
      ID_ALUNO,
      ID_ESCOLA,
      ID_UF = as.factor(ID_UF),
      proficiencia_lp = PROFICIENCIA_LP_SAEB,
      proficiencia_mt = PROFICIENCIA_MT_SAEB,
      inse            = nivel_para_num(NU_TIPO_NIVEL_INSE),
      sexo            = dplyr::if_else(TX_RESP_Q01 == "B", 1L, 0L, missing = NA_integer_),
      raca_branca     = dplyr::if_else(TX_RESP_Q02 == "A", 1L, 0L, missing = NA_integer_),
      reprovado       = dplyr::if_else(TX_RESP_Q05 %in% c("B", "C", "D"), 1L, 0L, missing = NA_integer_),
      abandonou       = dplyr::if_else(TX_RESP_Q06 %in% c("B", "C", "D"), 1L, 0L, missing = NA_integer_),
      trabalha        = dplyr::case_when(
        TX_RESP_Q07 %in% c("A") ~ 0L,
        TX_RESP_Q07 %in% c("B", "C", "D") ~ 1L,
        TRUE ~ NA_integer_
      ),
      escol_mae = dplyr::case_when(
        TX_RESP_Q04 == "A" ~ 1L,
        TX_RESP_Q04 == "B" ~ 2L,
        TX_RESP_Q04 == "C" ~ 3L,
        TX_RESP_Q04 == "D" ~ 4L,
        TX_RESP_Q04 == "E" ~ 5L,
        TRUE ~ NA_integer_
      ),
      eng_pais = rowMeans(cbind(
        letra_para_num(TX_RESP_Q14),
        letra_para_num(TX_RESP_Q15),
        letra_para_num(TX_RESP_Q16)
      ), na.rm = FALSE),
      idx_ambiente_aluno
    )

  return(alunos_clean)
}
