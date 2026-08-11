logging <- function(msg, ...) {
  futile.logger::flog.info(msg, ...)
}

logDebug <- function(msg, ...) {
  futile.logger::flog.debug(msg, ...)
}

logWarn <- function(msg, ...) {
  futile.logger::flog.warn(msg, ...)
}

init_logging <- function() {
  show_debug <- tolower(Sys.getenv("SHOW_DEBUG", unset = "false")) %in% c("true", "1", "yes", "y")

  if (isTRUE(show_debug)) {
    futile.logger::flog.threshold(futile.logger::DEBUG)
    base::packageStartupMessage("Logger initialized: threshold = DEBUG")
  } else {
    futile.logger::flog.threshold(futile.logger::INFO)
    base::packageStartupMessage("Logger initialized: threshold = INFO")
  }
}