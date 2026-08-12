testthat::test_that("Test llm_api_server with too short OpenAI key", {
  shiny::testServer(llm_api_server,
                    args = list(no_internet = NULL, exclude_pattern = ""),
                    {
                      print("test llm_api_server: OpenAI provider with valid key file")

                      session$setInputs(
                        provider = "OpenAI",
                        api_key = "84798576dsklfg"
                      )
                      testthat::expect_length(api(), 0)
                      testthat::expect_equal(attr(api(), "error"), "API key appears too short.")
                    })
})

testthat::test_that("Test llm_api_server with OpenAI key", {
  shiny::testServer(llm_api_server,
                    args = list(no_internet = NULL, exclude_pattern = ""),
                    {
                      print("test llm_api_server: OpenAI provider with key")

                      session$setInputs(
                        provider = "OpenAI",
                        api_key = "84798576dsklfgj4g7jl6lsjh"
                      )

                      testthat::expect_s3_class(api(), "RemoteLlmApi")
                      testthat::expect_s3_class(api(), "LlmApi")
                      testthat::expect_null(attr(api(), "error"))
                    })
})
