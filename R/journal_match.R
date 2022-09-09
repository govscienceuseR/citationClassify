#' Match to Scimago journal index
#'
#' Creates a logical vector as to whether a journal name is an exact match to an index of Scimago journals
#'
#' @param x vector of potential journal names, typically the 'container' or 'journal.disam' column from the govscienceuseR workflow, but the column can be any name
#' #' @param append logical (T or F) argument to whether user wants to add their own list of journals to be indexed. Default append = F
#' @param append_df if append = T, a data frame with one character column named 'title' to append to the built-in index
#'
#' @return logical vector indicating an exact match for the journal index
#'
#' @examples dt$journal_match <- journal_match(dt$container)
#'
#' @export

journal_match <- function(x, append = F, append_df){
  scimago.j <- fread("~/Box/truckee/data/eia_data/journal_list.csv", fill= T)
  if(append == T){
    scimago.j <- rbind(scimago.j, append_df)
  }
  journal_match <- ifelse(x %in% scimago.j$title, T, F)
  return(journal_match)
}