#' Derives a Flag Based on an Existing Flag
#'
#' Derive a flag which depends on other observations of the dataset. For
#' example, flagging events which need to be confirmed by a second event.
#'
#' An example usage might be flagging if a patient received two required
#' medications within a certain timeframe of each other.
#'
#' In the oncology setting, for example, the function could be used to flag if a
#' response value can be confirmed by an other assessment. This is commonly
#' used in endpoints such as best overall response.
#'
#' @param dataset Input dataset
#'
#'   The variables specified by the `by_vars` and `join_vars` parameter are
#'   expected.
#'
#' @param by_vars By variables
#'
#'   The specified variables are used as by variables for joining the input
#'   dataset with itself.
#'
#' @param order Order
#'
#'   The observations are ordered by the specified order.
#'
#' @param new_var New variable
#'
#'   The specified variable is added to the input dataset.
#'
#' @param tmp_obs_nr_var Temporary observation number
#'
#'   The specified variable is added to the input dataset and set to the
#'   observation number with respect to `order`. For each by group (`by_vars`)
#'   the observation number starts with `1`. The variable can be used in the
#'   conditions (`filter`, `first_cond`). It is not included in the output
#'   dataset. It can be used to flag consecutive observations or the last
#'   observation (see last example below).
#'
#' @param join_vars Variables to keep from joined dataset
#'
#'   The variables needed from the other observations should be specified
#'   for this parameter. The specified variables are added to the joined dataset
#'   with suffix ".join". For example to flag all observations with `AVALC ==
#'   "Y"` and `AVALC == "Y"` for at least one subsequent visit `join_vars =
#'   exprs(AVALC, AVISITN)` and `filter = AVALC == "Y" & AVALC.join == "Y" &
#'   AVISITN < AVISITN.join` could be specified.
#'
#'   The `*.join` variables are not included in the output dataset.
#'
#' @param join_type Observations to keep after joining
#'
#'   The argument determines which of the joined observations are kept with
#'   respect to the original observation. For example, if `join_type = "after"`
#'   is specified all observations after the original observations are kept.
#'
#'   For example for confirmed response or BOR in the oncology setting or
#'   confirmed deterioration in questionnaires the confirmatory assessment must
#'   be after the assessment to be flagged. Thus `join_type = "after"` could be
#'   used.
#'
#'   Whereas, sometimes you might allow for confirmatory observations to occur
#'   prior to the observation to be flagged. For example, to flag AEs occurring
#'   on or after seven days before a COVID AE. Thus `join_type = "all"` could be
#'   used.
#'
#'   *Permitted Values:* `"before"`, `"after"`, `"all"`
#'
#' @param first_cond Condition for selecting range of data
#'
#'   If this argument is specified, the other observations are restricted up to
#'   the first observation where the specified condition is fulfilled. If the
#'   condition is not fulfilled for any of the other observations, no
#'   observations are considered, i.e., the observation is not flagged.
#'
#'   This parameter should be specified if `filter` contains summary functions
#'   which should not apply to all observations but only up to the confirmation
#'   assessment. For an example see the third example below.
#'
#' @param filter Condition for selecting observations
#'
#'   The filter is applied to the joined dataset for flagging the confirmed
#'   observations. The condition can include summary functions. The joined
#'   dataset is grouped by the original observations. I.e., the summary function
#'   are applied to all observations up to the confirmation observation. For
#'   example, `filter = AVALC == "CR" & all(AVALC.join %in% c("CR", "NE")) &
#'   count_vals(var = AVALC.join, val = "NE") <= 1` selects observations with
#'   response "CR" and for all observations up to the confirmation observation
#'   the response is "CR" or "NE" and there is at most one "NE".
#'
#' @param check_type Check uniqueness?
#'
#'   If `"warning"` or `"error"` is specified, the specified message is issued
#'   if the observations of the input dataset are not unique with respect to the
#'   by variables and the order.
#'
#'   *Default:* `"warning"`
#'
#'   *Permitted Values:* `"none"`, `"warning"`, `"error"`
#'
#' @param true_value Value of `new_var` for flagged observations
#'
#'   *Default*: `"Y"`
#'
#' @param false_value Value of `new_var` for observations not flagged
#'
#'   *Default*: `NA_character_`
#'
#' @details
#'   The following steps are performed to produce the output dataset.
#'
#'   ## Step 1
#'
#'   The input dataset is joined with itself by the variables specified for
#'   `by_vars`. From the right hand side of the join only the variables
#'   specified for `join_vars` are kept. The suffix ".join" is added to these
#'   variables.
#'
#'   For example, for `by_vars = USUBJID`, `join_vars = exprs(AVISITN, AVALC)` and input dataset
#'
#'   ```{r eval=FALSE}
#'   # A tibble: 2 x 4
#'   USUBJID AVISITN AVALC  AVAL
#'   <chr>     <dbl> <chr> <dbl>
#'   1             1 Y         1
#'   1             2 N         0
#'   ```
#'
#'   the joined dataset is
#'
#'   ```{r eval=FALSE}
#'   A tibble: 4 x 6
#'   USUBJID AVISITN AVALC  AVAL AVISITN.join AVALC.join
#'   <chr>     <dbl> <chr> <dbl>        <dbl> <chr>
#'   1             1 Y         1            1 Y
#'   1             1 Y         1            2 N
#'   1             2 N         0            1 Y
#'   1             2 N         0            2 N
#'   ```
#'
#'   ## Step 2
#'
#'   The joined dataset is restricted to observations with respect to
#'   `join_type` and `order`.
#'
#'   The dataset from the example in the previous step with `join_type =
#'   "after"` and `order = exprs(AVISITN)` is restricted to
#'
#'   ```{r eval=FALSE}
#'   A tibble: 4 x 6
#'   USUBJID AVISITN AVALC  AVAL AVISITN.join AVALC.join
#'   <chr>     <dbl> <chr> <dbl>        <dbl> <chr>
#'   1             1 Y         1            2 N
#'   ```
#'
#'   ## Step 3
#'
#'   If `first_cond` is specified, for each observation of the input dataset the
#'   joined dataset is restricted to observations up to the first observation
#'   where `first_cond` is fulfilled (the observation fulfilling the condition
#'   is included). If for an observation of the input dataset the condition is
#'   not fulfilled, the observation is removed.
#'
#'   ## Step 4
#'
#'   The joined dataset is grouped by the observations from the input dataset
#'   and restricted to the observations fulfilling the condition specified by
#'   `filter`.
#'
#'   ## Step 5
#'
#'   The first observation of each group is selected
#'
#'   ## Step 6
#'
#'   The variable specified by `new_var` is added to the input dataset. It is
#'   set to `true_value` for all observations which were selected in the
#'   previous step. For the other observations it is set to `false_value`.
#'
#' @return The input dataset with the variable specified by `new_var` added.
#'
#'
#' @keywords der_gen
#' @family der_gen
#'
#' @seealso [filter_joined()]
#'
#' @export
#'
#' @examples
#' library(tibble)
#' library(admiral)
#'
#' # flag observations with a duration longer than 30 and
#' # at, after, or up to 7 days before a COVID AE (ACOVFL == "Y")
#' adae <- tribble(
#'   ~USUBJID, ~ADY, ~ACOVFL, ~ADURN,
#'   "1",        10, "N",          1,
#'   "1",        21, "N",         50,
#'   "1",        23, "Y",         14,
#'   "1",        32, "N",         31,
#'   "1",        42, "N",         20,
#'   "2",        11, "Y",         13,
#'   "2",        23, "N",          2,
#'   "3",        13, "Y",         12,
#'   "4",        14, "N",         32,
#'   "4",        21, "N",         41
#' )
#'
#' derive_var_joined_exist_flag(
#'   adae,
#'   new_var = ALCOVFL,
#'   by_vars = exprs(USUBJID),
#'   join_vars = exprs(ACOVFL, ADY),
#'   join_type = "all",
#'   order = exprs(ADY),
#'   filter = ADURN > 30 & ACOVFL.join == "Y" & ADY >= ADY.join - 7
#' )
#'
#' # flag observations with AVALC == "Y" and AVALC == "Y" at one subsequent visit
#' data <- tribble(
#'   ~USUBJID, ~AVISITN, ~AVALC,
#'   "1",      1,        "Y",
#'   "1",      2,        "N",
#'   "1",      3,        "Y",
#'   "1",      4,        "N",
#'   "2",      1,        "Y",
#'   "2",      2,        "N",
#'   "3",      1,        "Y",
#'   "4",      1,        "N",
#'   "4",      2,        "N",
#' )
#'
#' derive_var_joined_exist_flag(
#'   data,
#'   by_vars = exprs(USUBJID),
#'   new_var = CONFFL,
#'   join_vars = exprs(AVALC, AVISITN),
#'   join_type = "after",
#'   order = exprs(AVISITN),
#'   filter = AVALC == "Y" & AVALC.join == "Y" & AVISITN < AVISITN.join
#' )
#'
#' # select observations with AVALC == "CR", AVALC == "CR" at a subsequent visit,
#' # only "CR" or "NE" in between, and at most one "NE" in between
#' data <- tribble(
#'   ~USUBJID, ~AVISITN, ~AVALC,
#'   "1",      1,        "PR",
#'   "1",      2,        "CR",
#'   "1",      3,        "NE",
#'   "1",      4,        "CR",
#'   "1",      5,        "NE",
#'   "2",      1,        "CR",
#'   "2",      2,        "PR",
#'   "2",      3,        "CR",
#'   "3",      1,        "CR",
#'   "4",      1,        "CR",
#'   "4",      2,        "NE",
#'   "4",      3,        "NE",
#'   "4",      4,        "CR",
#'   "4",      5,        "PR"
#' )
#'
#' derive_var_joined_exist_flag(
#'   data,
#'   by_vars = exprs(USUBJID),
#'   join_vars = exprs(AVALC),
#'   join_type = "after",
#'   order = exprs(AVISITN),
#'   new_var = CONFFL,
#'   first_cond = AVALC.join == "CR",
#'   filter = AVALC == "CR" & all(AVALC.join %in% c("CR", "NE")) &
#'     count_vals(var = AVALC.join, val = "NE") <= 1
#' )
#'
#' # flag observations with AVALC == "PR", AVALC == "CR" or AVALC == "PR"
#' # at a subsequent visit at least 20 days later, only "CR", "PR", or "NE"
#' # in between, at most one "NE" in between, and "CR" is not followed by "PR"
#' data <- tribble(
#'   ~USUBJID, ~ADY, ~AVALC,
#'   "1",         6, "PR",
#'   "1",        12, "CR",
#'   "1",        24, "NE",
#'   "1",        32, "CR",
#'   "1",        48, "PR",
#'   "2",         3, "PR",
#'   "2",        21, "CR",
#'   "2",        33, "PR",
#'   "3",        11, "PR",
#'   "4",         7, "PR",
#'   "4",        12, "NE",
#'   "4",        24, "NE",
#'   "4",        32, "PR",
#'   "4",        55, "PR"
#' )
#'
#' derive_var_joined_exist_flag(
#'   data,
#'   by_vars = exprs(USUBJID),
#'   join_vars = exprs(AVALC, ADY),
#'   join_type = "after",
#'   order = exprs(ADY),
#'   new_var = CONFFL,
#'   first_cond = AVALC.join %in% c("CR", "PR") & ADY.join - ADY >= 20,
#'   filter = AVALC == "PR" &
#'     all(AVALC.join %in% c("CR", "PR", "NE")) &
#'     count_vals(var = AVALC.join, val = "NE") <= 1 &
#'     (
#'       min_cond(var = ADY.join, cond = AVALC.join == "CR") >
#'         max_cond(var = ADY.join, cond = AVALC.join == "PR") |
#'         count_vals(var = AVALC.join, val = "CR") == 0
#'     )
#' )
#'
#' # flag observations with CRIT1FL == "Y" at two consecutive visits or at the last visit
#' data <- tribble(
#'   ~USUBJID, ~AVISITN, ~CRIT1FL,
#'   "1",      1,        "Y",
#'   "1",      2,        "N",
#'   "1",      3,        "Y",
#'   "1",      5,        "N",
#'   "2",      1,        "Y",
#'   "2",      3,        "Y",
#'   "2",      5,        "N",
#'   "3",      1,        "Y",
#'   "4",      1,        "Y",
#'   "4",      2,        "N",
#' )
#'
#' derive_var_joined_exist_flag(
#'   data,
#'   by_vars = exprs(USUBJID),
#'   new_var = CONFFL,
#'   tmp_obs_nr_var = tmp_obs_nr,
#'   join_vars = exprs(CRIT1FL),
#'   join_type = "all",
#'   order = exprs(AVISITN),
#'   filter = CRIT1FL == "Y" & CRIT1FL.join == "Y" &
#'     (tmp_obs_nr + 1 == tmp_obs_nr.join | tmp_obs_nr == max(tmp_obs_nr.join))
#' )
#'
derive_var_joined_exist_flag <- function(dataset,
                                         by_vars,
                                         order,
                                         new_var,
                                         tmp_obs_nr_var = NULL,
                                         join_vars,
                                         join_type,
                                         first_cond = NULL,
                                         filter,
                                         true_value = "Y",
                                         false_value = NA_character_,
                                         check_type = "warning") {
  new_var <- assert_symbol(enexpr(new_var))
  tmp_obs_nr_var <- assert_symbol(enexpr(tmp_obs_nr_var), optional = TRUE)
  first_cond <- assert_filter_cond(enexpr(first_cond), optional = TRUE)
  filter <- assert_filter_cond(enexpr(filter))
  assert_data_frame(dataset)

  tmp_obs_nr <- get_new_tmp_var(dataset, prefix = "tmp_obs_nr_")

  data <- derive_var_obs_number(
    dataset,
    new_var = !!tmp_obs_nr
  )

  data_filtered <- filter_joined(
    data,
    by_vars = by_vars,
    order = order,
    tmp_obs_nr_var = !!tmp_obs_nr_var,
    join_vars = join_vars,
    join_type = join_type,
    first_cond = !!first_cond,
    filter = !!filter,
    check_type = check_type
  )

  derive_var_merged_exist_flag(
    data,
    dataset_add = data_filtered,
    by_vars = exprs(!!tmp_obs_nr),
    new_var = !!new_var,
    condition = TRUE,
    true_value = true_value,
    false_value = false_value,
    missing_value = false_value
  ) %>%
    remove_tmp_vars()
}

#' Derive Confirmation Flag
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' This function is *deprecated*, please use `derive_var_joined_exist_flag()` instead.
#'
#' @param dataset Input dataset
#'
#'   The variables specified by the `by_vars` and `join_vars` parameter are
#'   expected.
#'
#' @param by_vars By variables
#'
#'   The specified variables are used as by variables for joining the input
#'   dataset with itself.
#'
#' @param order Order
#'
#'   The observations are ordered by the specified order.
#'
#' @param new_var New variable
#'
#'   The specified variable is added to the input dataset.
#'
#' @param tmp_obs_nr_var Temporary observation number
#'
#'   The specified variable is added to the input dataset and set to the
#'   observation number with respect to `order`. For each by group (`by_vars`)
#'   the observation number starts with `1`. The variable can be used in the
#'   conditions (`filter`, `first_cond`). It is not included in the output
#'   dataset. It can be used to flag consecutive observations or the last
#'   observation (see last example below).
#'
#' @param join_vars Variables to keep from joined dataset
#'
#'   The variables needed from the other observations should be specified
#'   for this parameter. The specified variables are added to the joined dataset
#'   with suffix ".join". For example to flag all observations with `AVALC ==
#'   "Y"` and `AVALC == "Y"` for at least one subsequent visit `join_vars =
#'   exprs(AVALC, AVISITN)` and `filter = AVALC == "Y" & AVALC.join == "Y" &
#'   AVISITN < AVISITN.join` could be specified.
#'
#'   The `*.join` variables are not included in the output dataset.
#'
#' @param join_type Observations to keep after joining
#'
#'   The argument determines which of the joined observations are kept with
#'   respect to the original observation. For example, if `join_type = "after"`
#'   is specified all observations after the original observations are kept.
#'
#'   For example for confirmed response or BOR in the oncology setting or
#'   confirmed deterioration in questionnaires the confirmatory assessment must
#'   be after the assessment to be flagged. Thus `join_type = "after"` could be
#'   used.
#'
#'   Whereas, sometimes you might allow for confirmatory observations to occur
#'   prior to the observation to be flagged. For example, to flag AEs occurring
#'   on or after seven days before a COVID AE. Thus `join_type = "all"` could be
#'   used.
#'
#'   *Permitted Values:* `"before"`, `"after"`, `"all"`
#'
#' @param first_cond Condition for selecting range of data
#'
#'   If this argument is specified, the other observations are restricted up to
#'   the first observation where the specified condition is fulfilled. If the
#'   condition is not fulfilled for any of the other observations, no
#'   observations are considered, i.e., the observation is not flagged.
#'
#'   This parameter should be specified if `filter` contains summary functions
#'   which should not apply to all observations but only up to the confirmation
#'   assessment. For an example see the third example below.
#'
#' @param filter Condition for selecting observations
#'
#'   The filter is applied to the joined dataset for flagging the confirmed
#'   observations. The condition can include summary functions. The joined
#'   dataset is grouped by the original observations. I.e., the summary function
#'   are applied to all observations up to the confirmation observation. For
#'   example, `filter = AVALC == "CR" & all(AVALC.join %in% c("CR", "NE")) &
#'   count_vals(var = AVALC.join, val = "NE") <= 1` selects observations with
#'   response "CR" and for all observations up to the confirmation observation
#'   the response is "CR" or "NE" and there is at most one "NE".
#'
#' @param check_type Check uniqueness?
#'
#'   If `"warning"` or `"error"` is specified, the specified message is issued
#'   if the observations of the input dataset are not unique with respect to the
#'   by variables and the order.
#'
#'   *Default:* `"warning"`
#'
#'   *Permitted Values:* `"none"`, `"warning"`, `"error"`
#'
#' @param true_value Value of `new_var` for flagged observations
#'
#'   *Default*: `"Y"`
#'
#' @param false_value Value of `new_var` for observations not flagged
#'
#'   *Default*: `NA_character_`
#'
#' @details
#'   The following steps are performed to produce the output dataset.
#'
#'   ## Step 1
#'
#'   The input dataset is joined with itself by the variables specified for
#'   `by_vars`. From the right hand side of the join only the variables
#'   specified for `join_vars` are kept. The suffix ".join" is added to these
#'   variables.
#'
#'   For example, for `by_vars = USUBJID`, `join_vars = exprs(AVISITN, AVALC)` and input dataset
#'
#'   ```{r eval=FALSE}
#'   # A tibble: 2 x 4
#'   USUBJID AVISITN AVALC  AVAL
#'   <chr>     <dbl> <chr> <dbl>
#'   1             1 Y         1
#'   1             2 N         0
#'   ```
#'
#'   the joined dataset is
#'
#'   ```{r eval=FALSE}
#'   A tibble: 4 x 6
#'   USUBJID AVISITN AVALC  AVAL AVISITN.join AVALC.join
#'   <chr>     <dbl> <chr> <dbl>        <dbl> <chr>
#'   1             1 Y         1            1 Y
#'   1             1 Y         1            2 N
#'   1             2 N         0            1 Y
#'   1             2 N         0            2 N
#'   ```
#'
#'   ## Step 2
#'
#'   The joined dataset is restricted to observations with respect to
#'   `join_type` and `order`.
#'
#'   The dataset from the example in the previous step with `join_type =
#'   "after"` and `order = exprs(AVISITN)` is restricted to
#'
#'   ```{r eval=FALSE}
#'   A tibble: 4 x 6
#'   USUBJID AVISITN AVALC  AVAL AVISITN.join AVALC.join
#'   <chr>     <dbl> <chr> <dbl>        <dbl> <chr>
#'   1             1 Y         1            2 N
#'   ```
#'
#'   ## Step 3
#'
#'   If `first_cond` is specified, for each observation of the input dataset the
#'   joined dataset is restricted to observations up to the first observation
#'   where `first_cond` is fulfilled (the observation fulfilling the condition
#'   is included). If for an observation of the input dataset the condition is
#'   not fulfilled, the observation is removed.
#'
#'   ## Step 4
#'
#'   The joined dataset is grouped by the observations from the input dataset
#'   and restricted to the observations fulfilling the condition specified by
#'   `filter`.
#'
#'   ## Step 5
#'
#'   The first observation of each group is selected
#'
#'   ## Step 6
#'
#'   The variable specified by `new_var` is added to the input dataset. It is
#'   set to `true_value` for all observations which were selected in the
#'   previous step. For the other observations it is set to `false_value`.
#'
#' @return The input dataset with the variable specified by `new_var` added.
#'
#'
#' @keywords deprecated
#' @family deprecated
#'
#' @export
#'
derive_var_confirmation_flag <- function(dataset,
                                         by_vars,
                                         order,
                                         new_var,
                                         tmp_obs_nr_var = NULL,
                                         join_vars,
                                         join_type,
                                         first_cond = NULL,
                                         filter,
                                         true_value = "Y",
                                         false_value = NA_character_,
                                         check_type = "warning") {
  deprecate_stop(
    "0.10.0",
    "derive_var_confirmation_flag()",
    details = "Please use `derive_var_joined_exist_flag()` instead."
  )
}
