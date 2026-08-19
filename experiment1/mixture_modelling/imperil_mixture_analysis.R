library(tidyverse)
library(lmerTest)
library(emmeans)
library(glmmTMB)
library(patchwork)
library(Rmisc)
library(performance)
library(car)

# =========================================================================
# MIXTURE MODEL  ->  hybrid plot (mirrors the TCC d' pipeline exactly)
#
# Produces the same hybrid figure for the mixture-model parameters:
#     SD  (response variability / precision)
#     g   (guess rate)
#
# Style, facets, colours, dodge, error bars, theme, legend: identical to TCC.
#
# NOTE on how the TCC plot works (and therefore this one):
#   The plotted points + error bars come from Rmisc::summarySEwithin on the
#   RAW subject-level values (Cousineau-Morey within-subject CIs), NOT from
#   the model emmeans. The lmer models below are only for the omnibus/contrast
#   inference, exactly as in the TCC script.
# =========================================================================

library(dplyr)
library(lmerTest)
library(emmeans)
library(car)
library(Rmisc)
library(ggplot2)
library(scales)
library(cowplot)


exp_handle <- 3
# =========================================================================
# 0) DATA SOURCES
# =========================================================================

# --- context version: reps 1 & 5, with context x interference -------------
# (this is your existing file; it already has named columns incl. g, SD)
data_csv <- sprintf(
  "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/mixture_modelling/param_out/exp_%d_mixture_parameters_rep1_rep5.csv",
  exp_handle, exp_handle
)

# --- repetition-only version: reps 1..6, subject-wise ---------------------
# >>> ANALOGUE OF THE TCC *_allreps.mat FILE. <<<
# The grey baseline band (which spans all 6 reps) needs this. Point it at
# your mixture "allreps" export. If you don't have one, see the note at the
# bottom of this file for a reps-1&5-only variant.
data_csv_allreps <- sprintf(
 "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment%d/mixture_modelling/param_out/exp_%d_mixture_parameters_all_reps.csv",
  exp_handle, exp_handle
)

# =========================================================================
# 1) CONTEXT DATA (reps 1 & 5)  -- your existing preprocessing, carried on
# =========================================================================

df_ctx <- read.csv(data_csv) %>%
  dplyr::mutate(
    subject      = factor(subject),
    repetition   = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context      = factor(context, levels = c(0, 1),
                          labels = c("No Change", "Change")),
    interference = factor(interference, levels = c(0, 1),
                          labels = c("No Interference", "Interference"))
  ) %>%
  dplyr::filter(is.finite(g), is.finite(SD), SD > 0)

df_ctx_g <- df_ctx %>%
  dplyr::mutate(
    g_raw   = g,
    g_model = pmin(pmax(g, 1e-4), 1 - 1e-4),
    logit_g = qlogis(g_model)
  )

df_ctx_SD <- df_ctx_g %>% dplyr::filter(is.finite(SD), SD > 0, SD < 100)

# =========================================================================
# 2) REPETITION-ONLY DATA (reps 1..6)  -- analogue of dprime_set2
# =========================================================================

df_rep <- read.csv(data_csv_allreps) %>%
  dplyr::mutate(
    subject    = factor(subject),
    repetition = factor(repetition, levels = 1:6,
                        labels = c("1", "2", "3", "4", "5", "6"))
  ) %>%
  dplyr::filter(is.finite(g), is.finite(SD), SD > 0) %>%
  dplyr::mutate(
    g_model = pmin(pmax(g, 1e-4), 1 - 1e-4),
    logit_g = qlogis(g_model)
  )

df_rep_SD <- df_rep %>% dplyr::filter(SD < 100)   # match df_ctx_SD guard

# =========================================================================
# 3) MODELS  (inference only -- mirrors the TCC omnibus + contrast block)
# =========================================================================

## ---- SD : raw scale (as in your snippet) --------------------------------
m_SD_ctx <- lmerTest::lmer(
  SD ~ repetition * context * interference + (1 | subject),
  data = df_ctx_SD
)
cat("\n===== SD : omnibus (Type II F) =====\n")
print(car::Anova(m_SD_ctx, type = 2, test.statistic = "F"))

emms_SD <- emmeans(m_SD_ctx, ~  interference | context)
cat("\n===== SD : interference | repetition (pairwise) =====\n")
print(contrast(emms_SD, method = "pairwise", infer = TRUE))

m_SD_rep <- lmerTest::lmer(SD ~ repetition + (1 | subject), data = df_rep_SD)

## ---- g : logit scale (uses your logit_g), back-transformed for reporting -
m_g_ctx <- lmerTest::lmer(
  logit_g ~ repetition * context * interference + (1 | subject),
  data = df_ctx_g
)
print(car::Anova(m_g_ctx, type = 2, test.statistic = "F"))

# tell emmeans the response was manually logit-transformed so it can back-transform
emms_g <- emmeans(ref_grid(m_g_ctx, tran = "logit"),
                  ~  interference | repetition + context , type = "response")
cat("\n===== g : interference | repetition (pairwise, odds-ratio scale) =====\n")
print(contrast(emms_g, method = "pairwise", infer = TRUE))

m_g_rep <- lmerTest::lmer(logit_g ~ repetition + (1 | subject), data = df_rep)

# =========================================================================
# 4) HYBRID PLOT BUILDER  (identical layout to the TCC hybrid plot)
# =========================================================================

x_levels   <- c("1", "2", "3", "4", "5", "6")
int_levels <- c("No Interference", "Interference")

make_hybrid_plot <- function(dv, y_label, step_size, y_round,
                             d_ctx, d_rep,
                             x_levels = c("1","2","3","4","5","6"),
                             int_levels = c("No Interference", "Interference"),
                             legend_pos = "none", legend_text_size = 16,
                             y_percent = FALSE,
                             y_range = NULL) {          # <- new arg
  
  # generic value column so the rest is DV-agnostic
  d_ctx <- d_ctx %>% dplyr::mutate(value = .data[[dv]])
  d_rep <- d_rep %>% dplyr::mutate(value = .data[[dv]])
  
  # ---- within-subject summaries (for error bars) -------------------------
  
  # collapsed across all repetition levels (baseline band + line)
  ws_df_rep_all <- d_rep %>%
    dplyr::group_by(subject, repetition) %>%
    dplyr::summarise(mean_error = mean(value, na.rm = TRUE), .groups = "drop")
  
  ws_rep_all <- Rmisc::summarySEwithin(
    data = ws_df_rep_all, measurevar = "mean_error",
    withinvars = "repetition", idvar = "subject", conf.interval = 0.95
  ) %>%
    dplyr::mutate(repetition = factor(repetition, levels = x_levels))
  
  # interference-specific baseline at reps 1 & 5 (collapsed across context)
  ws_df_rep_int <- d_ctx %>%
    dplyr::group_by(subject, repetition, interference) %>%
    dplyr::summarise(mean_error = mean(value, na.rm = TRUE), .groups = "drop")
  
  ws_rep_int <- Rmisc::summarySEwithin(
    data = ws_df_rep_int, measurevar = "mean_error",
    withinvars = c("repetition", "interference"), idvar = "subject",
    conf.interval = 0.95
  ) %>%
    dplyr::mutate(
      repetition   = factor(repetition, levels = x_levels),
      interference = factor(interference, levels = int_levels)
    )
  
  # per-facet baseline: reps 2,3,4,6 duplicated into both facets;
  # reps 1 & 5 taken from the interference-specific summary
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
  
  # context x interference part: reps 1 & 5 only
  ws_df_ctx_int <- d_ctx %>%
    dplyr::group_by(subject, repetition, context, interference) %>%
    dplyr::summarise(mean_error = mean(value, na.rm = TRUE), .groups = "drop")
  
  ws_summary_ctx_int <- Rmisc::summarySEwithin(
    data = ws_df_ctx_int, measurevar = "mean_error",
    withinvars = c("repetition", "context", "interference"),
    idvar = "subject", conf.interval = 0.95
  ) %>%
    dplyr::mutate(
      repetition   = factor(repetition, levels = x_levels),
      context      = factor(context, levels = c("No Change", "Change")),
      interference = factor(interference, levels = int_levels)
    )
  
  # black error bars only at reps 2,3,4,6 (band carries the CI at 1 & 5)
  ws_summary_rep_for_points <- ws_summary_rep %>%
    dplyr::filter(!repetition %in% c("1", "5"))
  
  # numeric x so the ribbon/line can span the discrete axis
  ws_summary_rep <- ws_summary_rep %>%
    dplyr::mutate(rep_x = as.numeric(repetition))
  
  # ---- plot --------------------------------------------------------------
  pd <- position_dodge(width = 0.65)
  
  # one y-range for the WHOLE plot (both facets share it)
  range_df <- if (!is.null(y_range)) {
    data.frame(mean_error = y_range, rep_x = 1)   # no interference col -> applies to all facets
  } else NULL
  
  ggplot() +
    # --- repetition-only baseline band + line, WITHIN each interference facet
    geom_ribbon(
      data = ws_summary_rep,
      aes(x = rep_x, ymin = mean_error - ci, ymax = mean_error + ci, group = interference),
      fill = "grey50", alpha = 0.15, inherit.aes = FALSE
    ) +
    geom_line(
      data = ws_summary_rep,
      aes(x = rep_x, y = mean_error, group = interference),
      color = "grey40", linewidth = 1, inherit.aes = FALSE
    ) +
    # --- black dots: ALL 6 reps (centred); mapped for legend ---------------
  geom_point(
    data = ws_summary_rep_for_points,
    aes(x = repetition, y = mean_error, color = "Repetition only"), size = 4
  ) +
    # --- black error bars: only reps 2,3,4,6 -------------------------------
  geom_errorbar(
    data = ws_summary_rep_for_points,
    aes(x = repetition, ymin = mean_error - ci, ymax = mean_error + ci),
    width = 0.2, linewidth = 1.0, color = "black"
  ) +
    # --- context points at 1 & 5, dodged (per interference facet) ----------
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
      labels = if (y_percent) scales::label_percent(accuracy = 1) else waiver(),
      expand = expansion(mult = c(0.02, 0.10))
    ) +
    # ... after your last errorbar layer, before facet_wrap ...
    {if (!is.null(range_df))
      geom_blank(data = range_df, aes(x = rep_x, y = mean_error), inherit.aes = FALSE)} +
    facet_wrap(~ interference) +          # no scales = "free_y"
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
    ) +
  guides(
    color = guide_legend(
      override.aes = list(
        linetype  = 0,      # draw a line through each key
        # linewidth = 1,
        shape     = 16,     # filled circle
        size      = 4
      )
    )
  )
}
  

# # =========================================================================
# # 5) LEGEND OVERLAY  (carried over verbatim from the TCC script)
# # =========================================================================
# # 
# add_legend <- function(p, dx = 0, dy = 0) {
#   ggdraw(p) +
#     # black - Repetition Only
#     draw_line(x = c(.7925, .8075) + dx, y = c(.3400, .3400) + dy, colour = "black",   size = 1) +
#     draw_label("\u25CF", x = .80 + dx, y = .34 + dy, colour = "black",   size = 14) +
#     draw_label("Repetition Only", x = .82 + dx, y = .34 + dy, hjust = 0, size = 14) +
#     # blue - Change
#     draw_line(x = c(.7925, .8075) + dx, y = c(.3700, .3700) + dy, colour = "#4C8FBD", size = 1) +
#     draw_label("\u25CF", x = .80 + dx, y = .37 + dy, colour = "#4C8FBD", size = 14) +
#     draw_label("Change", x = .82 + dx, y = .37 + dy, hjust = 0, size = 14) +
#     # orange - No Change
#     draw_line(x = c(.7925, .8075) + dx, y = c(.4000, .4000) + dy, colour = "#E69F00", size = 1) +
#     draw_label("\u25CF", x = .80 + dx, y = .40 + dy, colour = "#E69F00", size = 14) +
#     draw_label("No Change", x = .82 + dx, y = .40 + dy, hjust = 0, size = 14)
# }

# =========================================================================
# 6) BUILD + SAVE
# =========================================================================

p_SD <- make_hybrid_plot(
  dv = "SD", y_label = "Memory Precision (SD)",
  step_size = if (exp_handle %in% c(1, 2)) 1 else 4,
  y_round = 5,
  d_ctx = df_ctx_SD, d_rep = df_rep_SD,
  y_range = c(16, 25.5)        
)
p_g <- make_hybrid_plot(
  dv = "g", y_label = "Guess Rate (g)",
  step_size = if (exp_handle %in% c(1:2)) 0.02 else 0.05, 
  y_round = 2.5,
  d_ctx = df_ctx_g, d_rep = df_rep,
  y_percent = TRUE,
  y_range = c(0, 0.19)         
)

# p_SD_leg <- add_legend(p_SD)
# p_g_leg  <- add_legend(p_g)

save_dest <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/figures"
dir.create(save_dest, recursive = TRUE, showWarnings = FALSE)

ggsave(
  filename = file.path(save_dest, sprintf("exp%d_mixture_SD.png", exp_handle)),
  plot = p_SD, width = 12, height = 7, units = "in", dpi = 300
)

ggsave(
  filename = file.path(save_dest, sprintf("exp%d_mixture_g.png", exp_handle)),
  plot = p_g, width = 12, height = 7, units = "in", dpi = 300
)

# =========================================================================
# NOTE - no allreps mixture file?
# If you don't have a reps-1..6 export and only want the reps-1&5 points
# (context x interference) without the grey baseline band, drop the two
# geom_ribbon/geom_line layers and the "Repetition only" geom_point/geom_errorbar
# from make_hybrid_plot(), and pass any placeholder for d_rep. Tell me and I'll
# hand you that trimmed version.
# =========================================================================
