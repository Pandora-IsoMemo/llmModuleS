# ---- UI Function ----
llm_api_ui <- function(id, title = NULL) {
  ns <- NS(id)

  ollama_available <- tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "false" && llmModule::is_ollama_running()

  provider_choices <- c("OpenAI" = "OpenAI", "DeepSeek" = "DeepSeek")
  if (ollama_available) {
    provider_choices <- c(provider_choices, "Ollama (Local)" = "Ollama")
  }

  tagList(
    if (!is.null(title)) h3(title) else NULL,
    fluidRow(
      column(3, radioButtons(ns("provider"), "Choose Provider", choices = provider_choices, selected = character(0))),
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
    ns <- session$ns
    # Reactive values
    api <- reactiveVal(NULL)
    ollama_available <- requireNamespace("ollamar", quietly = TRUE) &&
      tolower(Sys.getenv("IS_SHINYPROXY", "false")) == "false" &&
      llmModule::is_ollama_running()


    # Initialize manager
    manager <- reactiveVal(NULL)
    if (ollama_available) {
      manager(llmModule::update(llmModule::new_OllamaModelManager()))
    }


    # Cache the uploaded API key path (only when a new file is uploaded)
    api_key_path <- reactive({
      input$api_key_file$datapath
    })

    # Trigger remote API creation when file is uploaded
    remote_api <- reactive({
      req(input$provider %in% c("OpenAI", "DeepSeek"))
      if (!is.null(input$api_key_file)) {
        llmModule::new_RemoteLlmApi(
          api_key_path = input$api_key_file$datapath,
          provider = input$provider,
          no_internet = no_internet,
          exclude_pattern = exclude_pattern
        ) |>
          shinyTryCatch(errorTitle = "API setup failed", alertStyle = "shinyalert")
      } else {
        llmModule::new_RemoteLlmApi(
          provider = input$provider,
          no_internet = no_internet,
          exclude_pattern = exclude_pattern
        ) |>
          shinyTryCatch(errorTitle = "API setup failed", alertStyle = "shinyalert")
      }
    })

    # Trigger local API creation when pull button is clicked
    local_api <- eventReactive(input$pull_ollama, {
      req(isTRUE(ollama_available), input$new_model)
      llmModule::new_LocalLlmApi(manager(), input$new_model)
    })

    # Default to initializing Ollama if selected (no pull)
    observeEvent(input$provider, {
      if (ollama_available && input$provider == "Ollama") {
        new_api <- llmModule::new_LocalLlmApi(manager()) |>
          shinyTryCatch(errorTitle = "API setup failed", alertStyle = "shinyalert")
        api(new_api)
      }
    })

    # Watch the remote and local API creators and update the shared reactiveVal
    observeEvent(remote_api(), {
      api(remote_api())
    })

    observeEvent(local_api(), {
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
