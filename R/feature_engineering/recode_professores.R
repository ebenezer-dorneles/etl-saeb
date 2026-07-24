#' Recodificação do Questionário de Professores

process_professores <- function(professores_raw) {
  itens_violencia <- c(
    "TX_RESP_Q135", "TX_RESP_Q136", "TX_RESP_Q137", "TX_RESP_Q138",
    "TX_RESP_Q139", "TX_RESP_Q140", "TX_RESP_Q141", "TX_RESP_Q142",
    "TX_RESP_Q143", "TX_RESP_Q144", "TX_RESP_Q145", "TX_RESP_Q146"
  )

  itens_clima <- c(
    "TX_RESP_Q120", "TX_RESP_Q121", "TX_RESP_Q122",
    "TX_RESP_Q123", "TX_RESP_Q124", "TX_RESP_Q125", "TX_RESP_Q126"
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
