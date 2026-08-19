library(tidyverse)
library(lmerTest)
library(emmeans)
library(glmmTMB)
library(patchwork)
library(Rmisc)
library(performance)
library(ragg)
# =========================
# Choose test
# =========================

target_test <- "2"   # Test 1 only

# =========================
# Load repetition 1-6 data
# =========================

  df_all <- read.csv("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/mixture_modelling/param_output/mixture_parameters_all_repetitions.csv") %>%
    dplyr::mutate(
      subject = factor(subject),
      test = factor(test),
      repetition = factor(repetition, levels = 1:6)
    ) %>%
    dplyr::filter(
      test == target_test,
      is.finite(g),
      is.finite(SD),
      SD > 0
    )
  
  df_all_collapsed <- df_all %>%
    dplyr::group_by(subject, repetition) %>%
    dplyr::summarise(
      g = mean(g, na.rm = TRUE),
      SD = mean(SD, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::mutate(
      subject = factor(subject),
      repetition = factor(repetition, levels = 1:6)
    )
  
  df_all_g <- df_all_collapsed %>%
    dplyr::mutate(
      g_raw = g,
      g_model = pmin(pmax(g, 1e-4), 1 - 1e-4),
      logit_g = qlogis(g_model)
    )
  
  df_all_SD <- df_all_collapsed %>%
    dplyr::filter(is.finite(SD), SD > 0)
              
  # =========================
  # Models for repetition 1-6 trajectory
  # =========================
  
  m_g_all <- lmer(
    logit_g ~ repetition + (1 | subject),
    data = df_all_g
  )
  
  m_SD_all <- glmmTMB(
    SD ~ repetition + (1 | subject),
    data = df_all_SD,
    family = Gamma(link = "log")
  )
  
  # =========================
  # EMMs for repetition 1-6 trajectory
  # =========================
  
  all_g <- as.data.frame(confint(emmeans(m_g_all, ~ repetition))) %>%
    dplyr::mutate(
      response = plogis(emmean),
      lower_model = plogis(lower.CL),
      upper_model = plogis(upper.CL)
    )
  
  all_SD <- as.data.frame(emmeans(m_SD_all, ~ repetition, type = "response"))
  
  if ("lower.CL" %in% names(all_SD)) {
    all_SD <- all_SD %>%
      dplyr::rename(lower_model = lower.CL, upper_model = upper.CL)
  } else if ("asymp.LCL" %in% names(all_SD)) {
    all_SD <- all_SD %>%
      dplyr::rename(lower_model = asymp.LCL, upper_model = asymp.UCL)
  }
  

  # =========================
  # Load old rep 1/5 context data
  # =========================
  
  df_ctx <- read.csv("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/mixture_modelling/param_output/mixture_parameters_rep1_rep5.csv") %>%
    dplyr::mutate(
      subject = factor(subject),
      test = factor(test),
      repetition = factor(repetition, levels = c(1, 5)),
      context = factor(
        context,
        levels = c(0, 1),
        labels = c("No Change", "Change")
      )
    ) %>%
    dplyr::filter(
      test == target_test,
      is.finite(g),
      is.finite(SD),
      SD > 0
    )
  
  df_ctx_g <- df_ctx %>%
    dplyr::mutate(
      g_raw = g,
      g_model = pmin(pmax(g, 1e-4), 1 - 1e-4),
      logit_g = qlogis(g_model)
    )
  
  df_ctx_SD <- df_ctx %>%
    dplyr::filter(is.finite(SD), SD > 0)
  
  # =========================
  # Context models
  # =========================
  
  m_g_ctx <- lmer(
    logit_g ~ repetition * context + (1 | subject),
    data = df_ctx_g
  )
  
  car::Anova(m_g_ctx, type = 2, test.statistic = "F")
  rep_emm <- emmeans(m_g_ctx, ~ repetition,
                     tran = "logit", type = "response")
  rep_contrast <- contrast(rep_emm, method = "pairwise", infer= TRUE)
  print(rep_contrast)
  
  
  
  



m_SD_ctx <- lmer(
  SD ~ repetition * context + (1 | subject),
  data = df_ctx_SD,
)
car::Anova(m_SD_ctx, type = 2, test.statistic = "F")
rep_emm <- emmeans(m_SD_ctx, ~  repetition, type = "response")   # marginal means + ratio  ← the estimate you report
rep_contrast <- contrast(rep_emm, method = "pairwise", infer= TRUE)
print(rep_contrast)




# =========================
# Context EMMs
# =========================

ctx_g <- as.data.frame(confint(emmeans(m_g_ctx, ~ repetition * context))) %>%
  dplyr::mutate(
    response = plogis(emmean),
    lower_model = plogis(lower.CL),
    upper_model = plogis(upper.CL)
  )

ctx_SD <- as.data.frame(emmeans(m_SD_ctx, ~ repetition * context, type = "response"))

if ("lower.CL" %in% names(ctx_SD)) {
  ctx_SD <- ctx_SD %>%
    dplyr::rename(
      lower_model = lower.CL,
      upper_model = upper.CL
    )
} else if ("asymp.LCL" %in% names(ctx_SD)) {
  ctx_SD <- ctx_SD %>%
    dplyr::rename(
      lower_model = asymp.LCL,
      upper_model = asymp.UCL
    )
}



# =========================================================================
# REPLACEMENT for the within-subject-CI section + plotting section of script 1.
#
# Keep your model fits (m_g_all, m_SD_all, m_g_ctx, m_SD_ctx) and the
# emmeans/contrast PRINTS above this — they're still your inferential stats.
#
# The change: the plotted point centers are now the RAW within-subject means
# (what summarySEwithin already returns), not plogis(emmean). This removes the
# logit "mean-of-vs-logit-of" artifact, so the collapsed black baseline is a
# true arithmetic average and sits among the colored condition dots.
# (This is also exactly how script 2 builds its points.)
# =========================================================================

# -------------------------------------------------------------------------
# Plot data: raw within-subject means + Cousineau-Morey CIs
# -------------------------------------------------------------------------

# --- collapsed rep 1-6 baseline ---
# Reps 2,3,4,6: pooled fits from df_all (unchanged).
# Reps 1 & 5:   collapse the two per-context fits over context, per subject,
#               so the black dot lands on the exact midpoint of the coloured dots.

# helper: pooled values across all 6 reps
pooled_g <- Rmisc::summarySEwithin(
  data = df_all_g, measurevar = "g_raw",
  withinvars = "repetition", idvar = "subject", conf.interval = 0.95
) %>%
  dplyr::transmute(
    repetition = factor(repetition, levels = 1:6),
    response   = g_raw,
    lower_ws   = pmax(0, g_raw - ci),
    upper_ws   = pmin(1, g_raw + ci)
  )

# collapsed-over-context values, reps 1 & 5 only
coll_g_15 <- df_ctx_g %>%
  dplyr::group_by(subject, repetition) %>%
  dplyr::summarise(g_raw = mean(g_raw, na.rm = TRUE), .groups = "drop") %>%
  dplyr::mutate(repetition = droplevels(factor(repetition, levels = c(1, 5)))) %>%
  Rmisc::summarySEwithin(
    measurevar = "g_raw", withinvars = "repetition",
    idvar = "subject", conf.interval = 0.95
  ) %>%
  dplyr::transmute(
    repetition = factor(as.character(repetition), levels = 1:6),
    response   = g_raw,
    lower_ws   = pmax(0, g_raw - ci),
    upper_ws   = pmin(1, g_raw + ci)
  )

# splice: pooled for 2,3,4,6 + collapsed for 1,5
all_g_ws <- dplyr::bind_rows(
  pooled_g  %>% dplyr::filter(!repetition %in% c("1", "5")),
  coll_g_15
) %>%
  dplyr::arrange(as.numeric(as.character(repetition)))


# ---- same for SD (no 0/1 clamp) ----
pooled_SD <- Rmisc::summarySEwithin(
  data = df_all_SD, measurevar = "SD",
  withinvars = "repetition", idvar = "subject", conf.interval = 0.95
) %>%
  dplyr::transmute(
    repetition = factor(repetition, levels = 1:6),
    response   = SD,
    lower_ws   = SD - ci,
    upper_ws   = SD + ci
  )

coll_SD_15 <- df_ctx_SD %>%
  dplyr::group_by(subject, repetition) %>%
  dplyr::summarise(SD = mean(SD, na.rm = TRUE), .groups = "drop") %>%
  dplyr::mutate(repetition = droplevels(factor(repetition, levels = c(1, 5)))) %>%
  Rmisc::summarySEwithin(
    measurevar = "SD", withinvars = "repetition",
    idvar = "subject", conf.interval = 0.95
  ) %>%
  dplyr::transmute(
    repetition = factor(as.character(repetition), levels = 1:6),
    response   = SD,
    lower_ws   = SD - ci,
    upper_ws   = SD + ci
  )

all_SD_ws <- dplyr::bind_rows(
  pooled_SD %>% dplyr::filter(!repetition %in% c("1", "5")),
  coll_SD_15
) %>%
  dplyr::arrange(as.numeric(as.character(repetition)))

# --- context-split points at reps 1 & 5 ---
ctx_g_ws <- Rmisc::summarySEwithin(
  data = df_ctx_g, measurevar = "g_raw",
  withinvars = c("repetition", "context"), idvar = "subject", conf.interval = 0.95
) %>%
  dplyr::transmute(
    repetition = factor(repetition, levels = c(1, 5)),
    context    = factor(context, levels = c("No Change", "Change")),
    response   = g_raw,
    lower_ws   = pmax(0, g_raw - ci),
    upper_ws   = pmin(1, g_raw + ci)
  )

ctx_SD_ws <- Rmisc::summarySEwithin(
  data = df_ctx_SD, measurevar = "SD",
  withinvars = c("repetition", "context"), idvar = "subject", conf.interval = 0.95
) %>%
  dplyr::transmute(
    repetition = factor(repetition, levels = c(1, 5)),
    context    = factor(context, levels = c("No Change", "Change")),
    response   = SD,
    lower_ws   = SD - ci,
    upper_ws   = SD + ci
  )

# =========================================================================
# Plotting (unchanged from the hybrid version — it just reads `response`)
# =========================================================================

library(patchwork)
library(scales)

x_levels <- c("1", "2", "3", "4", "5", "6")

pal <- c(
  "No Change"       = "orange",
  "Change"          = "steelblue",
  "Repetition only" = "black"
)

all_g_ws  <- all_g_ws  %>% dplyr::mutate(rep_x = as.numeric(as.character(repetition)))
all_SD_ws <- all_SD_ws %>% dplyr::mutate(rep_x = as.numeric(as.character(repetition)))

all_g_ws_pts  <- all_g_ws  %>% dplyr::filter(!repetition %in% c("1", "5"))
all_SD_ws_pts <- all_SD_ws %>% dplyr::filter(!repetition %in% c("1", "5"))

pd <- position_dodge(width = 0.65)

hybrid_theme <- theme_classic() +
  theme(
    plot.title       = element_text(size = if (target_test == 1) 22 else 0 , face = "bold", hjust = 0.5),
    legend.title     = element_blank(),
    legend.text      = element_text(size = 16),
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    axis.title.x = element_text(face = "bold", size = if (target_test == 1) 0 else 20, margin = margin(t = 4)),
    axis.title.y = element_text(face = "bold", size = 20, margin = margin(r = 12)),
    axis.text.x  = element_text(size = 15, margin = margin(t = 8), color = "black"),
    axis.text.y  = element_text(size = 15, margin = margin(r = 8), color = "black"),
    axis.ticks.length = unit(0.3, "cm"),
    text = element_text(family = "Arial")
  ) 

# ---- Guess rate ----
p_g_hybrid <- ggplot() +
  geom_ribbon(data = all_g_ws,
              aes(x = rep_x, ymin = lower_ws, ymax = upper_ws),
              fill = "grey50", alpha = 0.15, inherit.aes = FALSE) +
  geom_line(data = all_g_ws,
            aes(x = rep_x, y = response),
            color = "grey40", linewidth = 1, inherit.aes = FALSE) +
  geom_point(data = all_g_ws_pts,
             aes(x = repetition, y = response, color = "Repetition only"),
             size = 4) +
  geom_errorbar(data = all_g_ws_pts,
                aes(x = repetition, ymin = lower_ws, ymax = upper_ws),
                width = 0.2, linewidth = 1.0, color = "black") +
  geom_errorbar(data = ctx_g_ws,
                aes(x = repetition, ymin = lower_ws, ymax = upper_ws, color = context),
                width = 0.4, linewidth = 1.0, position = pd) +
  geom_point(data = ctx_g_ws,
             aes(x = repetition, y = response, color = context),
             size = 4, position = pd) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.5),
                     expand = expansion(mult = c(0.01, 0.10)),
                     breaks = ifelse(target_test == 1, scales::breaks_width(0.01), scales::breaks_width(0.02))) +    
  scale_color_manual(values = pal,
                     breaks = c("No Change", "Change", "Repetition only")) +
  labs(x = ifelse(target_test == 2, "Repetition", ""), y = if (target_test == 1) "g (Novel Item)" else "g (Repeated Item)", color = NULL) +
  ggtitle("Guess Rate") +
  hybrid_theme +
  guides(color = guide_legend(override.aes = list(linetype = 0, shape = 16, size = 4)))


# ---- Precision (SD) ----
p_SD_hybrid <- ggplot() +
  geom_ribbon(data = all_SD_ws,
              aes(x = rep_x, ymin = lower_ws, ymax = upper_ws),
              fill = "grey50", alpha = 0.15, inherit.aes = FALSE) +
  geom_line(data = all_SD_ws,
            aes(x = rep_x, y = response),
            color = "grey40", linewidth = 1, inherit.aes = FALSE) +
  geom_point(data = all_SD_ws_pts,
             aes(x = repetition, y = response, color = "Repetition only"),
             size = 4) +
  geom_errorbar(data = all_SD_ws_pts,
                aes(x = repetition, ymin = lower_ws, ymax = upper_ws),
                width = 0.2, linewidth = 1.0, color = "black") +
  geom_errorbar(data = ctx_SD_ws,
                aes(x = repetition, ymin = lower_ws, ymax = upper_ws, color = context),
                width = 0.4, linewidth = 1.0, position = pd) +
  geom_point(data = ctx_SD_ws,
             aes(x = repetition, y = response, color = context),
             size = 4, position = pd) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(breaks = scales::breaks_width(1),
                     expand = expansion(mult = c(0.02, 0.12))) +
  scale_color_manual(values = pal,
                     breaks = c("No Change", "Change", "Repetition only")) +
  labs(x = ifelse(target_test == 2, "Repetition", ""), y = if (target_test == 1) "SD (Novel Item)" else "SD (Repeated Item)", color = NULL) +
  ggtitle("Memory Precision") +
  hybrid_theme  +
  guides(color = guide_legend(override.aes = list(linetype = 0, shape = 16, size = 4)))


# ---- Combine + save ----
p_hybrid <- (p_g_hybrid + p_SD_hybrid) +
  plot_layout(guides = "collect") &
  theme(
    legend.position  = if (target_test == 2) "none" else "none",
    legend.direction = "horizontal",   # force consistent orientation
  ) 

print(p_hybrid)

if (target_test == 1) {
  p_hybrid_test1 <- p_hybrid
} else if (target_test == 2) {
  p_hybrid_test2 <- p_hybrid
}

save_dest <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/figures"
dir.create(save_dest, recursive = TRUE, showWarnings = FALSE)
if (target_test == 1) {
  ggsave(
    filename = file.path(save_dest, "exp4_mixture_hybrid_test1.png"),
    plot   = p_hybrid,
    width  = 18, height = 7, units = "in",
    dpi    = 110,
    device = ragg::agg_png
  )
} else if (target_test == 2) {
  ggsave(
    filename = file.path(save_dest, "exp4_mixture_hybrid_test2.png"),
    plot   = p_hybrid,
    width  = 18, height = 7, units = "in",
    dpi    = 110,
    device = ragg::agg_png
  )
}
