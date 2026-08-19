# Imperil or Protect - Experiment 4 - Gamma GLMM analysis
# Coded by A.Y.

### SETUP/PARAMETERS ----

library(R.matlab)
library(dplyr)
library(ggplot2)
library(emmeans)
library(stringr)
library(lme4)
library(lmerTest)
library(glmmTMB)
library(brms)
library(rlang)
library(cowplot)
library(grid)
library(showtext)
library(sysfonts)
library(car)
library(ggtext)

options(scipen = 999)  # Avoid scientific notation

base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4/"

files <- list.files(base_dir, pattern = "\\.mat$", full.names = TRUE)

dfs <- lapply(files, function(f) {
  mat <- R.matlab::readMat(f)
  as.data.frame(mat$outputMatrix)
})

combinedData <- bind_rows(dfs)
colnames(combinedData) <- c(
  "subject", "conditionUsed", "block", "trial", "repetition",
  "context", "contextCode", "primaryColor", "secondaryColor",
  "angle1", "initiation_time1", "movement_time1", "rt1",
  "angle2", "initiation_time2", "movement_time2", "rt2",
  "breakTaken", "conditions"
)

### PREPROCESSING ----

# Enter the analysis DV # "angle" or "rt"
dependent_variable    <- "angle1"

## Trial-level trimming
# Based on RT

lower <- 0.3

if (dependent_variable == "angle1" || dependent_variable == "rt1") {
  combinedData_firstpass <- combinedData %>%
    dplyr::filter(!is.na(rt1), rt1 > lower, !is.na(angle1), angle1 != 0)
} else if (dependent_variable == "angle2" || dependent_variable == "rt2") {
  combinedData_firstpass <- combinedData %>%
    dplyr::filter(!is.na(rt2), rt2 > lower, !is.na(angle2), angle2 != 0)
}

## Subject-level trimming
# Based on global angular error (at Test 1 specifically)

bad_subjects <- combinedData_firstpass %>%
  # Determine outlier subjects
  dplyr::group_by(subject) %>%
  dplyr::summarise(global_angle = mean(abs(angle1), na.rm = TRUE), .groups = "drop") %>%
  dplyr::filter(global_angle > 45)

message("Excluded subjects (mean abs circular error > 45 deg):")
print(bad_subjects)

combinedData_secondpass <- combinedData_firstpass %>%
  dplyr::mutate(subject = factor(subject)) %>%
  dplyr::filter(!(subject %in% bad_subjects$subject))

# Base preprocessing
combinedData_sub <- combinedData_secondpass %>%
  dplyr::mutate(
    outcome = abs(.data[[dependent_variable]]),
    repetition_num   = as.numeric(as.character(repetition)),
    context_num      = as.numeric(as.character(context)),
  )

# Full 1-6 repetition dataset (collapsed). Interference is only manipulated at the
# test reps 1 & 5, so it is NOT added here; see the baseline construction below.
combinedData_sub_rep <- combinedData_sub %>%
  dplyr::filter(repetition_num %in% 1:6) %>%
  dplyr::mutate(
    repetition = factor(repetition_num, levels = 1:6,
                        labels = c("1", "2", "3", "4", "5", "6")),
    subject = factor(subject)
  )

# Repetition 1 and 5 dataset with context and interference
combinedData_sub_full <- combinedData_sub %>%
  dplyr::filter(
    repetition_num   %in% c(1, 5),
    context_num      %in% c(0, 1)
  ) %>%
  dplyr::mutate(
    repetition   = factor(repetition_num, levels = c(1, 5), labels = c("1", "5")),
    context      = factor(context_num, levels = c(0, 1),
                          labels = c("No Change", "Change")),
    subject = factor(subject)
  )

combinedData_gamma_rep  <- combinedData_sub_rep  %>% dplyr::filter(is.finite(outcome), outcome > 0)
combinedData_gamma_full <- combinedData_sub_full %>% dplyr::filter(is.finite(outcome), outcome > 0)


desc_stats_subject <- combinedData_gamma_full %>%
  dplyr::group_by(subject, repetition, context) %>%
  dplyr::summarise(subj_mean = mean(outcome, na.rm = TRUE), .groups = "drop") %>%
  dplyr::group_by(repetition, context) %>%
  dplyr::summarise(
    M      = mean(subj_mean),
    SD     = sd(subj_mean),          # between-subject SD — much smaller
    SEM    = SD / sqrt(dplyr::n()),
    n_subj = dplyr::n(),
    .groups = "drop"
  )


### MODELS
glmm_mod_rep <- glmmTMB(
  outcome ~ repetition + (1 | subject),
  data = combinedData_gamma_rep,
  family = Gamma(link = "log")
)

glmm_mod_full <- glmmTMB(
  outcome ~ repetition * context + (1 | subject),
  data = combinedData_gamma_full,
  family = Gamma(link="log")
)
summary(glmm_mod_full)
car::Anova(glmm_mod_full, type = "II")   # omnibus χ² per factor + interaction  ← the test you report
rep_emm <- emmeans(glmm_mod_full, ~  context | repetition, type = "response")   # marginal means + ratio  ← the estimate you report
rep_contrast <- contrast(rep_emm, method = "pairwise", infer= TRUE)
print(rep_contrast)














### EMMs ----

# 1) Repetition-only EMMs across all 6 repetitions
emm_rep <- emmeans(glmm_mod_rep, ~ repetition, type = "response")
rep_df <- as.data.frame(emm_rep)

# 2) Context EMMs only at reps 1 and 5
emm_ctx <- emmeans(glmm_mod_full, ~ context | repetition, type = "response")
ctx_df <- as.data.frame(emm_ctx)







# Make sure repetition is ordered correctly
rep_df$repetition <- factor(rep_df$repetition, levels = c("1", "2", "3", "4", "5", "6"))
ctx_df$repetition <- factor(ctx_df$repetition, levels = c("1", "2", "3", "4", "5", "6"))

# Inspect tables
print(rep_df)
print(ctx_df)

# Plot aesthetics 

legend_yes <- FALSE
if (legend_yes) {
  legend_pos = "right"
  legend_text_size = 20
  gg_title_pos = 0.6
} else {
  legend_pos = "none"
  legend_text_size = 20
  if (dependent_variable == "angle1") {
    gg_title_pos = 0.4
  } else if (dependent_variable == "angle2") {
    gg_title_pos = 0.5
  }
}

if (dependent_variable == "angle1") {
  # y axis settings:
  step_size <- c(1)
  y_range <- c(0.125, 0.2)
  # Plot title 
  ggtitle <- "Novel Item (Test 1)"
  y_label <- "Angular Error (°)"
} else if (dependent_variable == "angle2") {
  # y axis settings:
  step_size <- c(2)
  y_range <- c(0.125, 0.2)
  # Plot title 
  ggtitle <- "Repeated Item (Test 2)"
  y_label <- NULL
} else if (dependent_variable == "rt1") {
  # y axis settings:
  step_size <- c(0.25) * 100 # convert to ms
  y_range <- c(0.125, 0.3)
  # Plot title 
  ggtitle <- "Novel Item (Test 1)"
  y_label <- NULL
} else if (dependent_variable == "rt2") {
  # y axis settings:
  step_size <- c(0.5) * 100 # convert to ms
  y_range <- c(0.125, 0.2)
  y_label <- "Reaction Time (ms)"
  # Plot title 
  ggtitle <- "Repeated Item (Test 2)"
}

scale_factor <- ifelse(dependent_variable %in% c("rt1", "rt2"), 1000, 1)

font_add(
  family     = "Arial",
  regular    = "/System/Library/Fonts/Supplemental/Arial.ttf",
  bold       = "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
  italic     = "/System/Library/Fonts/Supplemental/Arial Italic.ttf",
  bolditalic = "/System/Library/Fonts/Supplemental/Arial Bold Italic.ttf"
)
showtext_auto()
showtext_opts(dpi = 300)



### WITHIN-SUBJECT HYBRID PLOT

library(Rmisc)

x_levels <- c("1", "2", "3", "4", "5", "6")

# 1) Repetition-only part: reps 1–6 collapsed across context
ws_df_rep <- combinedData_sub_rep %>%
  dplyr::group_by(subject, repetition) %>%
  dplyr::summarise(
    mean_error = mean(outcome * scale_factor, na.rm = TRUE),
    .groups = "drop"
  )

ws_summary_rep <- Rmisc::summarySEwithin(
  data = ws_df_rep,
  measurevar = "mean_error",
  withinvars = "repetition",
  idvar = "subject",
  conf.interval = 0.95
)

ws_summary_rep <- ws_summary_rep %>%
  dplyr::mutate(repetition = factor(repetition, levels = x_levels))

# 2) Context part: reps 1 and 5 only
ws_df_ctx <- combinedData_sub_full %>%
  dplyr::group_by(subject, repetition, context) %>%
  dplyr::summarise(
    mean_error = mean(outcome * scale_factor, na.rm = TRUE),
    .groups = "drop"
  )

ws_summary_ctx <- Rmisc::summarySEwithin(
  data = ws_df_ctx,
  measurevar = "mean_error",
  withinvars = c("repetition", "context"),
  idvar = "subject",
  conf.interval = 0.95
)

ws_summary_ctx <- ws_summary_ctx %>%
  dplyr::mutate(repetition = factor(repetition, levels = x_levels))

# 3) To avoid overplotting reps 1 and 5 twice
ws_summary_rep_for_points <- ws_summary_rep %>%
  dplyr::filter(!repetition %in% c("1", "5"))

# add a numeric x so the ribbon/line can span the discrete axis
ws_summary_rep <- ws_summary_rep %>%
  dplyr::mutate(
    repetition = factor(repetition, levels = x_levels),
    rep_x      = as.numeric(repetition)   # 1..6, matches scale_x_discrete positions
  )

# one shared dodge object so points and error bars line up
pd <- position_dodge(width = 0.65)

get_y_extent <- function(dv) {
  sf <- ifelse(dv %in% c("rt1", "rt2"), 1000, 1)
  
  base <- combinedData_sub %>%
    dplyr::mutate(
      raw_outcome    = as.numeric(as.character(.data[[dv]])),
      outcome        = if (dv %in% c("rt1","rt2")) raw_outcome
      else abs((((raw_outcome + 180) %% 360) - 180)),
      repetition_num = as.numeric(as.character(repetition)),
      context_num    = as.numeric(as.character(context))
    ) %>%
    dplyr::filter(is.finite(outcome), is.finite(rt1), rt1 >= 0.3)
  
  rep_df <- base %>%
    dplyr::filter(repetition_num %in% 1:6) %>%
    dplyr::mutate(repetition = factor(repetition_num, levels = 1:6),
                  subject = factor(subject)) %>%
    dplyr::group_by(subject, repetition) %>%
    dplyr::summarise(mean_error = mean(outcome * sf, na.rm = TRUE), .groups = "drop")
  
  ctx_df <- base %>%
    dplyr::filter(repetition_num %in% c(1, 5), context_num %in% c(0, 1)) %>%
    dplyr::mutate(repetition = factor(repetition_num, levels = c(1, 5)),
                  context = factor(context_num, levels = c(0, 1),
                                   labels = c("No Change", "Change")),
                  subject = factor(subject)) %>%
    dplyr::group_by(subject, repetition, context) %>%
    dplyr::summarise(mean_error = mean(outcome * sf, na.rm = TRUE), .groups = "drop")
  
  s_rep <- Rmisc::summarySEwithin(rep_df, "mean_error", withinvars = "repetition",
                                  idvar = "subject", conf.interval = 0.95)
  s_ctx <- Rmisc::summarySEwithin(ctx_df, "mean_error", withinvars = c("repetition", "context"),
                                  idvar = "subject", conf.interval = 0.95)
  
  range(c(s_rep$mean_error + c(-1, 1) * s_rep$ci,
          s_ctx$mean_error + c(-1, 1) * s_ctx$ci))
}

ext1 <- get_y_extent("rt1") - 125
ext2 <- get_y_extent("rt2") + 25
shared_y_range <- c(floor(min(ext1, ext2)), ceiling(max(ext1, ext2)))

ws_hybrid_plot <- ggplot() +
  # --- repetition-only baseline band + line (behind everything) ---
  geom_ribbon(
    data = ws_summary_rep,
    aes(x = rep_x, ymin = mean_error - ci, ymax = mean_error + ci),
    fill = "grey50", alpha = 0.15,
    inherit.aes = FALSE
  ) +
  geom_line(
    data = ws_summary_rep,
    aes(x = rep_x, y = mean_error),
    color = "grey40", linewidth = 1,
    inherit.aes = FALSE
  ) +
  # --- black dots: ALL 6 reps now (centered), so 1 & 5 get a marker ---
  geom_point(
    data = ws_summary_rep_for_points,
    aes(x = repetition, y = mean_error, color = "Repetition only"),  # literal string
    size = 4
  ) +
  # --- black error bars: still only 2,3,4,6 (band carries the CI at 1 & 5) ---
  geom_errorbar(
    data = ws_summary_rep_for_points,
    aes(x = repetition, ymin = mean_error - ci, ymax = mean_error + ci),
    width = 0.2, linewidth = 1.0, color = "black"
  ) +
  # --- context points at 1 & 5, dodged around the black dot ---
  geom_point(
    data = ws_summary_ctx,
    aes(x = repetition, y = mean_error, color = context),
    size = 4, position = pd
  ) +
  geom_errorbar(
    data = ws_summary_ctx,
    aes(x = repetition, ymin = mean_error - ci, ymax = mean_error + ci, color = context),
    width = 0.4, linewidth = 1.0, position = pd
  ) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    breaks = scales::breaks_width(50),
    expand = expansion(mult = c(0.02, 0.02))
  ) +
  coord_cartesian(ylim = shared_y_range) +
  scale_color_manual(
    values = c(
      "No Change"       = "orange",
      "Change"          = "steelblue",
      "Repetition only" = "black"
    ),
    breaks = c("No Change", "Change", "Repetition only")  # reorder however you like
  ) +
  labs(x = "Repetition", y = y_label, color = "Context") +
  ggtitle(ggtitle) +
  theme_classic() +
  theme(
    plot.title   = element_text(hjust = 0.5, face = "bold", size = 26),
    legend.title = element_blank(),
    plot.margin  = margin(5, 5, 5, 5),
    legend.text  = element_text(size = legend_text_size),
    legend.position = legend_pos,
    plot.background  = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    axis.title.x = element_text(face = "bold", size = 24, margin = margin(t = 4)),
    axis.title.y = element_markdown(face = "bold", size = 24, margin = margin(r = 12)),
    axis.text.x  = element_text(size = 18, margin = margin(t = 8), color = "black"),
    axis.text.y  = element_text(size = 18, margin = margin(r = 8), color = "black"),
    axis.ticks.length = unit(0.3, "cm"),
    text = element_text(family = "Arial")
  )



library(dplyr)
library(ggplot2)
library(Rmisc)
library(cowplot)
library(scales)

## ---- 0) Choose what to plot --------------------------------
# "time"  -> rt1   (Test 1) + rt2    (Test 2)
# "error" -> angle1(Test 1) + angle2 (Test 2)
domain <- "error"

dv_test1 <- if (domain == "time") "rt1" else "angle1"
dv_test2 <- if (domain == "time") "rt2" else "angle2"

# y-axis tick spacing in the *scaled* data units (ms for time, ° for error)
y_break_width <- if (domain == "time") 50 else 2

## ---- 1) DV-independent subject exclusion (run once) --------
bad_subjects <- combinedData %>%
  dplyr::mutate(
    subject    = factor(subject),
    angle1_num = as.numeric(as.character(angle1)),
    angle1_abs = abs(((angle1_num + 180) %% 360) - 180)
  ) %>%
  dplyr::filter(is.finite(angle1_abs), is.finite(rt1), rt1 >= 0.3) %>%
  dplyr::group_by(subject) %>%
  dplyr::summarise(mean_abs_angle1 = mean(angle1_abs, na.rm = TRUE), .groups = "drop") %>%
  dplyr::filter(mean_abs_angle1 > 45)

combinedData_sub <- combinedData %>%
  dplyr::mutate(subject = factor(subject)) %>%
  dplyr::filter(!(subject %in% bad_subjects$subject))

## ---- 2) Within-subject summaries for one DV ----------------
get_ws_summaries <- function(dv) {
  sf       <- ifelse(dv %in% c("rt1", "rt2"), 1000, 1)
  x_levels <- c("1", "2", "3", "4", "5", "6")
  
  base <- combinedData_sub %>%
    dplyr::mutate(
      raw_outcome    = as.numeric(as.character(.data[[dv]])),
      outcome        = if (dv %in% c("rt1", "rt2")) raw_outcome
      else abs((((raw_outcome + 180) %% 360) - 180)),
      repetition_num = as.numeric(as.character(repetition)),
      context_num    = as.numeric(as.character(context))
    ) %>%
    dplyr::filter(is.finite(outcome), is.finite(rt1), rt1 >= 0.3)
  
  rep_df <- base %>%
    dplyr::filter(repetition_num %in% 1:6) %>%
    dplyr::mutate(repetition = factor(repetition_num, levels = 1:6),
                  subject = factor(subject)) %>%
    dplyr::group_by(subject, repetition) %>%
    dplyr::summarise(mean_error = mean(outcome * sf, na.rm = TRUE), .groups = "drop")
  
  ctx_df <- base %>%
    dplyr::filter(repetition_num %in% c(1, 5), context_num %in% c(0, 1)) %>%
    dplyr::mutate(repetition = factor(repetition_num, levels = c(1, 5)),
                  context = factor(context_num, levels = c(0, 1),
                                   labels = c("No Change", "Change")),
                  subject = factor(subject)) %>%
    dplyr::group_by(subject, repetition, context) %>%
    dplyr::summarise(mean_error = mean(outcome * sf, na.rm = TRUE), .groups = "drop")
  
  s_rep <- Rmisc::summarySEwithin(rep_df, "mean_error", withinvars = "repetition",
                                  idvar = "subject", conf.interval = 0.95) %>%
    dplyr::mutate(repetition = factor(repetition, levels = x_levels),
                  rep_x = as.numeric(repetition))
  
  s_ctx <- Rmisc::summarySEwithin(ctx_df, "mean_error", withinvars = c("repetition", "context"),
                                  idvar = "subject", conf.interval = 0.95) %>%
    dplyr::mutate(repetition = factor(repetition, levels = x_levels))
  
  list(rep = s_rep, ctx = s_ctx)
}

## ---- 3) Independent y-range for EACH test ------------------
if (domain == "time") {
  ext_of <- function(s) range(c(s$rep$mean_error + c(-1, 1) * s$rep$ci,
                                s$ctx$mean_error + c(-1, 1) * s$ctx$ci))
  
  ws1 <- get_ws_summaries(dv_test1)
  ws2 <- get_ws_summaries(dv_test2)
  
  # pad a single panel's data extent into a tick-friendly range
  make_y_range <- function(s) {
    raw_range <- ext_of(s)
    pad       <- diff(raw_range) * 0.08
    # snap outward to the tick grid so the end ticks are visible
    c(floor((raw_range[1] - pad) / y_break_width) * y_break_width,
      ceiling((raw_range[2] + pad) / y_break_width) * y_break_width)
  }
  y_range1 <- make_y_range(ws1)   # Test 1 (novel)
  y_range2 <- make_y_range(ws2)   # Test 2 (repeated)
  
  ## Manual y-range override per panel (NULL = use the auto-computed range).
  ## Give values in scaled units (ms for time, ° for error).
  y_range_override <- list(
    test1 = c(2000, 2200),          # e.g. c(150, 350) for the novel panel
    test2 = NULL           # e.g. c(100, 250) for the repeated panel
  )
  
  if (!is.null(y_range_override$test1)) y_range1 <- y_range_override$test1
  if (!is.null(y_range_override$test2)) y_range2 <- y_range_override$test2
} else if (domain == "error") {
  ext_of <- function(s) range(c(s$rep$mean_error + c(-1, 1) * s$rep$ci,
                                s$ctx$mean_error + c(-1, 1) * s$ctx$ci))
  
  ws1 <- get_ws_summaries(dv_test1)
  ws2 <- get_ws_summaries(dv_test2)
  
  # pad a single panel's data extent into a tick-friendly range
  make_y_range <- function(s) {
    raw_range <- ext_of(s)
    pad       <- diff(raw_range) * 0.08
    # snap outward to the tick grid so the end ticks are visible
    c(floor((raw_range[1] - pad) / y_break_width) * y_break_width,
      ceiling((raw_range[2] + pad) / y_break_width) * y_break_width)
  }
  y_range1 <- make_y_range(ws1)   # Test 1 (novel)
  y_range2 <- make_y_range(ws2)   # Test 2 (repeated)
  
  ## Manual y-range override per panel (NULL = use the auto-computed range).
  ## Give values in scaled units (ms for time, ° for error).
  y_range_override <- list(
    test1 = c(14, 34),          # e.g. c(150, 350) for the novel panel
    test2 = c(14, 34)           # e.g. c(100, 250) for the repeated panel
  )
  
  if (!is.null(y_range_override$test1)) y_range1 <- y_range_override$test1
  if (!is.null(y_range_override$test2)) y_range2 <- y_range_override$test2
}
  

## ---- 4) Single-panel builder -------------------------------
build_hybrid_plot <- function(dv, ws, show_y_axis, y_range, show_y_title = TRUE) {
  x_levels <- c("1", "2", "3", "4", "5", "6")
  pd       <- position_dodge(width = 0.65)
  
  ggtitle_txt <- if (dv %in% c("rt1", "angle1")) "Novel Item"
  else "Repeated Item"
  y_label <- if (!show_y_axis) NULL
  else if (dv %in% c("rt1", "rt2")) "Reaction Time (ms)"
  else "Angular Error (\u00B0)"
  
  s_rep        <- ws$rep
  s_ctx        <- ws$ctx
  s_rep_points <- s_rep %>% dplyr::filter(!repetition %in% c("1", "5"))
  
  y_breaks <- seq(
    floor(y_range[1] / y_break_width) * y_break_width,
    ceiling(y_range[2] / y_break_width) * y_break_width,
    by = y_break_width
  )
  
  p <- ggplot() +
    geom_ribbon(data = s_rep,
                aes(x = rep_x, ymin = mean_error - ci, ymax = mean_error + ci),
                fill = "grey50", alpha = 0.15, inherit.aes = FALSE) +
    geom_line(data = s_rep, aes(x = rep_x, y = mean_error),
              color = "grey40", linewidth = 1, inherit.aes = FALSE) +
    geom_point(data = s_rep_points,
               aes(x = repetition, y = mean_error, color = "Repetition only"), size = 4) +
    geom_errorbar(data = s_rep_points,
                  aes(x = repetition, ymin = mean_error - ci, ymax = mean_error + ci),
                  width = 0.2, linewidth = 1.0, color = "black") +
    geom_point(data = s_ctx,
               aes(x = repetition, y = mean_error, color = context),
               size = 4, position = pd) +
    geom_errorbar(data = s_ctx,
                  aes(x = repetition, ymin = mean_error - ci, ymax = mean_error + ci, color = context),
                  width = 0.4, linewidth = 1.0, position = pd) +
    scale_x_discrete(limits = x_levels) +
    scale_y_continuous(breaks = y_breaks,
                       expand = expansion(mult = c(0.02, 0.02))) +
    coord_cartesian(ylim = y_range) +
    scale_color_manual(
      values = c("No Change" = "orange", "Change" = "steelblue", "Repetition only" = "black"),
      breaks = c("No Change", "Change", "Repetition only")
    ) +
    labs(x = NULL, y = y_label, color = NULL) +
    ggtitle(ggtitle_txt) +
    theme_classic() +
    theme(
      plot.title       = element_text(hjust = 0.5, face = "bold", size = 26),
      legend.position  = if (domain == "time") "none" else "none",
      plot.margin      = margin(5, 5, 5, 5),
      plot.background  = element_rect(fill = "white", color = NA),
      panel.background = element_rect(fill = "white", color = NA),
      axis.title.y     = element_markdown(face = "bold", size = 24, margin = margin(r = 18)),
      axis.text.x      = element_text(size = 18, margin = margin(t = 8), color = "black"),
      axis.text.y      = element_text(size = 18, margin = margin(r = 8), color = "black"),
      axis.ticks.length = unit(0.3, "cm"),
      text = element_text(family = "Arial")
    ) + guides(
      color = guide_legend(
        override.aes = list(
          linetype = 0,
          shape    = 16,
          size     = 4
        )
      )
    )
  
  # Right panel: drop the whole y-axis so the two share one axis
  if (!show_y_axis) {
    p <- p + theme(axis.title.y = element_blank(),
                   axis.text.y  = element_blank(),
                   axis.ticks.y = element_blank(),
                   axis.line.y  = element_blank())
  }
  if (!show_y_title) {
    p <- p + theme(axis.title.y = element_blank())
  }
  p
}
  
p1 <- build_hybrid_plot(dv_test1, ws1, show_y_axis = FALSE, y_range = y_range1, show_y_title = FALSE)   # left  (Test 1)
p2 <- build_hybrid_plot(dv_test2, ws2, show_y_axis = TRUE, y_range = y_range2, show_y_title = TRUE)  # right (Test 2)
## ---- 5) Merge: side by side, one y-axis, one x-label, ONE legend ----

# legend_shared <- if (domain == "time") {
#   cowplot::get_legend(
#     p1 + theme(
#       legend.position      = "none",
#       legend.title         = element_blank(),
#       legend.text          = element_text(size = 18, margin = margin(r = 14, l = 4)),
#       legend.key.width     = unit(1.0, "cm"),
#       legend.key.spacing.x = unit(0.1, "cm")
#     )
#   )
# } else NULL
# Remove legends from both panels so they hold only the plotting area
p1_nl <- p1 + theme(legend.position = "none")
p2_nl <- p2 + theme(legend.position = "none")

prow <- cowplot::plot_grid(
  p2_nl, p1_nl,
  nrow = 1, align = "h", axis = "tb",
  rel_widths = c(1, 1)
)

  # Panels + centred "Repetition" label directly beneath them
  panels_with_xlab <- cowplot::ggdraw() +
    cowplot::draw_plot(prow, x = 0, y = 0.045, width = 1, height = 0.955) +
    cowplot::draw_label(
      if (domain == "time") "Repetition" else "",
      x = 0.5, y = 0.000, vjust = 0,
      fontface = "bold", fontfamily = "Arial", size = 24
    )

combined_plot <- if (domain == "time") {
  cowplot::ggdraw() +
    cowplot::draw_plot(panels_with_xlab, x = 0, y = 0.08, width = 1, height = 0.9) +
    # cowplot::draw_plot(
    #   legend_shared,
    #   x = 0.05,          # <- SLIDE: increase = right, decrease/negative = left
    #   y = 0,
    #   width = 1,
    #   height = 0.09
    # ) +
    theme(plot.background = element_rect(fill = "white", color = NA))
} else {
  panels_with_xlab +
    theme(plot.background = element_rect(fill = "white", color = NA))
}

if (domain == "error") {
  combined_plot_error <- combined_plot
} else if (domain == "time") {
  combined_plot_time <- combined_plot
}


## ---- 6) Save -----------------------------------------------
out_name <- if (domain == "time") "exp4_time_beh.png" else "exp4_error_beh.png"
ggsave(
  filename = out_name,
  path     = "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/figures",
  plot     = combined_plot,
  width    = 14, height = 7, units = "in", dpi = 300
)
