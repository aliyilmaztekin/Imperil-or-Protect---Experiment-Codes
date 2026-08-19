# Imperil or Protect - Experiment 2 - ANOVA/LMM/Gamma GLMM analysis
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
library(Rmisc)
library(ggtext)

options(scipen = 999)  # Avoid scientific notation

raw_data <- "/Users/ali/Desktop/visual imperil project/imperil_all_analyses_data/all_data_experiment2_sixlets_anova.mat"
raw_data_read <- readMat(raw_data)

# 2) Extract numeric matrix and convert to data frame
raw_data_matrix <- raw_data_read$all.data.experiment2.sixlets.anova
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# 3) Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "trial", "repetition", "block", "angle",
  "rt", "initiation_time", "movement_time",
  "condition", "context", "interference", "raw_angle")

### PREPROCESSING

# Rename the dataset
combinedData <- raw_data_data_frame

# Enter the analysis DV # "angle" or "rt"
dependent_variable    <- "angle"
independent_variables <- c("repetition", "context", "interference")

## Trial-level trimming
# Based on RT

lower <- 0.3

combinedData_firstpass <- combinedData %>%
  dplyr::mutate(angle = abs(((angle + 180) %% 360) - 180)) %>%
  dplyr::mutate(raw_angle = ((raw_angle + 180) %% 360) - 180) %>%
  dplyr::filter(
    !is.na(rt), rt > lower,
    !is.na(angle), angle != 0
  )

quants <- combinedData_firstpass %>%
  dplyr::group_by(subject) %>%
  dplyr::summarise(quantile_p = quantile(rt, 0.95, na.rm = TRUE))

trim_counts <- combinedData_firstpass %>%
  dplyr::group_by(subject) %>%
  dplyr::summarise(
    n_total   = dplyr::n(),
    n_trimmed = sum(rt > quantile(rt, 0.95, na.rm = TRUE), na.rm = TRUE),
    n_kept    = sum(rt <= quantile(rt, 0.95, na.rm = TRUE), na.rm = TRUE)
  )


combinedData_secondpass <- combinedData_firstpass %>%
  dplyr::group_by(subject) %>%
  dplyr::filter(rt <= quantile(rt, 0.95, na.rm = TRUE)) %>%
  dplyr::ungroup()

## Subject-level trimming
# Based on global angular error
bad_subjects <- combinedData_secondpass %>%
  # Determine outlier subjects
  dplyr::group_by(subject) %>%
  dplyr::summarise(global_angle = mean(angle, na.rm = TRUE), .groups = "drop") %>%
  dplyr::filter(global_angle > 45)

message("Excluded subjects (mean abs circular error > 45 deg):")
print(bad_subjects)

combinedData_thirdpass <- combinedData_secondpass %>%
  dplyr::mutate(subject = factor(subject)) %>%
  dplyr::filter(!(subject %in% bad_subjects$subject))

thirdpass_matrix <- data.matrix(combinedData_thirdpass)
writeMat("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment2/mixture_modelling/combinedData_thirdpass2.mat",
         thirdpass = thirdpass_matrix)

miss_trials <- list()   # created once, outside

for (sbj in unique(combinedData_thirdpass$subject)) {
  
  if (sbj %in% bad_subjects$subject) {
    next
  }
  
  kept <- combinedData_thirdpass %>%
    dplyr::filter(subject == sbj) %>%
    dplyr::select(trial)
  
  miss <- setdiff(1:1440, kept$trial)
  
  miss_trials[[as.character(sbj)]] <- miss   # append under this subject's ID
}

named <- miss_trials
names(named) <- paste0("s", names(miss_trials))  

writeMat("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment2/excluded_trials_exp2.mat", miss_trials = named)


# Base preprocessing
combinedData_sub <- combinedData_thirdpass %>%
  dplyr::mutate(
    outcome = .data[[dependent_variable]],
    repetition_num   = as.numeric(as.character(repetition)),
    context_num      = as.numeric(as.character(context)),
    interference_num = as.numeric(as.character(interference))
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
    context_num      %in% c(0, 1),
    interference_num %in% c(0, 1)
  ) %>%
  dplyr::mutate(
    repetition   = factor(repetition_num, levels = c(1, 5), labels = c("1", "5")),
    context      = factor(context_num, levels = c(0, 1),
                          labels = c("No Change", "Change")),
    interference = factor(interference_num, levels = c(0, 1),
                          labels = c("No Interference", "Interference")),
    subject = factor(subject)
  )

combinedData_gamma_rep  <- combinedData_sub_rep  %>% dplyr::filter(is.finite(outcome), outcome > 0)
combinedData_gamma_full <- combinedData_sub_full %>% dplyr::filter(is.finite(outcome), outcome > 0)

desc_stats_subject <- combinedData_gamma_full %>%
  dplyr::group_by(subject, repetition, context, interference) %>%
  dplyr::summarise(subj_mean = mean(outcome, na.rm = TRUE), .groups = "drop") %>%
  dplyr::group_by(repetition, context, interference) %>%
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
summary(glmm_mod_rep)

glmm_mod_full <- glmmTMB(
  outcome ~ repetition * context * interference + (1 | subject),
  data = combinedData_gamma_full,
  family = Gamma(link = "log")
)
summary(glmm_mod_full)
car::Anova(glmm_mod_full, type = 2)       # omnibus χ² per factor + interaction  ← the test you report
rep_emm <- emmeans(glmm_mod_full, ~ context, type = "response")   # marginal means + ratio  ← the estimate you report
rep_contrast <- contrast(rep_emm, method = "pairwise", infer= TRUE)
print(rep_contrast)

### EMMs ----

emm_rep <- emmeans(glmm_mod_rep, ~ repetition, type = "response")
rep_df  <- as.data.frame(emm_rep)

emm_int <- emmeans(glmm_mod_full, ~ interference | repetition * context, type = "response")
int_df  <- as.data.frame(emm_int)

x_levels <- c("1", "2", "3", "4", "5", "6")

rep_df <- rep_df %>% dplyr::mutate(repetition = factor(repetition, levels = x_levels))
int_df <- int_df %>% dplyr::mutate(
  repetition   = factor(repetition, levels = x_levels),
  context      = factor(context, levels = c("No Change", "Change")),
  interference = factor(interference, levels = c("No Interference", "Interference"))
)

### PLOT AESTHETICS ----

legend_yes <- FALSE
if (legend_yes) {
  legend_pos <- "right"; legend_text_size <- 12
} else {
  legend_pos <- "none";  legend_text_size <- 16
}

if (dependent_variable == "angle") {
  step_size <- 2
  y_label   <- "Angular Error (\u00B0)"
} else if (dependent_variable == "rt") {
  step_size <- 0.10 * 1000
  y_label   <- "Reaction Time (ms)"
}

scale_factor <- ifelse(dependent_variable %in% c("rt"), 1000, 1)

### WITHIN-SUBJECT SUMMARIES ----

# 1) Repetition-only baseline.
#    Interference is only manipulated at the test reps (1 & 5), so:
#      - reps 2,3,4,6 -> one overall value, shared across both facets
#      - reps 1 & 5   -> interference-specific (collapsed across context)
int_levels <- c("No Interference", "Interference")

# (a) overall baseline across all six reps (collapsed across everything)
ws_df_rep_all <- combinedData_sub_rep %>%
  dplyr::group_by(subject, repetition) %>%
  dplyr::summarise(mean_error = mean(outcome * scale_factor, na.rm = TRUE), .groups = "drop")

ws_rep_all <- Rmisc::summarySEwithin(
  data = ws_df_rep_all, measurevar = "mean_error",
  withinvars = "repetition", idvar = "subject", conf.interval = 0.95
) %>%
  dplyr::mutate(repetition = factor(repetition, levels = x_levels))

# (b) interference-specific baseline at reps 1 & 5 (collapsed across context)
ws_df_rep_int <- combinedData_sub_full %>%
  dplyr::group_by(subject, repetition, interference) %>%
  dplyr::summarise(mean_error = mean(outcome * scale_factor, na.rm = TRUE), .groups = "drop")

ws_rep_int <- Rmisc::summarySEwithin(
  data = ws_df_rep_int, measurevar = "mean_error",
  withinvars = c("repetition", "interference"), idvar = "subject", conf.interval = 0.95
) %>%
  dplyr::mutate(
    repetition   = factor(repetition, levels = x_levels),
    interference = factor(interference, levels = int_levels)
  )

# (c) assemble the per-facet baseline: reps 2,3,4,6 duplicated into both facets,
#     reps 1 & 5 taken from the interference-specific summary
ws_rep_mid <- ws_rep_all %>% dplyr::filter(!repetition %in% c("1", "5"))
ws_rep_mid <- dplyr::bind_rows(
  ws_rep_mid %>% dplyr::mutate(interference = factor("No Interference", levels = int_levels)),
  ws_rep_mid %>% dplyr::mutate(interference = factor("Interference",    levels = int_levels))
)

ws_summary_rep <- dplyr::bind_rows(
  ws_rep_int %>% dplyr::select(repetition, interference, mean_error, ci),
  ws_rep_mid %>% dplyr::select(repetition, interference, mean_error, ci)
) %>%
  dplyr::mutate(
    repetition   = factor(repetition, levels = x_levels),
    interference = factor(interference, levels = int_levels)
  ) %>%
  dplyr::arrange(interference, repetition)

# 2) Context x interference part: reps 1 and 5 only
ws_df_ctx_int <- combinedData_sub_full %>%
  dplyr::group_by(subject, repetition, context, interference) %>%
  dplyr::summarise(mean_error = mean(outcome * scale_factor, na.rm = TRUE), .groups = "drop")

ws_summary_ctx_int <- Rmisc::summarySEwithin(
  data = ws_df_ctx_int, measurevar = "mean_error",
  withinvars = c("repetition", "context", "interference"),
  idvar = "subject", conf.interval = 0.95
) %>%
  dplyr::mutate(
    repetition   = factor(repetition, levels = x_levels),
    context      = factor(context, levels = c("No Change", "Change")),
    interference = factor(interference, levels = c("No Interference", "Interference"))
  )

# 3) Black error bars only at reps 2,3,4,6 (band carries the CI at 1 & 5)
ws_summary_rep_for_points <- ws_summary_rep %>%
  dplyr::filter(!repetition %in% c("1", "5"))

# 4) Numeric x so the ribbon/line can span the discrete axis
ws_summary_rep <- ws_summary_rep %>%
  dplyr::mutate(rep_x = as.numeric(repetition))

### HYBRID PLOT (exp1 styling, faceted by interference) ----

# shared dodge so the context points and their error bars line up
pd <- position_dodge(width = 0.65)

# y-range from THIS experiment's data (band + context points, incl. CIs)
y_lo <- min(ws_summary_rep$mean_error - ws_summary_rep$ci,
            ws_summary_ctx_int$mean_error - ws_summary_ctx_int$ci)
y_hi <- max(ws_summary_rep$mean_error + ws_summary_rep$ci,
            ws_summary_ctx_int$mean_error + ws_summary_ctx_int$ci)
shared_y_range <- c(floor(y_lo), ceiling(y_hi))

exp2_ws_hybrid_plot <- ggplot() +
  # --- repetition-only baseline band + line, now WITHIN each interference facet ---
  geom_ribbon(
    data = ws_summary_rep,
    aes(x = rep_x, ymin = mean_error - ci, ymax = mean_error + ci, group = interference),
    fill = "grey50", alpha = 0.15,
    inherit.aes = FALSE
  ) +
  geom_line(
    data = ws_summary_rep,
    aes(x = rep_x, y = mean_error, group = interference),
    color = "grey40", linewidth = 1,
    inherit.aes = FALSE
  ) +
  # --- black dots: ALL 6 reps (centred), so 1 & 5 get a marker; mapped for legend ---
  geom_point(
    data = ws_summary_rep,
    aes(x = repetition, y = mean_error, color = "Repetition only"),
    size = 4
  ) +
  # --- black error bars: only reps 2,3,4,6 ---
  geom_errorbar(
    data = ws_summary_rep_for_points,
    aes(x = repetition, ymin = mean_error - ci, ymax = mean_error + ci),
    width = 0.2, linewidth = 1.0, color = "black"
  ) +
  # --- context points at 1 & 5, dodged around the black dot (per interference facet) ---
  geom_point(
    data = ws_summary_ctx_int,
    aes(x = repetition, y = mean_error, color = context),
    size = 4, position = pd
  ) +
  geom_errorbar(
    data = ws_summary_ctx_int,
    aes(x = repetition, ymin = mean_error - ci, ymax = mean_error + ci, color = context),
    width = 0.4, linewidth = 1.0, position = pd
  ) +
  facet_wrap(~ interference) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    breaks = scales::breaks_width(step_size),
    expand = expansion(mult = c(0.02, 0.04))
  ) +
  coord_cartesian(ylim = shared_y_range) +
  scale_color_manual(
    values = c(
      "No Change"       = "orange",
      "Change"          = "steelblue",
      "Repetition only" = "black"
    ),
    breaks = c("No Change", "Change", "Repetition only")
  ) +
  labs(x = "Repetition", y = y_label, color = NULL) +
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


library(cowplot)

add_legend <- function(p, dx = 0, dy = 0) {
  ggdraw(p) +
    # draw_plot_label(
    #   label = c("A", "B"),
    #   x = c(.10, .55),     # left edge of each panel
    #   y = c(.98, .98),     # near the top
    #   size = 14
    # ) +
    # black — Repetition Only
    draw_line(x = c(.7925, .8075) + dx, y = c(.3400, .3400) + dy, colour = "black",   size = 1) +
    draw_label("\u25CF", x = .80 + dx, y = .34 + dy, colour = "black",   size = 14) +
    draw_label("Repetition Only", x = .82 + dx, y = .34 + dy, hjust = 0, size = 14) +
    # blue — Change
    draw_line(x = c(.7925, .8075) + dx, y = c(.3700, .3700) + dy, colour = "#4C8FBD", size = 1) +
    draw_label("\u25CF", x = .80 + dx, y = .37 + dy, colour = "#4C8FBD", size = 14) +
    draw_label("Change", x = .82 + dx, y = .37 + dy, hjust = 0, size = 14) +
    # orange — No Change
    draw_line(x = c(.7925, .8075) + dx, y = c(.4000, .4000) + dy, colour = "#E69F00", size = 1) +
    draw_label("\u25CF", x = .80 + dx, y = .40 + dy, colour = "#E69F00", size = 14) +
    draw_label("No Change", x = .82 + dx, y = .40 + dy, hjust = 0, size = 14)
}


if (dependent_variable == "angle"){
  # now apply the legend ONCE, to a different output name:
  test <- add_legend(exp2_ws_hybrid_plot, dx = -.700, dy = .45)
  print(test)
} else if (dependent_variable == "rt"){
  # now apply the legend ONCE, to a different output name:
  test <- add_legend(exp2_ws_hybrid_plot, dx = .05, dy = -.08)
  print(test)
}


exp2_ws_hybrid_plot_out <- test

### SAVE ----

save_dest <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/figures"
dir.create(save_dest, recursive = TRUE, showWarnings = FALSE)

out_name <- if (dependent_variable == "angle") "exp2_error_plot.png" else "exp2_time_plot.png"

ggsave(
  filename = file.path(save_dest, out_name),
  plot   = exp2_ws_hybrid_plot_out,
  width  = 12, height = 7, units = "in",   # matched to the exp1 figure
  dpi    = 300
)