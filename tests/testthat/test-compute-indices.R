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

test_that("compute_teacher_indices performs EFA and aggregates by school correctly", {
  # Generate 100 mock teachers across 3 schools with correlated values to ensure EFA convergence
  set.seed(42)
  n <- 100
  
  # Latent factors
  f1_latent <- c(rep(1, 33), rep(2.5, 33), rep(4, 34))
  f2_latent <- c(rep(4, 33), rep(1, 33), rep(2.5, 34))
  
  df_list <- list(
    ID_ESCOLA = rep(c("101", "102", "103"), length.out = n)
  )
  
  # Populate 13 violence items (correlated with f1_latent: Q135 to Q147)
  for (i in 1:13) {
    col_name <- paste0("TX_Q", 134 + i)
    val <- round(f1_latent + rnorm(n, 0, 0.1))
    val[val < 1] <- 1
    val[val > 4] <- 4
    df_list[[col_name]] <- val
  }
  
  # Populate 7 climate items (correlated with f2_latent: Q120, Q122, Q123, Q127 to Q130)
  clima_cols <- c("TX_Q120", "TX_Q122", "TX_Q123", "TX_Q127", "TX_Q128", "TX_Q129", "TX_Q130")
  for (col_name in clima_cols) {
    val <- round(f2_latent + rnorm(n, 0, 0.1))
    val[val < 1] <- 1
    val[val > 4] <- 4
    df_list[[col_name]] <- val
  }
  
  mock_df <- dplyr::as_tibble(df_list)
  
  prof_proc <- list(
    df = mock_df,
    itens_violencia = paste0("TX_Q", 135:147),
    itens_clima = clima_cols
  )
  
  result <- compute_teacher_indices(prof_proc)
  
  # Check output structure and classes
  expect_type(result, "list")
  expect_named(result, c("professores_df", "prof_escola", "efa_model"))
  expect_s3_class(result$efa_model, "fa")
  
  # Verify scores were computed and added
  expect_true("idx_violencia_prof" %in% names(result$professores_df))
  expect_true("idx_clima_prof" %in% names(result$professores_df))
  expect_equal(nrow(result$professores_df), n)
  
  # Verify school aggregation
  expect_equal(nrow(result$prof_escola), 3)
  expect_equal(result$prof_escola$ID_ESCOLA, c("101", "102", "103"))
  expect_equal(result$prof_escola$n_professores, c(34, 33, 33))
  expect_true(all(!is.na(result$prof_escola$idx_violencia_escola)))
  expect_true(all(!is.na(result$prof_escola$idx_clima_escola)))
})
