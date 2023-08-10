# THIS FILE INCLUDES FUNCTION THAT ARE RE-USED THROUGHOUT
# roxygen2 COMMENTS TO GENERATE DOCUMENTATION TEXT

roxygen_param_by_var <- function(arg) {
  case_when(
    arg == 1 ~ "By Variables for Grouping",
    arg == 2 ~ "By Varialbes for Joining",
    arg == 3 ~ "Extraneous"
  )
}
