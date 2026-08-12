# llmModuleS 26.08.1

## Updates
- Increased image and updated dependencies in Dockerfile

# llmModuleS 26.08.0

## Updates
- Updated the Shiny modules to support “bridge” providers (via new_BridgedLlmApi), improved model metadata handling in prompt settings, and added package-level logging initialization.
- Replaced file-upload API key input with a password field; keys are now passed directly as strings instead of file paths.

## Bug Fixes
- Replaced reversible hex encoding of API keys in the model cache key with a one-way SHA-256 hash (`openssl`).

# llmModuleS 26.05.1

## Updates
- Fixed output format of `llm_generate_prompt` for easier integration into `DataTools` package

# llmModuleS 26.05.0

## New Features
- extracted shiny modules from `llmModule` into separate `llmModuleS` package

