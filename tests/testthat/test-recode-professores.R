source(here::here("R/feature_engineering/recode_alunos.R"))
source(here::here("R/feature_engineering/recode_professores.R"))

test_that("process_professores recodes teacher questionnaire items correctly", {
  # Mock teacher raw data frame
  mock_raw <- dplyr::tibble(
    ID_ESCOLA = c("1", "2"),
    TX_Q135 = c("A", "B"),
    TX_Q136 = c("C", "D"),
    TX_Q137 = c("A", NA),
    TX_Q138 = c("B", "X"),
    TX_Q139 = c("A", "A"),
    TX_Q140 = c("A", "A"),
    TX_Q141 = c("A", "A"),
    TX_Q142 = c("A", "A"),
    TX_Q143 = c("A", "A"),
    TX_Q144 = c("A", "A"),
    TX_Q145 = c("A", "A"),
    TX_Q146 = c("A", "A"),
    TX_Q120 = c("A", "B"),
    TX_Q121 = c("C", "D"),
    TX_Q122 = c("A", NA),
    TX_Q123 = c("B", "X"),
    TX_Q124 = c("A", "A"),
    TX_Q125 = c("A", "A"),
    TX_Q126 = c("A", "A")
  )
  
  result <- process_professores(mock_raw)
  
  # Check output structure
  expect_type(result, "list")
  expect_named(result, c("df", "itens_violencia", "itens_clima"))
  
  # Check dataframe recoding
  df_proc <- result$df
  expect_equal(df_proc$TX_Q135, c(1L, 2L))
  expect_equal(df_proc$TX_Q136, c(3L, 4L))
  expect_equal(df_proc$TX_Q137, c(1L, NA_integer_))
  expect_equal(df_proc$TX_Q138, c(2L, NA_integer_))
  
  expect_equal(df_proc$TX_Q120, c(1L, 2L))
  expect_equal(df_proc$TX_Q121, c(3L, 4L))
  expect_equal(df_proc$TX_Q122, c(1L, NA_integer_))
  expect_equal(df_proc$TX_Q123, c(2L, NA_integer_))
  
  # Verify metadata vectors
  expect_equal(result$itens_violencia[1], "TX_Q135")
  expect_equal(result$itens_clima[1], "TX_Q120")
})
