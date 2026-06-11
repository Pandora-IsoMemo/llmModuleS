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
    provider_default_model_sentinel <- "__provider_default_model__"

    llm_prompt_config <- reactiveVal()
    model_info_cache <- reactiveValues(entries = list())

    # possibly load default values from config later ...
    fields_advanced_all <- list(
      list(fun = selectInput, args = list(ns("prompt_role"), "Prompt Role", c("user", "system", "assistant"))),
      list(fun = sliderInput, args = list(ns("top_p"), "Top-p", min = 0, max = 1, value = 1, step = 0.01)),
      list(fun = numericInput, args = list(ns("seed"), "Seed (optional)", value = NA, min = 1, step = 1)),
      list(fun = textInput, args = list(ns("stop"), "Stop Sequence (optional)", placeholder = "e.g. ### or <end>"))
    )

    fields_advanced_provider <- list(
      Ollama = list(),
      Bridge = list(
        list(fun = numericInput, args = list(ns("n"), "No. of Completions (n)", value = 1, min = 1))
      ),
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

    fingerprint_text <- function(value) {
      if (is.null(value)) {
        return("")
      }

      text <- paste(value, collapse = "")
      paste0(sprintf("%02x", as.integer(charToRaw(text))), collapse = "")
    }

    model_cache_key <- function(api) {
      provider <- if (!is.null(api$provider)) api$provider else "unknown"
      auth_key <- fingerprint_text(if (!is.null(api$api_key)) api$api_key else "")
      paste(class(api)[1], provider, auth_key, sep = "|")
    }

    get_cached_model_info <- function(api) {
      key <- model_cache_key(api)
      model_info_cache$entries[[key]]
    }

    set_cached_model_info <- function(api, model_info) {
      key <- model_cache_key(api)
      entries <- model_info_cache$entries
      entries[[key]] <- model_info
      model_info_cache$entries <- entries
      model_info
    }

    output$advancedInputs <- renderUI({
      req(llm_api(), llm_api()$provider)
      logDebug("%s: Rendering advanced inputs for provider '%s'", id, llm_api()$provider)

      provider_fields <- fields_advanced_provider[[llm_api()$provider]]
      if (is.null(provider_fields)) {
        provider_fields <- fields_advanced_provider$Bridge
      }

      tagList(
        fluidRow(
          lapply(fields_advanced_all, function(f) column(3, do.call(f$fun, f$args)))
        ),
        fluidRow(
          lapply(provider_fields, function(f) column(3, do.call(f$fun, f$args)))
        )
      )
    })

    observe({
      logDebug("%s: Updating model choices", id)
      api <- llm_api()

      cached_model_info <- if (inherits(api, "LlmApi")) get_cached_model_info(api) else NULL

      if (!is.null(cached_model_info)) {
        logDebug("%s: Using cached model metadata for provider '%s'", id, api$provider)
        model_info <- cached_model_info
      } else if (inherits(api, "LlmApi")) {
        model_info <- get_llm_models_info(api, with_creds_only = TRUE) |>
          shinyTryCatch(errorTitle = "Getting models failed", alertStyle = "shinyalert")

        if (!is_LlmModelsInfo(model_info)) { # in case of error during fetching models
          model_info <- new_empty_LlmModelsInfo(provider = api$provider, listing_status = "error")
        }

        set_cached_model_info(api, model_info)
      } else { # if api is not LlmApi
        model_info <- new_empty_LlmModelsInfo(listing_status = "error")
      }

      models <- as_model_choices(model_info)
      can_fallback_to_provider_default <- llm_models_can_fallback(model_info)

      choices <- if (length(models) == 0) {
        if (can_fallback_to_provider_default) {
          c("Use provider default model" = provider_default_model_sentinel)
        } else {
          c("No models found..." = "")
        }
      } else {
        models
      }
      updateSelectInput(session, "model", choices = choices)
    }) |>
      bindEvent(llm_api())

    observe({
      req(prompt_reactive())
      logDebug("%s: Updating prompt configuration", id)

      selected_model <- input$model
      using_provider_default <- identical(selected_model, provider_default_model_sentinel) || identical(selected_model, "")
      selected_model <- if (using_provider_default) NULL else selected_model

      new_settings <- new_LlmPromptConfig(
        # all providers:
        prompt_content = prompt_reactive(),
        model = selected_model,
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

      if (inherits(new_settings, "LlmPromptConfig") && using_provider_default) {
        provider <- if (inherits(llm_api(), "LlmApi") && !is.null(llm_api()$provider)) llm_api()$provider else "selected provider"
        default_msg <- sprintf("No explicit model selected; using the provider default model for '%s'.", provider)
        new_settings <- append_attr(new_settings, default_msg, "message")
      }

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
