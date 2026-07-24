#' Recodificação do Questionário de Professores

process_professores <- function(professores_raw) {
  itens_violencia <- c(
    "TX_Q135", "TX_Q136", "TX_Q137", "TX_Q138",
    "TX_Q139", "TX_Q140", "TX_Q141", "TX_Q142",
    "TX_Q143", "TX_Q144", "TX_Q145", "TX_Q146"
  )

  itens_clima <- c(
    "TX_Q120", "TX_Q121", "TX_Q122",
    "TX_Q123", "TX_Q124", "TX_Q125", "TX_Q126"
  )

  professores_df <- professores_raw |>
    dplyr::mutate(
      dplyr::across(dplyr::all_of(c(itens_violencia, itens_clima)), letra_para_num)
    )

  return(list(
    df = professores_df,
    itens_violencia = itens_violencia,
    itens_clima = itens_clima
  ))
}
