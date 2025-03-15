# reticulate bindings for the bioread library:
# https://github.com/uwmadison-chm/bioread

#' Check if all requirements are satisfied
#'
#' @return TRUE if all requirements are satisfied, FALSE otherwise
#'
#' @keywords internal
bioread_available <- function() {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    warning("R package 'reticulate' is required but not available.")
    return(FALSE)
  }
  if (!reticulate::py_module_available("bioread")) {
    warning("Python package 'bioread' is not available.")
    return(FALSE)
  }
  TRUE
}

#' Read a BIOPAC AcqKnowledge file
#'
#' @param file Path to an .acq file
#' @param channel_indexes Specific channel indexes to load data for (NULL loads all channels)
#'
#' @return A named list containing .acq data in R format, or
#'         NULL if the python bioread isn't available. The list contains:
#' \describe{
#'   \item{channels}{A list of channel data and metadata}
#'   \item{markers}{A list of markers}
#'   \item{journal}{A character vector of journal text}
#' }
#'
#' @details
#' The \code{channels} component is a list of channels, each containing:
#' \describe{
#'   \item{time}{A vector of time points}
#'   \item{data}{A vector of channel data}
#'   \item{name}{The channel name}
#'   \item{units}{The channel units}
#'   \item{samples_per_second}{The number of samples per second}
#' }
#'
#' The \code{markers} component is a list of markers, each containing:
#' \describe{
#'   \item{time_index}{The time index of the marker, in seconds}
#'   \item{sample_index}{The sample index of the marker}
#'   \item{text}{The marker text}
#'   \item{channel_number}{The channel number of the marker}
#'   \item{channel_name}{The channel name of the marker}
#'   \item{type}{The type of marker}
#'   \item{color_rgba}{The color of the marker, as a 4-element vector of RGBA byte values}
#'   \item{date_created}{The date and time the marker was created, in ISO 8601 format}
#' }
#'
#' Some marker components are NULL for some file versions.
#'
#' @examples
#' library(bioread)
#' acq_file <- system.file("extdata", "physio-5.0.1-c.acq", package = "bioread")
#' acq_data <- read_acq(acq_file)
#'
#' if (!is.null(acq_data)) {
#'   channel <- acq_data$channels[[1]]
#'
#'   # Plot the first channel
#'   plot(
#'     channel$time, channel$data, type = "l", xlab = "Time (s)",
#'     ylab = channel$units, main = channel$name)
#' }
#' @export
read_acq <- function(file, channel_indexes = NULL) {
  if (!bioread_available()) {
    return(NULL)
  }

  br <- reticulate::import("bioread", delay_load = TRUE)

  # Convert R indexes to python indexes
  if (!is.null(channel_indexes)) {
    channel_indexes <- lapply(channel_indexes - 1, as.integer)
  }
  py_data <- br$read(file, channel_indexes = channel_indexes)

  result <- list()
  result$channels <- lapply(py_data$channels, format_channel)
  result$markers <- lapply(py_data$event_markers, format_marker)
  result$journal <- py_data$journal

  return(result)
}

#' Convert a python channel to something better for R
#'
#' @param pych A channel in Python format
#'
#' @return A channel in R format
#'
#' @keywords internal
format_channel <- function(pych) {
  rch <- list()
  rch$time <- pych$time_index
  rch$data <- pych$data
  rch$name <- pych$name
  rch$units <- pych$units
  rch$samples_per_second <- pych$samples_per_second
  rch
}

#' Convert a python marker to a better R format
#'
#' @param pym A marker in Python format
#'
#' @return A marker in R format
#'
#' @keywords internal
format_marker <- function(pym) {
  rmark <- list()
  rmark$time_index <- pym$time_index
  rmark$sample_index <- as.integer(pym$sample_index + 1) # Python is 0-based, R is 1-based
  rmark$text <- pym$text
  rmark$channel_number <- pym$channel_number + 1 # Python is 0-based, R is 1-based
  rmark$channel_name <- pym$channel_name
  rmark$type <- pym$type
  rmark$color_rgba <- pym$color
  rmark$date_created <- pym$date_created_str
  rmark
}
