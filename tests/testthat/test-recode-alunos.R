source(here::here("R/feature_engineering/recode_alunos.R"))

test_that("letra_para_num recodes A-D correctly and defaults to NA", {
  expect_equal(letra_para_num("A"), 1L)
  expect_equal(letra_para_num("B"), 2L)
  expect_equal(letra_para_num("C"), 3L)
  expect_equal(letra_para_num("D"), 4L)
  expect_equal(letra_para_num("E"), NA_integer_)
  expect_equal(letra_para_num(NA), NA_integer_)
  expect_equal(letra_para_num(c("A", "C", "X")), c(1L, 3L, NA_integer_))
})

test_that("inverter reverses score range correctly", {
  expect_equal(inverter(1, max = 4), 4)
  expect_equal(inverter(4, max = 4), 1)
  expect_equal(inverter(2, max = 5), 4)
  expect_true(is.na(inverter(NA, max = 4)))
})

test_that("nivel_para_num recodes roman numeral strings correctly", {
  expect_equal(nivel_para_num("Nível I"), 1L)
  expect_equal(nivel_para_num("Nivel I"), 1L)
  expect_equal(nivel_para_num("Nível VIII"), 8L)
  expect_equal(nivel_para_num("Nível IX"), NA_integer_)
})

test_that("process_alunos processes student data correctly", {
  # Create a tiny mock dataframe of raw student data
  mock_raw <- dplyr::tibble(
    ID_ALUNO = 12345L,
    ID_ESCOLA = 98765L,
    ID_UF = 41L,
    PROFICIENCIA_LP_SAEB = "250.5",
    PROFICIENCIA_MT_SAEB = "280.2",
    NU_TIPO_NIVEL_INSE = "3",
    TX_RESP_Q01 = "B",  # Sexo (B -> 1, others -> 0)
    TX_RESP_Q04 = "A",  # Raca Branca (A -> 1, others -> 0)
    TX_RESP_Q19 = "B",  # Reprovado
    TX_RESP_Q20 = "A",  # Abandonou (not B -> 0)
    TX_RESP_Q21d = "C", # Trabalha
    TX_RESP_Q08 = "D",  # Escol mae
    TX_RESP_Q10b = "A", # Eng pais 1
    TX_RESP_Q10c = "B", # Eng pais 2
    TX_RESP_Q10e = "C", # Eng pais 3
    TX_RESP_Q10f = "A", # Eng pais 4
    TX_RESP_Q23d = "A", # Ambiente 1
    TX_RESP_Q23c = "B", # Ambiente 2
    TX_RESP_Q23h = "C", # Ambiente 3
    TX_RESP_Q23i = "D", # Ambiente 4
    TX_RESP_Q22f = "A", # Ambiente 5
    TX_RESP_Q23b = "B", # Ambiente 6
    TX_RESP_Q23a = "C", # Ambiente 7
    TX_RESP_Q23e = "D"  # Ambiente 8
  )
  
  result <- process_alunos(mock_raw)
  
  expect_equal(result$ID_ALUNO, 12345L)
  expect_equal(result$ID_ESCOLA, "98765")
  expect_equal(result$ID_UF, factor("PR", levels = c("PR", "SC", "RS")))
  expect_equal(result$proficiencia_lp, 250.5)
  expect_equal(result$proficiencia_mt, 280.2)
  expect_equal(result$inse, 3.0)
  expect_equal(result$sexo, 1L)
  expect_equal(result$raca_branca, 1L)
  expect_equal(result$reprovado, 1L)
  expect_equal(result$abandonou, 0L)
  expect_equal(result$trabalha, 3L)
  expect_equal(result$escol_mae, 4L)
  
  # Check rowMeans for eng_pais: mean of (1, 2, 3, 1) = 7/4 = 1.75
  expect_equal(result$eng_pais, 1.75)
  
  # Check rowMeans for idx_ambiente_aluno: mean of (1, 2, 3, 4, 1, 2, 3, 4) = 20/8 = 2.5
  expect_equal(result$idx_ambiente_aluno, 2.5)
})
