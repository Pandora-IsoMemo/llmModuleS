# ---- UI Function ----
llm_prompt_config_ui <- function(id) {
  ns <- NS(id)

  tagList(
    fluidRow(
      column(3, selectInput(ns("model"), "Select a model", choices = c("Check provider ..." = ""))),
      column(3, sliderInput(ns("temperature"), "Temperature", min = 0, max = 2, value = 1, step = 0.1)),
      column(3, numericInput(ns("max_tokens"), "Max Tokens", value = 100, min = 1)),
      column(3, checkboxInput(ns("show_advanced"), "Show Advanced Settings", value = FALSE))
    ),
    conditionalPanel(
      ns = ns,
      condition = "input.show_advanced == true",
      uiOutput(ns("advancedInputs"))
    ),
    fluidRow(
      column(12, align = "right", status_message_ui(ns("settings_status")))
    )
  )
}

# ---- Server Function ----
llm_prompt_config_server <- function(id, llm_api, prompt_reactive = reactiveVal("")) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    llm_prompt_config <- reactiveVal()

    # possibly load default values from config later ...
    fields_advanced_all <- list(
      list(fun = selectInput, args = list(ns("prompt_role"), "Prompt Role", c("user", "system", "assistant"))),
      list(fun = sliderInput, args = list(ns("top_p"), "Top-p", min = 0, max = 1, value = 1, step = 0.01)),
      list(fun = numericInput, args = list(ns("seed"), "Seed (optional)", value = NA, min = 1, step = 1)),
      list(fun = textInput, args = list(ns("stop"), "Stop Sequence (optional)", placeholder = "e.g. ### or <end>"))
    )

    fields_advanced_provider <- list(
      Ollama = list(),
      DeepSeek = list(
        list(fun = numericInput, args = list(ns("n"), "No. of Completions (n)", value = 1, min = 1))
      ),
      OpenAI = list(
        list(fun = numericInput, args = list(ns("n"), "No. of Completions (n)", value = 1, min = 1)),
        list(fun = sliderInput, args = list(ns("presence_penalty"), "Presence Penalty", min = -2, max = 2, value = 0, step = 0.1)),
        list(fun = sliderInput, args = list(ns("frequency_penalty"), "Frequency Penalty", min = -2, max = 2, value = 0, step = 0.1)),
        list(fun = checkboxInput, args = list(ns("logprobs"), "Return Logprobs", value = FALSE))
      )
    )

    output$advancedInputs <- renderUI({
      req(llm_api(), llm_api()$provider)
      tagList(
        fluidRow(
          lapply(fields_advanced_all, function(f) column(3, do.call(f$fun, f$args)))
        ),
        fluidRow(
          lapply(fields_advanced_provider[[llm_api()$provider]], function(f) column(3, do.call(f$fun, f$args)))
        )
      )
    })

    observe({
      api <- llm_api()
      if (inherits(api, "LlmApi")) {
        models <- llmModule::get_llm_models(api) |>
          shinyTryCatch(errorTitle = "Getting models failed", alertStyle = "shinyalert")
      } else {
        models <- list()
      }

      choices <- if (length(models) == 0) {
        c("No models found..." = "")
      } else {
        models
      }
      updateSelectInput(session, "model", choices = choices)
    }) |> bindEvent(llm_api())

    observe({
      req(prompt_reactive())
      new_settings <- llmModule::new_LlmPromptConfig(
        # all providers:
        prompt_content = prompt_reactive(),
        model = input$model,
        max_tokens = input$max_tokens,
        temperature = input$temperature,
        prompt_role = input$prompt_role,
        stop = input$stop,
        seed = input$seed,
        top_p = input$top_p,
        # DeepSeek & OpenAI:
        n = input$n,
        # OpenAi:
        presence_penalty = input$presence_penalty,
        frequency_penalty = input$frequency_penalty,
        logprobs = input$logprobs
      ) |>
        shinyTryCatch(errorTitle = "Prompt inputs setup failed", alertStyle = "shinyalert")

      llm_prompt_config(new_settings)
    })

    statusMessageServer(
      "settings_status",
      object = llm_prompt_config,
      success_message = "Prompt inputs ready!",
      warning_message = "Prompt inputs warning!",
      error_message   = "Prompt inputs error!"
    )

    llm_prompt_config
  })
}


# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   titlePanel("LLM Prompt Settings Module"),
#   llm_prompt_config_ui("llm_settings"),
#   verbatimTextOutput("params")
# )
#
# server <- function(input, output, session) {
#   prompt_config <- llm_prompt_config_server("llm_settings", llm_api = reactiveVal(list(provider = "OpenAI")))
#
#   output$params <- renderPrint({
#     prompt_config()
#   })
# }
#
# shinyApp(ui, server)
