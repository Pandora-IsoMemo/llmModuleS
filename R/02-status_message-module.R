# ---- Constructor ----
new_StatusMessage <- function(
    object,
    success_message = "Connection successful!",
    warning_message = "Connection incomplete.",
    error_message = "Connection failed!"
) {
  combine_message <- function(object, attr_name, default_msg = NULL) {
    val <- attr(object, attr_name)
    if (!is.null(val)) {
      c(default_msg, val)
    } else {
      NULL
    }
  }

  err <- combine_message(object, "error", error_message)
  warn <- combine_message(object, "warning", warning_message)
  if (is.null(err) && is.null(warn)) {
    success <- combine_message(object, "message", success_message)
    if (is.null(success)) success <- success_message
  } else {
    success <- NULL
  }

  structure(
    list(success = success, warning = warn, error = err),
    class = "StatusMessage"
  )
}

# ---- Extractor ----
extractMessage <- function(object, type = c("error", "warning", "success")) {
  type <- match.arg(type)
  if (!inherits(object, "StatusMessage")) return(NULL)
  object[[type]]
}

# ---- Module UI ----
status_message_ui <- function(id) {
  ns <- NS(id)

  div(
    #style = "height: 9em",
    div(class = "text-danger", uiOutput(ns("error"))),
    div(class = "text-warning", uiOutput(ns("warning"))),
    div(class = "text-success", uiOutput(ns("success")))
  )
}

# ---- Module Server ----
statusMessageServer <- function(id, object, ...) {
  moduleServer(id, function(input, output, session) {
    observe({
      status <- new_StatusMessage(object(), ...)

      output$error <-
        renderUI(tagList(lapply(
          extractMessage(status, type = "error"), function(msg) tags$p(strip_ansi(msg))
        )))
      output$warning <-
        renderUI(tagList(lapply(
          extractMessage(status, type = "warning"), function(msg) tags$p(strip_ansi(msg))
        )))
      output$success <-
        renderUI(tagList(lapply(
          extractMessage(status, type = "success"), function(msg) tags$p(strip_ansi(msg))
        )))
    }) |>
      bindEvent(object())
  })
}

strip_ansi <- function(x) {
  gsub("\033\\[[0-9;]*m", "", x)
}

# ---- Test App ----
# To test the module run devtools::load_all() first
# Please comment this code before building the package

# ui <- fluidPage(
#   titlePanel("Test Status Message Module"),
#   actionButton("toggle", "Toggle API Status"),
#   br(), br(),
#   status_message_ui("status")
# )
#
# server <- function(input, output, session) {
#   # Reactive flag to toggle between valid and invalid API object
#   valid <- reactiveVal(TRUE)
#
#   observeEvent(input$toggle, {
#     valid(!valid())
#   })
#
#   test_object <- reactive({
#     if (valid()) {
#       structure(
#         list(api_key = "key", url = "url", provider = "provider"),
#         class = "RemoteLlmApi"
#       )
#     } else {
#       obj <- list()
#       attr(obj, "error") <- "API key failed validation request."
#       obj
#     }
#   })
#
#   statusMessageServer("status", object = test_object)
# }
#
# shinyApp(ui, server)
