source(here::here("R/utils/clean_microdata_saeb_2023.R"))

test_that("clean functions correctly read and filter microdata", {
  tmp_dir <- tempfile("saeb_mock_")
  dir_dados <- file.path(tmp_dir, "MICRODADOS_SAEB_2023", "DADOS")
  dir.create(dir_dados, recursive = TRUE)
  on.exit(unlink(tmp_dir, recursive = TRUE))
  
  # 1. Create Mock TS_PROFESSOR.csv
  prof_file <- file.path(dir_dados, "TS_PROFESSOR.csv")
  prof_data <- paste0(
    "ID_UF;TX_Q135;TX_Q120\n",
    "41;A;B\n",
    "42;B;A\n",
    "43;C;A\n",
    "41;88888888;C"
  )
  writeLines(prof_data, prof_file)
  
  # 2. Create Mock TS_ESCOLA.csv
  escola_file <- file.path(dir_dados, "TS_ESCOLA.csv")
  escola_data <- paste0(
    "ID_UF;ID_ESCOLA;TX_TIPO\n",
    "41;111;Publica\n",
    "43;222;Privada\n",
    "42;333;99999999"
  )
  writeLines(escola_data, escola_file)
  
  # 3. Create Mock TS_ALUNO_34EM.csv
  aluno_file <- file.path(dir_dados, "TS_ALUNO_34EM.csv")
  aluno_data <- paste0(
    "ID_UF;ID_ALUNO;PROFICIENCIA\n",
    "41;1001;250\n",
    "42;1002;270\n",
    "43;1003;260\n",
    "41;1004;NA"
  )
  writeLines(aluno_data, aluno_file)
  
  # Run clean_professores and test results (filtering for PR and SC: 41, 42)
  res_prof <- clean_professores(tmp_dir, c("41", "42"), "2023")
  expect_s3_class(res_prof, "data.table")
  expect_equal(nrow(res_prof), 3) # 41, 42, and 41 (the 43 should be filtered out)
  expect_equal(res_prof$ID_UF, c("41", "42", "41"))
  expect_true(is.na(res_prof$TX_Q135[3])) # 88888888 is converted to NA
  
  # Run clean_escolas and test results
  res_escola <- clean_escolas(tmp_dir, c("41", "42"), "2023")
  expect_s3_class(res_escola, "data.table")
  expect_equal(nrow(res_escola), 2) # 41 and 42 (43 filtered out)
  expect_equal(res_escola$ID_ESCOLA, c("111", "333"))
  expect_true(is.na(res_escola$TX_TIPO[2])) # 99999999 is converted to NA
  
  # Run clean_alunos and test results
  res_alunos <- clean_alunos(tmp_dir, c("41", "42"), "2023")
  expect_s3_class(res_alunos, "data.table")
  expect_equal(nrow(res_alunos), 3) # 41, 42, 41 (43 filtered out)
  expect_equal(res_alunos$ID_ALUNO, c("1001", "1002", "1004"))
  expect_true(is.na(res_alunos$PROFICIENCIA[3])) # "NA" is converted to NA
})
