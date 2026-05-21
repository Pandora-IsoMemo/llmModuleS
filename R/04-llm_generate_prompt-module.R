#' LLM Prompt Generator UI Module
#'
#' Provides a user interface to enter a prompt, configure LLM API access, and optionally display the generated text output.
#'
#' @param id A unique string identifying the module namespace.
#' @param prompt_beginning Optional character string shown as a prefix label before the prompt input. Default is `""`.
#' @param prompt_placeholder Placeholder text shown in the prompt input field. Default is `"Ask me anything..."`.
#' @param theme Editor theme for the ACE input. Defaults to `"xcode"`.
#' @param output_response Logical; whether to show the generated response output below the input UI. Default is `FALSE`.
#'
#' @return A UI definition (tagList) that can be included in a Shiny app.
#'
#' @details
#' This module renders the following elements:
#' - LLM API configuration UI (via `llm_api_ui`)
#' - Prompt configuration UI (via `llm_prompt_config_ui`)
#' - An ACE code editor for prompt input
#' - A "Generate Text" button with status messaging
#' - Optional display of the generated response (controlled by `output_response`)
#'
#' @seealso \code{\link{llm_generate_prompt_server}} for the server-side logic.
#'
#' @export
llm_generate_prompt_ui <- function(id,
                                   prompt_beginning = "",
                                   prompt_placeholder = "Ask me anything...",
                                   theme = "xcode",
                                   output_response = FALSE) {
  ns <- NS(id)

  tagList(
    llm_api_ui(ns("api")),
    tags$br(),
    llm_prompt_config_ui(ns("prompt_config")),
    div(style = "margin-bottom: 0.5em;",
        tags$html(
          HTML(sprintf("<b>Prompt Input:</b> &nbsp;&nbsp; %s", prompt_beginning))
        )),
    shinyAce::aceEditor(
      ns("prompt"),
      value = NULL,
      mode = "text",
      theme = theme,
      fontSize = 16,
      autoScrollEditorIntoView = TRUE,
      minLines = 3,
      maxLines = 5,
      autoComplete = "live",
      placeholder = prompt_placeholder
    ),
    fluidRow(
      column(4, actionButton(ns("generate"), "Generate Text")),
      column(8, align = "right", status_message_ui(ns("response_status"))),

    ),
    hr(),
    if (output_response) verbatimTextOutput(ns("generated_text")) else NULL
  )
}

#' LLM Prompt Generator Server Module
#'
#' Server-side logic for handling prompt input, LLM API interaction, response handling, and error/status display.
#'
#' @param id A string specifying the module namespace, matching the `id` used in `llm_generate_prompt_ui`.
#' @param no_internet logical
#' @param auto_complete_list A reactive list.
#' @param exclude_pattern character, a regex pattern to exclude certain models from the list of
#'   available models, e.g. "babbage|curie|dall-e|davinci|text-embedding|tts|whisper"
#'
#' @return A reactive value (`reactiveVal`) containing the generated response tables, which
#'  can be used for further processing in the app.
#'
#' @details
#' The server module:
#' - Initializes the LLM API and prompt configuration modules.
#' - Enables or disables the "Generate Text" button based on configuration readiness.
#' - On click, sends a prompt to the API and stores the result in a `reactiveVal`.
#' - Uses `statusMessageServer()` to provide feedback on the response generation status.
#' - Renders the LLM response using `renderPrint()` if UI is configured to do so.
#'
#' It depends on these additional server modules:
#' - `llm_api_server()` for managing API key and connection
#' - `llm_prompt_config_server()` for prompt tuning options
#' - `statusMessageServer()` to show status messages like success, warning, or error
#'
#' @seealso \code{\link{llm_generate_prompt_ui}} for the UI component.
#'
#' @export
llm_generate_prompt_server <- function(id, auto_complete_list = reactive(NULL), no_internet = NULL, exclude_pattern = "") {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    llm_api_reactive <- llm_api_server("api", no_internet = no_internet, exclude_pattern = exclude_pattern)
    prompt_config_reactive <- llm_prompt_config_server("prompt_config", llm_api_reactive, reactive(input$prompt))

    llm_response <- reactiveVal()
    llm_response_tables <- reactiveVal()

    # disable generate button if no API key is available
    observe({
      if (!inherits(llm_api_reactive(), "LlmApi") || !inherits(prompt_config_reactive(), "LlmPromptConfig")) {
        shinyjs::disable(ns("generate"), asis = TRUE)
      } else {
        shinyjs::enable(ns("generate"), asis = TRUE)
      }
    })

    # UPDATE AceEditor's auto-complete ----
    observe({
      logDebug("%s: update prompt", id)
      shinyAce::updateAceEditor(
        session = session,
        "prompt",
        autoCompleters = c("snippet", "text", "static", "keyword"),
        autoCompleteList = unlist(auto_complete_list(), use.names = FALSE)
      )
    }) |>
      bindEvent(auto_complete_list(),
                ignoreNULL = FALSE,
                ignoreInit = TRUE)

    observe({
      new_response <- llmModule::new_LlmResponse(
        llm_api_reactive(), prompt_config_reactive()
      ) |>
        withProgress(
          message = "Generating response...",
          value = 0.5,
          min = 0,
          max = 1,
          detail = "Please wait..."
        ) |>
        shinyTryCatch(errorTitle = "Prompt generation failed", alertStyle = "shinyalert")

      llm_response(new_response)
    }) |>
      bindEvent(input$generate)

    statusMessageServer(
      "response_status",
      object = llm_response,
      success_message = "Response ready!",
      warning_message = "Response incomplete!",
      error_message   = "Response generation failed!"
    )

    output$generated_text <- renderPrint({
      validate(need(inherits(llm_response(), "LlmResponse"), "No response available."))

      response_tables <- llm_response() |>
        llmModule::as_table(output_type = "complete")
      llm_response_tables(response_tables)

      response_tables$core_output$content |> cat()
    })

    return(llm_response_tables)
  })
}

# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   shinyjs::useShinyjs(),
#   titlePanel("LLM Prompt Module Test"),
#   llm_generate_prompt_ui("single_prompt")
# )
#
# server <- function(input, output, session) {
#   llm_generate_prompt_server("single_prompt")
# }
#
# shinyApp(ui, server)
