# Append attribute to object
append_attr <- function(object, val, attr_name) {
  existing <- attr(object, attr_name)
  attr(object, attr_name) <- c(existing, val)
  object
}