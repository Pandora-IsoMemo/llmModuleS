# ---- UI Function ----
llm_api_ui <- function(id, title = NULL) {
  ns <- NS(id)

  ollama_available <- tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "false" && is_ollama_running()

  providers_legacy <- c("OpenAI" = "OpenAI", "DeepSeek" = "DeepSeek")

  providers_ellmer <- eligible_ellmer_providers()

  provider_choices <- providers_ellmer[["provider_key"]]
  names(provider_choices) <- providers_ellmer[["provider_name"]]

  # remove providers that are already in legacy list
  provider_choices <- provider_choices[!names(provider_choices) %in% names(providers_legacy)]

  provider_choices <- c(providers_legacy, provider_choices)

  if (ollama_available) {
    # remove Ollama from provider choices if available, since it gets its own special UI treatment
    # and is the default when running in Docker
    provider_choices <- provider_choices[!names(provider_choices) == "Ollama"]

    provider_choices <- c("Ollama (Local)" = "Ollama", provider_choices)
  }

  tagList(
    if (!is.null(title)) h3(title) else NULL,
    fluidRow(
      column(3, selectInput(ns("provider"), "Choose Provider", choices = provider_choices, selected = character(0))),
      conditionalPanel(
        ns = ns,
        condition = "input.provider != 'Ollama'",
        column(5, fileInput(ns("api_key_file"), "Upload API Key File", accept = c(".txt")))
      ),
      conditionalPanel(
        ns = ns,
        condition = "input.provider == 'Ollama'",
        column(3, textInput(ns("new_model"), "Pull model", placeholder = "tinyllama")),
        column(2, style = "margin-top: 1.75em", actionButton(ns("pull_ollama"), "Pull"))
      ),
      column(4, align = "right", status_message_ui(ns("api_status")))
    ),
  )
}

# ---- Server Function ----
llm_api_server <- function(id, no_internet = NULL, exclude_pattern = "") {
  moduleServer(id, function(input, output, session) {
    # Reactive values
    api <- reactiveVal(NULL)
    ollama_available <- requireNamespace("ollamar", quietly = TRUE) &&
      tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "false" &&
      is_ollama_running()


    # Initialize manager
    manager <- reactiveVal(NULL)
    if (ollama_available) {
      logDebug("%s: Initializing Ollama Model Manager", id)
      manager(update(new_OllamaModelManager()))
    }


    # Cache the uploaded API key path (only when a new file is uploaded)
    api_key_path <- reactive({
      input$api_key_file$datapath
    })

    # Trigger remote/bridge API creation when file is uploaded
    remote_api <- reactive({
      req(length(input$provider) == 1, input$provider != "Ollama")
      logDebug("%s: Initializing remote API", id)

      api_key_path <- NULL
      if (!is.null(input$api_key_file)) {
        api_key_path <- input$api_key_file$datapath
      }

      new_BridgedLlmApi(
        api_key_path = api_key_path,
        provider = input$provider,
        no_internet = no_internet,
        exclude_pattern = exclude_pattern
      ) |>
        shinyTryCatch(errorTitle = "API setup failed", alertStyle = "shinyalert")
    })

    # Trigger local API creation when pull button is clicked
    local_api <- eventReactive(input$pull_ollama, {
      req(isTRUE(ollama_available), input$new_model)
      new_LocalLlmApi(manager(), input$new_model)
    })

    # Default to initializing Ollama if selected (no pull)
    observeEvent(input$provider, {
      if (ollama_available && input$provider == "Ollama") {
        logDebug("%s: Initializing Ollama API", id)
        new_api <- new_LocalLlmApi(manager()) |>
          shinyTryCatch(errorTitle = "API setup failed", alertStyle = "shinyalert")
        api(new_api)
      }
    })

    # Watch the remote and local API creators and update the shared reactiveVal
    observeEvent(remote_api(), {
      logDebug("%s: Updating API with remote API", id)
      api(remote_api())
    })

    observeEvent(local_api(), {
      logDebug("%s: Updating API with local API", id)
      api(local_api())
    })

    statusMessageServer(
      "api_status",
      object = api,
      success_message = "Connection test successful!",
      warning_message = "Connection test warning!",
      error_message = "Connection test failed!"
    )

    # Return reactive values
    return(api)
  })
}

# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   titlePanel("LLM API Test App"),
#   sidebarLayout(
#     sidebarPanel(
#       llm_api_ui("llm")
#     ),
#     mainPanel(
#       verbatimTextOutput("api")
#     )
#   )
# )
#
# server <- function(input, output, session) {
#   llm_api <- llm_api_server("llm")
#
#   output$api <- renderPrint({
#     llm_api()
#   })
# }
#
# shinyApp(ui, server)
