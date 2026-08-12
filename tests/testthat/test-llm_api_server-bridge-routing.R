testthat::test_that("llm_api_server routes bridge providers through new_BridgedLlmApi", {
  shiny::testServer(
    llm_api_server,
    args = list(no_internet = NULL, exclude_pattern = ""),
    {
      session$setInputs(
        provider = "Anthropic",
        api_key = "short-key"
      )

      testthat::expect_length(api(), 0)
      testthat::expect_equal(attr(api(), "error"), "API key appears too short.")
    }
  )
})

testthat::test_that("llm_api_server bridge path returns EllmerLlmApi on valid key", {
  shiny::testServer(
    llm_api_server,
    args = list(no_internet = NULL, exclude_pattern = ""),
    {
      session$setInputs(
        provider = "Anthropic",
        api_key = "sk-ant-validkey123456789012345"
      )

      testthat::expect_s3_class(api(), "EllmerLlmApi")
      testthat::expect_s3_class(api(), "LlmApi")
      testthat::expect_equal(api()$provider, "Anthropic")
    }
  )
})
