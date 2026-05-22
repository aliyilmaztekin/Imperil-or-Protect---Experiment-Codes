library(tidyverse)
library(lmerTest)
library(emmeans)
library(glmmTMB)
library(patchwork)
library(Rmisc)

# =========================
# Choose test
# =========================

target_test <- "2"   # Test 1 only

# =========================
# Load repetition 1-6 data
# =========================

df_all <- read.csv("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/mixture_modelling/mixture_parameters_all_repetitions_test1_test2.csv") %>%
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
# Within-subject CI widths for repetition 1-6 trajectory
# =========================

ws_g_all <- Rmisc::summarySEwithin(
  data = df_all_g,
  measurevar = "g_raw",
  withinvars = "repetition",
  idvar = "subject",
  conf.interval = 0.95
) %>%
  dplyr::select(repetition, ci_g = ci)

ws_SD_all <- Rmisc::summarySEwithin(
  data = df_all_SD,
  measurevar = "SD",
  withinvars = "repetition",
  idvar = "subject",
  conf.interval = 0.95
) %>%
  dplyr::select(repetition, ci_SD = ci)

all_g_ws <- all_g %>%
  dplyr::left_join(ws_g_all, by = "repetition") %>%
  dplyr::mutate(
    lower_ws = pmax(0, response - ci_g),
    upper_ws = pmin(1, response + ci_g)
  )

all_SD_ws <- all_SD %>%
  dplyr::left_join(ws_SD_all, by = "repetition") %>%
  dplyr::mutate(
    lower_ws = response - ci_SD,
    upper_ws = response + ci_SD
  )

# =========================
# Load old rep 1/5 context data
# =========================

df_ctx <- read.csv("/Users/ali/Desktop/visual imperil project/imperil4materials/mixture_parameters_rep1_rep5_test1_test2.csv") %>%
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

# m_g_ctx <- lmer(
#   logit_g ~ repetition * context + (1 | subject),
#   data = df_ctx_g
# )

m_SD_ctx <- glmmTMB(
  SD ~ repetition * context + (1 | subject),
  data = df_ctx_SD,
  family = Gamma(link = "log")
)

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
    dplyr::rename(lower_model = lower.CL, upper_model = upper.CL)
} else if ("asymp.LCL" %in% names(ctx_SD)) {
  ctx_SD <- ctx_SD %>%
    dplyr::rename(lower_model = asymp.LCL, upper_model = asymp.UCL)
}

# =========================
# Within-subject CI widths for context overlay
# =========================

ws_g_ctx <- Rmisc::summarySEwithin(
  data = df_ctx_g,
  measurevar = "g_raw",
  withinvars = c("repetition", "context"),
  idvar = "subject",
  conf.interval = 0.95
) %>%
  dplyr::select(repetition, context, ci_g = ci)

ws_SD_ctx <- Rmisc::summarySEwithin(
  data = df_ctx_SD,
  measurevar = "SD",
  withinvars = c("repetition", "context"),
  idvar = "subject",
  conf.interval = 0.95
) %>%
  dplyr::select(repetition, context, ci_SD = ci)

ctx_g_ws <- ctx_g %>%
  dplyr::left_join(ws_g_ctx, by = c("repetition", "context")) %>%
  dplyr::mutate(
    lower_ws = pmax(0, response - ci_g),
    upper_ws = pmin(1, response + ci_g)
  )

ctx_SD_ws <- ctx_SD %>%
  dplyr::left_join(ws_SD_ctx, by = c("repetition", "context")) %>%
  dplyr::mutate(
    lower_ws = response - ci_SD,
    upper_ws = response + ci_SD
  )
# =========================
# Plot settings
# =========================

all_g_ws_plot <- all_g_ws %>%
  filter(!repetition %in% c("1", "5"))

all_SD_ws_plot <- all_SD_ws %>%
  filter(!repetition %in% c("1", "5"))

x_levels <- as.character(1:6)

my_theme <- theme_classic() +
  theme(
    plot.title = element_text(size = 28),
    legend.title = element_blank(),
    legend.text = element_text(size = 24),
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    axis.title.x = element_text(face = "bold", size = 28),
    axis.title.y = element_text(face = "bold", size = 28),
    axis.text.x = element_text(size = 24, color = "black"),
    axis.text.y = element_text(size = 24, color = "black"),
    text = element_text(family = "Arial")
  )

# =========================
# Hybrid guess-rate plot
# =========================

p_g_hybrid <- ggplot() +
  geom_point(
    data = all_g_ws_plot,
    aes(x = repetition, y = response),
    size = 4.5,
    color = "black"
  ) +
  geom_errorbar(
    data = all_g_ws_plot,
    aes(
      x = repetition,
      ymin = pmax(0, lower_ws),
      ymax = upper_ws
    ),
    width = 0.18,
    linewidth = 0.9,
    color = "black"
  ) +
  geom_point(
    data = ctx_g_ws,
    aes(x = repetition, y = response, color = context),
    size = 5.5,
    position = position_dodge(width = 0.35)
  ) +
  geom_errorbar(
    data = ctx_g_ws,
    aes(
      x = repetition,
      ymin = pmax(0, lower_ws),
      ymax = upper_ws,
      color = context
    ),
    width = 0.18,
    linewidth = 1.0,
    position = position_dodge(width = 0.35)
  ) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 0.5),
    breaks = seq(0, 0.03, 0.005),
    limits = c(0, 0.03),
    expand = expansion(mult = c(0, 0.05))
  )+
  scale_color_manual(values = c("No Change" = "orange", "Change" = "steelblue")) +
  labs(
    x = "Repetition",
    y = "g (%)",
    color = "Context"
  ) +
  ggtitle("Guess Rate") +
  my_theme

# =========================
# Hybrid precision plot
# =========================

p_SD_hybrid <- ggplot() +
  geom_point(
    data = all_SD_ws_plot,
    aes(x = repetition, y = response),
    size = 4.5,
    color = "black"
  ) +
  geom_errorbar(
    data = all_SD_ws_plot,
    aes(x = repetition, ymin = lower_ws, ymax = upper_ws),
    width = 0.18,
    linewidth = 0.9,
    color = "black"
  ) +
  geom_point(
    data = ctx_SD_ws,
    aes(x = repetition, y = response, color = context),
    size = 5.5,
    position = position_dodge(width = 0.35)
  ) +
  geom_errorbar(
    data = ctx_SD_ws,
    aes(x = repetition, ymin = lower_ws, ymax = upper_ws, color = context),
    width = 0.08,
    linewidth = 1.0,
    position = position_dodge(width = 0.35)
  ) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    expand = expansion(mult = c(0.125, 0.15)),
    breaks = scales::breaks_width(1)
  ) +
  scale_color_manual(values = c("No Change" = "orange", "Change" = "steelblue")) +
  labs(
    x = "Repetition",
    y = "SD (°)",
    color = "Context"
  ) +
  ggtitle("Precision") +
  my_theme

# =========================
# Combine and save
# =========================

p_hybrid <- p_g_hybrid + p_SD_hybrid +
  plot_layout(guides = "collect") &
  theme(
    legend.position = "right",
    plot.title = element_text(hjust = 0.5, face = "bold", size = 28)
  )

print(p_hybrid)

ggsave(
  filename = "mixture_model_hybrid_test1_repetition_context_overlay.png",
  plot = p_hybrid,
  width = 13.52756,
  height = 8.090551,
  dpi = 300
)