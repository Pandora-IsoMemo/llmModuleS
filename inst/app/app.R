library(llmModuleS)


ui <- shiny::fluidPage(
  shinyjs::useShinyjs(),
  shiny::titlePanel("LLM Prompt Module Test"),
  llm_generate_prompt_ui("single_prompt", output_response = TRUE)
)

server <- function(input, output, session) {
  llm_generate_prompt_server("single_prompt")
}

shiny::shinyApp(ui, server)
