library(R.matlab)
library(dplyr)
library(tidyr)
library(ggplot2)
library(emmeans)
library(lmerTest) 
options(scipen = 999)  # Avoid scientific notation

exp_handle <- 2
### LOAD DATA
raw_data <- sprintf("/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment%d_surprise.mat", exp_handle)
raw_data_read <- readMat(raw_data)

# Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment2.surprise
raw_data_data_frame <- as.data.frame(raw_data_matrix)

if (exp_handle == 1) {
  colnames(raw_data_data_frame) <- c(
    "subject", "trial", "context", "context_type", "interference",
    "binary_acc", "angle", "rt", "waitRT", "decisionTime")
} else if (exp_handle == 2) {
  # Assign column names
  colnames(raw_data_data_frame) <- c(
    "subject", "trial", "context", "interference", "interference_type",
    "binary_acc", "angle", "rt", "waitRT", "decisionTime")
}


### CHOOSE DV TO ANALYZE
combinedData <- raw_data_data_frame
dv <- "angle"

### PREPROCESSING
combinedData$raw_outcome <- combinedData[[dv]]

combinedData_sub <- combinedData %>%
  dplyr::mutate(
    raw_outcome = as.numeric(as.character(raw_outcome)),
    rt = as.numeric(as.character(rt)),
    outcome = if (dv %in% c("rt", "waitRT", "decisionTime", "binary_acc")) {
      raw_outcome
    } else {
      abs(((raw_outcome + 180) %% 360) - 180)
    },
    
    subject = factor(subject),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change")),
    interference = factor(interference, levels = c(0, 1), labels = c("No Interference", "Interference"))
  ) %>%
  dplyr::filter(
    is.finite(outcome),
    is.finite(rt),
    rt >= 0.3,
    context %in% c("No Change", "Change"),
    interference %in% c("No Interference", "Interference")
  )


### ANALYSIS

# Subject-level condition means
# This makes each subject x condition cell contribute equally,
# instead of giving more weight to conditions with more trials.
subject_means <- combinedData_sub %>%
  dplyr::group_by(subject, context, interference) %>%
  dplyr::summarise(
    outcome_mean = mean(outcome, na.rm = TRUE),
    n_trials = dplyr::n(),
    .groups = "drop"
  )

# Optional: check trial count imbalance at subject level
trial_count_summary <- subject_means %>%
  dplyr::group_by(context, interference) %>%
  dplyr::summarise(
    mean_trials = mean(n_trials),
    min_trials = min(n_trials),
    max_trials = max(n_trials),
    .groups = "drop"
  )

print(trial_count_summary)

### DESCRIPTIVE STATISTICS

# Trial counts per condition, from trial-level data
trial_counts <- combinedData_sub %>%
  dplyr::group_by(context, interference) %>%
  dplyr::summarise(
    n_trials = dplyr::n(),
    n_subjects_raw = dplyr::n_distinct(subject),
    .groups = "drop"
  )

if (dv == "binary_acc") {
  
  # First calculate accuracy separately for each subject in each condition
  subject_descriptives <- combinedData_sub %>%
    dplyr::group_by(subject, context, interference) %>%
    dplyr::summarise(
      acc = mean(outcome, na.rm = TRUE),
      n_trials_subject = dplyr::n(),
      .groups = "drop"
    )
  
  # Then summarize across subjects
  descriptives <- subject_descriptives %>%
    dplyr::group_by(context, interference) %>%
    dplyr::summarise(
      mean_acc = mean(acc, na.rm = TRUE) * 100,
      sd_acc = sd(acc, na.rm = TRUE) * 100,
      n_subjects = dplyr::n(),
      se_acc = sd(acc, na.rm = TRUE) / sqrt(n_subjects) * 100,
      mean_trials_per_subject = mean(n_trials_subject, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::left_join(trial_counts, by = c("context", "interference"))
  
  descriptives_display <- descriptives %>%
    dplyr::select(
      context,
      interference,
      mean_acc,
      sd_acc,
      se_acc,
      n_subjects,
      n_trials,
      mean_trials_per_subject
    ) %>%
    dplyr::mutate(
      mean_acc = sprintf("%.1f", mean_acc),
      sd_acc = sprintf("%.1f", sd_acc),
      se_acc = sprintf("%.1f", se_acc),
      mean_trials_per_subject = sprintf("%.1f", mean_trials_per_subject)
    )
  
} else {
  
  # For continuous outcomes, summarize participant-level condition means
  subject_descriptives <- combinedData_sub %>%
    dplyr::group_by(subject, context, interference) %>%
    dplyr::summarise(
      outcome_mean = mean(outcome, na.rm = TRUE),
      n_trials_subject = dplyr::n(),
      .groups = "drop"
    )
  
  descriptives <- subject_descriptives %>%
    dplyr::group_by(context, interference) %>%
    dplyr::summarise(
      AVG = mean(outcome_mean, na.rm = TRUE),
      SD = sd(outcome_mean, na.rm = TRUE),
      n_subjects = dplyr::n(),
      SE = SD / sqrt(n_subjects),
      mean_trials_per_subject = mean(n_trials_subject, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::left_join(trial_counts, by = c("context", "interference"))
  
  descriptives_display <- descriptives %>%
    dplyr::select(
      context,
      interference,
      AVG,
      SD,
      SE,
      n_subjects,
      n_trials,
      mean_trials_per_subject
    ) %>%
    dplyr::mutate(
      AVG = sprintf("%.3f", AVG),
      SD = sprintf("%.3f", SD),
      SE = sprintf("%.3f", SE),
      mean_trials_per_subject = sprintf("%.1f", mean_trials_per_subject)
    )
}
print(descriptives_display)

if (dv == "binary_acc") {
  
  mod_acc <- lme4::glmer(
    binary_acc ~ context * interference + (1 | subject),
    data   = combinedData_sub,
    family = binomial(link = "logit")
  )
  car::Anova(mod_acc, type = 2)  
  
} else {
  
  # LME
  formula <- as.formula("outcome ~ context * interference + (1 | subject)")
  
  lme_test <- lmerTest::lmer(formula, data = combinedData_sub)
  
  omnibus_test <- car::Anova(lme_test, type = 2, test.statistic = "F")
  print(omnibus_test)
  
}












# =========================================================================
# SURPRISE ANOVA (2 IVs: context x interference)  ->  TCC plot style
#
# There's no repetition axis here, so the hybrid structure collapses to:
#   colored context points + within-subject CIs, facetted by interference.
# Theme, palette (orange = No Change, steelblue = Change), and the
# within-subject Cousineau-Morey CIs (Rmisc::summarySEwithin) are identical
# to the TCC / mixture figures.
#
# Works for whatever `dv` you set upstream (binary_acc, angle, rt, ...),
# using the `outcome` column already built in combinedData_sub.
# =========================================================================

library(dplyr)
library(ggplot2)
library(Rmisc)
library(scales)

# ---- DV-specific display config -----------------------------------------
# scale: multiplier applied to the plotted value (e.g. 100 -> % for accuracy)
# step:  y-axis tick spacing ; yround: y-limit rounding unit
dv_cfg <- switch(
  dv,
  binary_acc   = list(label = "Accuracy (%)",           scale = 100, step = 5,   yround = 5),
  angle        = list(label = "Angular Error (\u00B0)", scale = 1,   step = 5,  yround = 10),
  rt           = list(label = "Reaction Time (ms)",      scale = 1,   step = 0.2, yround = 0.2),
  waitRT       = list(label = "Wait RT (s)",            scale = 1,   step = 0.2, yround = 0.2),
  decisionTime = list(label = "Decision Time (s)",      scale = 1,   step = 0.2, yround = 0.2),
  list(label = dv, scale = 1, step = NULL, yround = 1)   # fallback
)

# ---- within-subject summary (Cousineau-Morey CIs) -----------------------
ws_df <- combinedData_sub %>%
  dplyr::group_by(subject, context, interference) %>%
  dplyr::summarise(mean_val = mean(outcome, na.rm = TRUE), .groups = "drop")

ws_summary <- Rmisc::summarySEwithin(
  data = ws_df, measurevar = "mean_val",
  withinvars = c("context", "interference"),
  idvar = "subject", conf.interval = 0.95
) %>%
  dplyr::mutate(
    context      = factor(context, levels = c("No Change", "Change")),
    interference = factor(interference, levels = c("No Interference", "Interference")),
    mean_val     = mean_val * dv_cfg$scale,
    ci           = ci * dv_cfg$scale
  )

# ---- shared y-range from the data (incl. CIs) ---------------------------
y_lo <- min(ws_summary$mean_val - ws_summary$ci)
y_hi <- max(ws_summary$mean_val + ws_summary$ci)
shared_y_range <- c(floor(y_lo   / dv_cfg$yround) * dv_cfg$yround,
                    ceiling(y_hi  / dv_cfg$yround) * dv_cfg$yround)

y_breaks <- if (is.null(dv_cfg$step)) waiver() else scales::breaks_width(dv_cfg$step)

# =========================================================================
# PLOT
# =========================================================================

legend_pos <- "none"; legend_text_size <- 16

ctx_plot <- ggplot(ws_summary,
                   aes(x = context, y = mean_val, color = context, group = 1)) +
  # faint connector between the two context levels (echoes the TCC line motif;
  # delete this layer if you'd rather keep the levels visually separate)
  geom_line(color = "grey40", linewidth = 1) +
  geom_point(size = 4) +
  geom_errorbar(aes(ymin = mean_val - ci, ymax = mean_val + ci),
                width = 0.4, linewidth = 1.0) +
  facet_wrap(~ interference) +
  scale_y_continuous(breaks = y_breaks,
                     expand = expansion(mult = c(0.05, 0.10))) +
  coord_cartesian(ylim = shared_y_range) +
  scale_color_manual(values = c("No Change" = "black", "Change" = "black")) +
  labs(x = "Context", y = dv_cfg$label, color = NULL) +
  theme_classic() +
  theme(
    legend.position  = legend_pos,
    legend.title     = element_blank(),
    legend.text      = element_text(size = legend_text_size),
    strip.background = element_blank(),
    strip.text       = element_text(size = 22, face = "bold", hjust = 0.5),
    plot.background  = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    panel.spacing    = unit(1.2, "lines"),
    axis.title.x = element_text(face = "bold", size = 20, margin = margin(t = 4)),
    axis.title.y = element_text(face = "bold", size = 20, margin = margin(r = 12)),
    axis.text.x  = element_text(size = 15, margin = margin(t = 8), color = "black"),
    axis.text.y  = element_text(size = 15, margin = margin(r = 8), color = "black"),
    axis.ticks.length = unit(0.3, "cm"),
    text = element_text(family = "Arial")
  ) 

# =========================================================================
# SAVE
# =========================================================================
save_dest <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/figures"
dir.create(save_dest, recursive = TRUE, showWarnings = FALSE)

ggsave(
  filename = file.path(save_dest, sprintf("exp2_surprise_%s_context.png", dv)),
  plot   = ctx_plot,
  width  = 9, height = 7, units = "in",   # narrower than TCC (only 2 x-levels)
  dpi    = 300
)

# ---- optional: chance line for 2AFC accuracy ----------------------------
# if (dv == "binary_acc") ctx_plot <- ctx_plot +
#   geom_hline(yintercept = 50, linetype = "dashed", color = "grey60")




















