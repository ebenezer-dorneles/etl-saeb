#' Cálculo de Índices Fatoriais (AFE) e Agregação por Escola

compute_teacher_indices <- function(professores_proc) {
  professores_df  <- professores_proc$df
  itens_violencia <- professores_proc$itens_violencia
  itens_clima     <- professores_proc$itens_clima
  todos_itens     <- c(itens_violencia, itens_clima)

  mat_prof <- profesores_df[, todos_itens] |> na.omit()
  efa_prof <- psych::fa(mat_prof, nfactors = 2, rotate = "promax", fm = "ml")

  # Identificação dos fatores
  loadings_mat <- unclass(efa_prof$loadings)
  f_viol <- if (mean(abs(loadings_mat[itens_violencia, 1])) > mean(abs(loadings_mat[itens_violencia, 2]))) "ML1" else "ML2"
  f_clim <- if (f_viol == "ML1") "ML2" else "ML1"

  scores_all <- psych::factor.scores(
    professores_df[, todos_itens],
    efa_prof,
    method = "tenBerge",
    missing = TRUE
  )$scores

  professores_df$idx_violencia_prof <- scores_all[, f_viol]
  professores_df$idx_clima_prof     <- scores_all[, f_clim]

  prof_escola <- professores_df |>
    dplyr::group_by(ID_ESCOLA) |>
    dplyr::summarise(
      idx_violencia_escola = mean(idx_violencia_prof, na.rm = TRUE),
      idx_clima_escola     = mean(idx_clima_prof,     na.rm = TRUE),
      n_professores        = dplyr::n(),
      .groups = "drop"
    )

  return(list(
    professores_df = professores_df,
    prof_escola    = prof_escola,
    efa_model      = efa_prof
  ))
}

process_escolas <- function(escolas_raw) {
  escolas_clean <- escolas_raw |>
    dplyr::transmute(
      ID_ESCOLA,
      inse_escola  = nivel_para_num(NU_TIPO_NIVEL_INSE),
      publica      = dplyr::if_else(ID_DEPENDENCIA_ADM %in% c(1, 2, 3), 1L, 0L, missing = NA_integer_),
      rural        = dplyr::if_else(ID_LOCALIZACAO == 2, 1L, 0L, missing = NA_integer_),
      form_doc     = suppressWarnings(as.numeric(PC_FORMACAO_DOCENTE)),
      ln_n_alunos  = log(suppressWarnings(as.numeric(QT_MAT_BAS)) + 1)
    )

  return(escolas_clean)
}
