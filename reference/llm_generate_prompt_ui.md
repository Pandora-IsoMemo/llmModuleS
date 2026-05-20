# LLM Prompt Generator UI Module

Provides a user interface to enter a prompt, configure LLM API access,
and optionally display the generated text output.

## Usage

``` r
llm_generate_prompt_ui(
  id,
  prompt_beginning = "",
  prompt_placeholder = "Ask me anything...",
  theme = "xcode",
  output_response = FALSE
)
```

## Arguments

- id:

  A unique string identifying the module namespace.

- prompt_beginning:

  Optional character string shown as a prefix label before the prompt
  input. Default is \`""\`.

- prompt_placeholder:

  Placeholder text shown in the prompt input field. Default is \`"Ask me
  anything..."\`.

- theme:

  Editor theme for the ACE input. Defaults to \`"xcode"\`.

- output_response:

  Logical; whether to show the generated response output below the input
  UI. Default is \`FALSE\`.

## Value

A UI definition (tagList) that can be included in a Shiny app.

## Details

This module renders the following elements: - LLM API configuration UI
(via \`llm_api_ui\`) - Prompt configuration UI (via
\`llm_prompt_config_ui\`) - An ACE code editor for prompt input - A
"Generate Text" button with status messaging - Optional display of the
generated response (controlled by \`output_response\`)

## See also

[`llm_generate_prompt_server`](https://pandora-isomemo.github.io/llmModuleS/reference/llm_generate_prompt_server.md)
for the server-side logic.
