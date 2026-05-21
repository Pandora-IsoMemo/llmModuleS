# LLM Prompt Generator Server Module

Server-side logic for handling prompt input, LLM API interaction,
response handling, and error/status display.

## Usage

``` r
llm_generate_prompt_server(
  id,
  auto_complete_list = reactive(NULL),
  no_internet = NULL,
  exclude_pattern = ""
)
```

## Arguments

- id:

  A string specifying the module namespace, matching the \`id\` used in
  \`llm_generate_prompt_ui\`.

- auto_complete_list:

  A reactive list.

- no_internet:

  logical

- exclude_pattern:

  character, a regex pattern to exclude certain models from the list of
  available models, e.g.
  "babbage\|curie\|dall-e\|davinci\|text-embedding\|tts\|whisper"

## Value

A reactive value (\`reactiveVal\`) containing the generated response
tables, which can be used for further processing in the app.

## Details

The server module: - Initializes the LLM API and prompt configuration
modules. - Enables or disables the "Generate Text" button based on
configuration readiness. - On click, sends a prompt to the API and
stores the result in a \`reactiveVal\`. - Uses \`statusMessageServer()\`
to provide feedback on the response generation status. - Renders the LLM
response using \`renderPrint()\` if UI is configured to do so.

It depends on these additional server modules: - \`llm_api_server()\`
for managing API key and connection - \`llm_prompt_config_server()\` for
prompt tuning options - \`statusMessageServer()\` to show status
messages like success, warning, or error

## See also

[`llm_generate_prompt_ui`](https://pandora-isomemo.github.io/llmModuleS/reference/llm_generate_prompt_ui.md)
for the UI component.
