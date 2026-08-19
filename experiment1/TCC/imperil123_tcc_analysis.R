library(tidyverse)
library(lmerTest)
library(emmeans)
library(glmmTMB)
library(patchwork)
library(Rmisc)
library(performance)
library(car)
library(R.matlab)

exp_handle <- 3
data_out <- sprintf("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/TCC/param_out/imperil%d_TCC_subjectwise_dprime.mat", exp_handle, exp_handle)

df_dprime <- readMat(data_out)

# 2) Extract numeric matrix and convert to data frame
raw_data_matrix <- df_dprime$finalMatrix
raw_data_data_frame <- as.data.frame(raw_data_matrix)

# 3) Assign column names
colnames(raw_data_data_frame) <- c(
  "subject", "repetition", "context", "interference", "dprime")

dprime_set <- raw_data_data_frame %>%
  dplyr::mutate(
    subject = factor(subject),
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context = factor(
      context,
      levels = c(0, 1),
      labels = c("No Change", "Change")
    ),
    interference = factor(interference, levels = c(0, 1), labels = c("No Interference","Interference"))
  ) 

dv <- "dprime"

model_formula <- as.formula(paste0(dv, " ~ repetition * context * interference + (1 | subject)"))

lmm_test <- lmerTest::lmer(
  model_formula,
  data = dprime_set
)

omnibus_test <- car::Anova(lmm_test, type = 2, test.statistic = "F")
print(omnibus_test)

emms <- emmeans(lmm_test, ~  repetition | context)
rep_contrast <- contrast(emms, method = "pairwise", infer= TRUE)
print(rep_contrast)



## Repetition-only data

data_out2 <- sprintf("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/TCC/param_out/imperil%d_TCC_subjectwise_dprime_allreps.mat", exp_handle, exp_handle)

df_dprime_allreps <- readMat(data_out2)

raw_data_matrix2 <- df_dprime_allreps$finalMatrix
raw_data_data_frame2 <- as.data.frame(raw_data_matrix2)

colnames(raw_data_data_frame2) <- c(
  "subject", "repetition", "dprime")

dprime_set2 <- raw_data_data_frame2 %>%
  dplyr::mutate(
    subject = factor(subject),
    repetition = factor(repetition, levels = c(1,2,3,4,5,6), labels = c("1", "2","3","4","5","6"))
  ) 

model_formula2 <- as.formula(paste0(dv, " ~ repetition + (1 | subject)"))

lmm_test2 <- lmerTest::lmer(
  model_formula2,
  data = dprime_set2
)


## EMMs as data frame for the plot
emm_full <- emmeans(lmm_test, ~ interference | repetition * context)
full_df  <- as.data.frame(emm_full)

emm_rep <- emmeans(lmm_test2, ~ repetition)
rep_df  <- as.data.frame(emm_rep)

x_levels <- c("1", "2", "3", "4", "5", "6")

rep_df <- rep_df %>% dplyr::mutate(repetition = factor(repetition, levels = x_levels))
full_df <- full_df %>% dplyr::mutate(
  repetition   = factor(repetition, levels = x_levels),
  context      = factor(context, levels = c("No Change", "Change")),
  interference = factor(interference, levels = c("No Interference", "Interference"))
)


## Within-Subject Summaries (for error bars)

int_levels <- c("No Interference", "Interference")

# Collapsed dprime across all repetition levels
ws_df_rep_all <- dprime_set2 %>%
  dplyr::group_by(subject, repetition) %>%
  dplyr::summarise(mean_error = mean(dprime, na.rm = TRUE), .groups = "drop")

ws_rep_all <- Rmisc::summarySEwithin(
  data = ws_df_rep_all, measurevar = "mean_error",
  withinvars = "repetition", idvar = "subject", conf.interval = 0.95
) %>%
  dplyr::mutate(repetition = factor(repetition, levels = x_levels))

# interference-specific baseline at reps 1 & 5 (collapsed across context)
ws_df_rep_int <- dprime_set %>%
  dplyr::group_by(subject, repetition, interference) %>%
  dplyr::summarise(mean_error = mean(dprime, na.rm = TRUE), .groups = "drop")

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
ws_df_ctx_int <- dprime_set %>%
  dplyr::group_by(subject, repetition, context, interference) %>%
  dplyr::summarise(mean_error = mean(dprime, na.rm = TRUE), .groups = "drop")

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


### HYBRID PLOT

legend_yes <- FALSE
if (legend_yes) {
  legend_pos <- "none"; legend_text_size <- 12
} else {
  legend_pos <- "none";  legend_text_size <- 16
}

step_size <- 0.5
y_label   <- "Memory Strength (d')"


# shared dodge so the context points and their error bars line up
pd <- position_dodge(width = 0.65)

# y-range from THIS experiment's data (band + context points, incl. CIs)
y_lo <- min(ws_summary_rep$mean_error - ws_summary_rep$ci,
            ws_summary_ctx_int$mean_error - ws_summary_ctx_int$ci)
y_hi <- max(ws_summary_rep$mean_error + ws_summary_rep$ci,
            ws_summary_ctx_int$mean_error + ws_summary_ctx_int$ci)
shared_y_range <- c(floor(y_lo), ceiling(y_hi))

ws_hybrid_plot <- ggplot() +
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
    data = ws_summary_rep_for_points,
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
    expand = expansion(mult = c(0.12, 0.10))
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
    legend.position  = "none",
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
  ) + guides(
    color = guide_legend(
      override.aes = list(
        linetype  = 0,      # draw a line through each key
        # linewidth = 1,
        shape     = 16,     # filled circle
        size      = 4
      )
    )
  ) 


# library(cowplot)
# add_legend <- function(p, dx = 0, dy = 0) {
#   ggdraw(p) +
#     # draw_plot_label(
#     #   label = c("A", "B"),
#     #   x = c(.10, .55),     # left edge of each panel
#     #   y = c(.98, .98),     # near the top
#     #   size = 14
#     # ) +
#     # black — Repetition Only
#     draw_line(x = c(.7925, .8075) + dx, y = c(.3400, .3400) + dy, colour = "black",   size = 1) +
#     draw_label("\u25CF", x = .80 + dx, y = .34 + dy, colour = "black",   size = 14) +
#     draw_label("Repetition Only", x = .82 + dx, y = .34 + dy, hjust = 0, size = 14) +
#     # blue — Change
#     draw_line(x = c(.7925, .8075) + dx, y = c(.3700, .3700) + dy, colour = "#4C8FBD", size = 1) +
#     draw_label("\u25CF", x = .80 + dx, y = .37 + dy, colour = "#4C8FBD", size = 14) +
#     draw_label("Change", x = .82 + dx, y = .37 + dy, hjust = 0, size = 14) +
#     # orange — No Change
#     draw_line(x = c(.7925, .8075) + dx, y = c(.4000, .4000) + dy, colour = "#E69F00", size = 1) +
#     draw_label("\u25CF", x = .80 + dx, y = .40 + dy, colour = "#E69F00", size = 14) +
#     draw_label("No Change", x = .82 + dx, y = .40 + dy, hjust = 0, size = 14)
# }


# 
# if (dependent_variable == "angle"){
#   # now apply the legend ONCE, to a different output name:
#   test <- add_legend(exp3_ws_hybrid_plot, dx = -.700, dy = .45)
#   print(test)
# } else if (dependent_variable == "rt"){
#   # now apply the legend ONCE, to a different output name:
#   test <- add_legend(exp3_ws_hybrid_plot, dx = .05, dy = -.08)
#   print(test)
# }


# ws_hybrid_plot_out <- test

### SAVE ----
save_dest <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/figures"
dir.create(save_dest, recursive = TRUE, showWarnings = FALSE)

out_name <- sprintf("exp%d_tcc_dprime.png", exp_handle)

ggsave(
  filename = file.path(save_dest, out_name),
  plot   = ws_hybrid_plot,
  width  = 12, height = 7, units = "in",
  dpi    = 300
)