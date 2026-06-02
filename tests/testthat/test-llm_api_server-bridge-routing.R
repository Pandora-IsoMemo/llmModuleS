testthat::test_that("llm_api_server routes bridge providers through new_BridgedLlmApi", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("short-key", key_file)

  shiny::testServer(
    llm_api_server,
    args = list(no_internet = NULL, exclude_pattern = ""),
    {
      session$setInputs(
        provider = "Anthropic",
        api_key_file = structure(
          list(
            name = "test-key",
            size = 10L,
            type = "text/plain",
            datapath = key_file
          ),
          class = "data.frame",
          row.names = c(NA, -1L)
        )
      )

      testthat::expect_length(api(), 0)
      testthat::expect_equal(attr(api(), "error"), "API key appears too short.")
    }
  )
})

testthat::test_that("llm_api_server bridge path returns EllmerLlmApi on valid key", {
  key_file <- tempfile(fileext = ".txt")
  writeLines("sk-ant-validkey123456789012345", key_file)

  shiny::testServer(
    llm_api_server,
    args = list(no_internet = NULL, exclude_pattern = ""),
    {
      session$setInputs(
        provider = "Anthropic",
        api_key_file = structure(
          list(
            name = "test-key",
            size = 10L,
            type = "text/plain",
            datapath = key_file
          ),
          class = "data.frame",
          row.names = c(NA, -1L)
        )
      )

      testthat::expect_s3_class(api(), "EllmerLlmApi")
      testthat::expect_s3_class(api(), "LlmApi")
      testthat::expect_equal(api()$provider, "Anthropic")
    }
  )
})
