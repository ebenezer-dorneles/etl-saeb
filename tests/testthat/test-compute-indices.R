source(here::here("R/feature_engineering/recode_alunos.R"))
source(here::here("R/feature_engineering/compute_indices.R"))

test_that("process_escolas processes school data correctly", {
  # Mock schools raw data
  mock_raw <- dplyr::tibble(
    ID_ESCOLA = c(101, 102, 103),
    NIVEL_SOCIO_ECONOMICO = c("Nível IV", "Nivel II", "Nível VI"),
    IN_PUBLICA = c("1", "0", "1"),
    ID_LOCALIZACAO = c(1, 2, 2), # 1 = urban, 2 = rural
    PC_FORMACAO_DOCENTE_MEDIO = c("85.5", "na", "92.0"),
    NU_MATRICULADOS_CENSO_EM = c("100", "0", "400")
  )
  
  result <- process_escolas(mock_raw)
  
  expect_equal(result$ID_ESCOLA, c("101", "102", "103"))
  expect_equal(result$inse_escola, c(4L, 2L, 6L))
  expect_equal(result$publica, c(1L, 0L, 1L))
  expect_equal(result$rural, c(0L, 1L, 1L))
  expect_equal(result$form_doc[1], 85.5)
  expect_true(is.na(result$form_doc[2]))
  expect_equal(result$ln_n_alunos[1], log(101))
  expect_equal(result$ln_n_alunos[2], log(1)) # log(0 + 1) = 0
})
