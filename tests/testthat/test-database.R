source(here::here("R/utils/database.R"))

test_that("save_table creates table, handles overwrite and creates index", {
  # Setup an in-memory DuckDB connection
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE))
  
  df1 <- dplyr::tibble(
    id = c(1L, 2L, 3L),
    nome = c("Alice", "Bob", "Charlie")
  )
  
  # Test basic saving
  expect_message(
    save_table(con, df1, "test_table"),
    "test_table: 3 rows saved"
  )
  
  expect_true(DBI::dbExistsTable(con, "test_table"))
  
  # Check data in table
  res <- DBI::dbReadTable(con, "test_table")
  expect_equal(nrow(res), 3)
  expect_equal(res$nome, c("Alice", "Bob", "Charlie"))
  
  # Test idempotency / overwrite
  df2 <- dplyr::tibble(
    id = c(1L, 2L, 3L, 4L),
    nome = c("Alice", "Bob", "Charlie", "David")
  )
  
  expect_message(
    save_table(con, df2, "test_table"),
    "test_table: 4 rows saved"
  )
  
  res_overwritten <- DBI::dbReadTable(con, "test_table")
  expect_equal(nrow(res_overwritten), 4)
  expect_equal(res_overwritten$nome[4], "David")
  
  # Test index creation
  save_table(con, df2, "test_table_indexed", chave = "id")
  expect_true(DBI::dbExistsTable(con, "test_table_indexed"))
  
  # Query DuckDB metadata to ensure the index exists
  indexes <- DBI::dbGetQuery(con, "SELECT index_name FROM duckdb_indexes")
  expect_true("idx_test_table_indexed_id" %in% indexes$index_name)
})
