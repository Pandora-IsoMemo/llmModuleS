# llmModuleS

`llmModuleS` provides reusable Shiny modules and an app entry point for
generating text with Large Language Models (LLMs).

This package is focused on the Shiny layer and uses `llmModule` for core
LLM API abstractions and request handling.

## Overview

`llmModuleS` contains:

- A complete prompt-generation Shiny module
  ([`llm_generate_prompt_ui()`](https://pandora-isomemo.github.io/llmModuleS/reference/llm_generate_prompt_ui.md)
  /
  [`llm_generate_prompt_server()`](https://pandora-isomemo.github.io/llmModuleS/reference/llm_generate_prompt_server.md))
- An application launcher
  ([`startApplication()`](https://pandora-isomemo.github.io/llmModuleS/reference/startApplication.md))
- Internal module components for:
  - API/provider setup (OpenAI, DeepSeek, and Ollama if available)
  - Prompt settings (basic and advanced)
  - Status message rendering for success/warning/error feedback

Supported providers in the UI:

- OpenAI
- DeepSeek
- Ollama (local), when available and not running in a restricted
  ShinyProxy setup

## Exported Functions

- `llm_generate_prompt_ui(id, ...)`
- `llm_generate_prompt_server(id, ...)`
- `startApplication(port = ..., host = ..., launch.browser = ...)`

## Installation

Install development dependencies first if needed:

``` r

install.packages(c("devtools", "remotes"))
```

Install from local source:

``` r

devtools::install(".")
```

## Quick Example: Use the Module in Your Own Shiny App

``` r

library(shiny)
library(shinyjs)
library(llmModuleS)

ui <- fluidPage(
  useShinyjs(),
  titlePanel("LLM Prompt Generator"),
  llm_generate_prompt_ui("single_prompt", output_response = TRUE)
)

server <- function(input, output, session) {
  llm_generate_prompt_server("single_prompt")
}

shinyApp(ui, server)
```

## Run the Packaged App

``` r

library(llmModuleS)
startApplication(launch.browser = TRUE)
```

The app loads from `inst/app` inside the installed package.

## Behavior Summary

- Provider selection controls how API setup is handled:
  - OpenAI/DeepSeek: accepts an uploaded API key file (or uses defaults
    when supported)
  - Ollama: can initialize local API access and optionally pull a model
- Prompt settings include model selection, temperature, max tokens, and
  provider-specific advanced controls
- The Generate button is enabled only when API and prompt configuration
  are valid
- Response status is surfaced to the UI with success, warning, or error
  messages

## Testing

Unit tests are implemented with `testthat`.

Run all tests:

``` r

devtools::test()
```

Current tests include API validation behavior in the Shiny API module
(for example invalid and too-short OpenAI key scenarios).

## Package Relationship

`llmModuleS` depends on `llmModule` (\>= 26.05.0) for the underlying LLM
objects and API operations.

If you are looking for lower-level LLM API classes/functions, use
`llmModule` directly.

## Documentation

Pkgdown site:

- <https://pandora-isomemo.github.io/llmModuleS/>

## Notes for developers

When adding information to the *help* sites, *docstrings* or the
*vignette* of this package, please update documentation locally as
follows. The documentation of the main branch is build automatically via
github action.

``` r

devtools::document() # or CTRL + SHIFT + D in RStudio
devtools::build_site()
```

When testing with a local docker container, please make sure to rebuild
the docker image after changes in the R code or dependencies. You can do
this from the root of the repository via:

``` bash
docker build -t llm-module-s:latest .
```

After that, start the container as usual via:

``` bash
docker run -p 3838:3838 llm-module-s:latest
```

and access the app in your browser at `http://localhost:3838/`. Stop the
container with `CTRL + C` in the terminal.

**Optional:**

Add `-it` for interactive mode, or `--rm` to remove the container after
stopping.
