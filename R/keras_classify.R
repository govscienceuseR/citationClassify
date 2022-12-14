#' Run Keras Model on Data
#'
#' Makes a prediction about the classification of the reference -- a journal, an agency, a conference, or not a reference. Classifications are designated based on 95% confidence
#'
#' @param df a data frame with the input data
#' @param download_dir the location where the keras model data will be downloaded, defaults to home directory
#' @param probability a numeric value between 0-1 indicating that value
#' @param journal_column the name of the column that contains journal articles, as a character object. If using the govscienceuseR workflow, this column name is either container, journal, or journal_disam.
#' @param auto_input a logical value where if T, the function automatically assign the model input based on a series of conditions. If F, assign your own input_column argument. Default is set to TRUE.
#' @param input_column if auto_input = FALSE, the name of the column to use as the model input, as a character object
#' @return a data frame with ffive columns: four representing the probabilities for each class and a fifth column with the classification category based on probability specified in the probability argument
#'
#' @examples dt <- keras_classify(dt, .85, 'journal_disam') # with auto input
#' @examples dt <- keras_classify(dt, .85, 'journal_disam', auto_input = F, 'input') # manually specifying input
#'
#' @import keras
#' @import tensorflow
#' @import dplyr
#' @import data.table
#' @import magrittr
#' @import stringr
#' @export


keras_classify <- function(df, probability = .9,
                           journal_column, auto_input = T, input_column){

  # Below does not work, creates a null pointer
  ## model <- keras::load_model_tf("data/k_model")
  ## usethis::use_data(model)
  ## data("model", envir=environment())

  # This works internally but not functional for package
  ## model <- keras::load_model_tf("data/k_model")

  # What if I have the function locally download the data before running?
##   urls <- c("https://github.com/govscienceuseR/referenceClassify/blob/master## /data/k_model/keras_metadata.pb",
##             "https://github.com/govscienceuseR/referenceClassify/blob/master## /data/k_model/saved_model.pb",
##             "https://github.com/govscienceuseR/referenceClassify/blob/master## /data/k_model/variables/variables.data-00000-of-00001",
##             "https://github.com/govscienceuseR/referenceClassify/blob/master## /data/k_model/variables/variables.index"
##             )
##
##   tempdir_model <- file.path(tempdir(), "keras")
##   tempdir_var <- file.path(paste0(tempdir_model, "/variables"))
##   tempdir_assets <- file.path(paste0(tempdir_model, "/assets"))
##   dir.create(tempdir_model)
##   dir.create(tempdir_var)
##   dir.create(tempdir_assets)
##
##   download.file(url = urls[1],
##                 destfile = paste0(tempdir_model,
##                                   '/keras_metadata.pb'))
##   download.file(url = urls[2],
##                 destfile = paste0(tempdir_model,
##                                   '/saved_model.pb'))
##   download.file(url = urls[3],
##                 destfile = paste0(tempdir_var,
##                                   '/variables.data-00000-of-00001'))
##   download.file(url = urls[4],
##                 destfile = paste0(tempdir_var,
##                                   '/variables.index'))
##   model <- load_model_tf(tempdir_model)
  model <- keras::load_model_tf("data/k_model")

  if(auto_input == T){
    df$container_match_journal <- df[[journal_column]] %in% scimago.j$title
    df$pub_match_journal <- df$publisher %in% scimago.j$title
    df$container_match_agency <- df[[journal_column]] %in% agencies$Agency
    df$author_match_agency <- df$author %in% agencies$Agency
    df$pub_match_agency <- df$publisher %in% agencies$Agency
    df$container_match_conf <- df[[journal_column]] %in% scimago.c$title
    df$pub_match_conf <- df$publisher %in% scimago.c$title

    df <- df %>%
      mutate(input = case_when(
        container_match_journal == T ~ journal_column,
        pub_match_journal == T ~ publisher,
        author_match_agency == T ~ author,
        container_match_agency == T ~ journal_column,
        pub_match_agency == T ~ publisher,
        container_match_conf == T ~ journal_column,
        pub_match_conf == T ~ publisher,
        container_match_agency_p ~ journal_column,
        author_match_agency_p ~ author,
        pub_match_agency_p ~ publisher,
        !is.na(doi) ~ doi,
        !is.na(journal_column) ~ journal_column,
        !is.na(publisher) ~ publisher,
        !is.na(author) ~ author,
        !is.na(title) ~ title))
  } else {
    df$input <- df[[input_column]]
  }

  pred <- model %>%
    predict(df$input) %>%
    data.table(.) %>%
    rename("class_journal" = "V1", "class_agency" = "V2",
           "class_conference" = "V4", "class_none" = "V3") %>%
    mutate(predict_class = case_when(
      class_journal > probability ~ "journal",
      class_agency > probability ~ "agency",
      class_none > probability ~ "delete",
      class_conference > probability ~ "conference",
      T ~ "unsure"))

  return(pred)
}
