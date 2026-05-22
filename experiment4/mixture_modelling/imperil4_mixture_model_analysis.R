library(tidyverse)
library(lmerTest)
library(emmeans)
library(dplyr)
library(afex)
afex_options(type = 3, check_contrasts = TRUE)

# =========================
# Load and prepare data
# =========================
df <- read.csv("/Users/ali/Desktop/visual imperil project/imperil4materials/mixture_parameters_rep1_rep5_test1_test2.csv") %>%
  mutate(
    subject = factor(subject),
    repetition = factor(repetition, levels = c(1, 5)),
    context = factor(context, levels = c(0, 1),
                     labels = c("No Change", "Change"))
  ) %>%
  filter(is.finite(g))

# =========================
# Guess-rate descriptives
# =========================

descriptives_g <- df %>%
  dplyr::group_by(repetition, context) %>%
  dplyr::summarise(
    mean_g = mean(g, na.rm = TRUE),
    sd_g = sd(g, na.rm = TRUE),
    n_subj = dplyr::n_distinct(subject),
    se_g = sd_g / sqrt(n_subj),
    .groups = "drop"
  )

print(descriptives_g)

# =========================
# Guess-rate model
# =========================

df_g <- df %>%
  dplyr::mutate(
    g_raw = g,
    g_model = pmin(pmax(g, 1e-4), 1 - 1e-4),
    logit_g = qlogis(g_model)
  ) %>%
  dplyr::filter(is.finite(logit_g))

m_g <- lmer(
  logit_g ~ repetition * context + (1 | subject),
  data = df_g
)

summary(m_g)
anova(m_g)

emm_ctx <- emmeans(m_g, ~ context | repetition)
pairs(emm_ctx)

emm_rep <- emmeans(m_g, ~ repetition | context)
pairs(emm_rep)

# =========================
# SD descriptives / checks
# =========================

summary(df$SD)
hist(df$SD)

df_SD <- df %>%
  dplyr::filter(is.finite(SD), SD > 0)

boxplot(df_SD$SD)

# =========================
# SD descriptives
# =========================

descriptives_SD <- df_SD %>%
  dplyr::group_by(repetition, context) %>%
  dplyr::summarise(
    mean_SD = mean(SD, na.rm = TRUE),
    sd_SD = sd(SD, na.rm = TRUE),
    n_subj = dplyr::n_distinct(subject),
    se_SD = sd_SD / sqrt(n_subj),
    .groups = "drop"
  )

print(descriptives_SD)

# =========================
# SD model: Gamma GLMM
# =========================

library(glmmTMB)

m_SD <- glmmTMB(
  SD ~ repetition * context + (1 | subject),
  data = df_SD,
  family = Gamma(link = "log")
)

summary(m_SD)
car::Anova(m_SD, type = 3)

emm_SD_ctx <- emmeans(m_SD, ~ context | repetition, type = "response")
pairs(emm_SD_ctx)

emm_SD_rep <- emmeans(m_SD, ~ repetition | context, type = "response")
pairs(emm_SD_rep)

# =========================
# Mixture model plots: EMM CIs
# =========================

library(tidyverse)
library(emmeans)
library(patchwork)

# Guess-rate plot data: EMMs
ctx_g <- as.data.frame(confint(emmeans(m_g, ~ repetition * context))) %>%
  dplyr::mutate(
    response = plogis(emmean),
    lower = plogis(lower.CL),
    upper = plogis(upper.CL)
  )

# SD plot data: EMMs
ctx_SD <- as.data.frame(emmeans(m_SD, ~ repetition * context, type = "response"))

if ("lower.CL" %in% names(ctx_SD)) {
  ctx_SD <- ctx_SD %>%
    dplyr::rename(lower = lower.CL, upper = upper.CL)
} else {
  ctx_SD <- ctx_SD %>%
    dplyr::rename(lower = asymp.LCL, upper = asymp.UCL)
}

x_levels <- c("1", "5")

# Shared theme
my_theme <- theme_classic() +
  theme(
    plot.title = element_text(size = 28),
    legend.title = element_blank(),
    legend.text = element_text(size = 28),
    legend.position = "none",
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    axis.title.x = element_text(
      face = "bold",
      size = 28,
      margin = margin(t = 4)
    ),
    axis.title.y = element_text(
      face = "bold",
      size = 28,
      margin = margin(r = 12)
    ),
    axis.text.x = element_text(
      size = 28,
      margin = margin(t = 8),
      color = "black"
    ),
    axis.text.y = element_text(
      size = 28,
      margin = margin(r = 8),
      color = "black"
    ),
    axis.ticks.length = unit(0.2, "cm"),
    text = element_text(family = "Arial")
  )

# Guess-rate figure: EMM CIs
p_g <- ggplot() +
  geom_point(
    data = ctx_g,
    aes(x = repetition, y = response, color = context),
    size = 5
  ) +
  geom_errorbar(
    data = ctx_g,
    aes(x = repetition, ymin = lower, ymax = upper, color = context),
    width = 0.3,
    linewidth = 1.0
  ) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 0.5),
    breaks = seq(0, 0.06, 0.01),
    expand = expansion(mult = c(0.05, 0.1))
  ) +
  coord_cartesian(ylim = c(0, 0.06)) +
  scale_color_manual(values = c("No Change" = "orange", "Change" = "steelblue")) +
  labs(
    x = "Repetition",
    y = "g (%)",
    color = "Context"
  ) +
  ggtitle("Guess Rate") +
  my_theme

# SD figure: EMM CIs
p_SD <- ggplot() +
  geom_point(
    data = ctx_SD,
    aes(x = repetition, y = response, color = context),
    size = 5
  ) +
  geom_errorbar(
    data = ctx_SD,
    aes(x = repetition, ymin = lower, ymax = upper, color = context),
    width = 0.3,
    linewidth = 1.0
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

p_mixture <- p_g + p_SD +
  plot_layout(guides = "collect") &
  theme(
    legend.position = "right",
    plot.title = element_text(
      hjust = 0.5,
      face = "bold",
      size = 28
    )
  )

print(p_mixture)

ggsave(
  filename = "mixture_model_results_FINAL.png",
  plot = p_mixture,
  width = 13.52756,
  height = 8.090551,
  dpi = 300
)

# =========================
# Mixture model plots: EMM points + within-subject CI widths
# =========================

library(Rmisc)

# Guess-rate WS CI widths, computed on raw g scale
ws_g_df <- df_g %>%
  dplyr::group_by(subject, repetition, context) %>%
  dplyr::summarise(
    g_mean = mean(g_raw, na.rm = TRUE),
    .groups = "drop"
  )

ws_g <- Rmisc::summarySEwithin(
  data = ws_g_df,
  measurevar = "g_mean",
  withinvars = c("repetition", "context"),
  idvar = "subject",
  conf.interval = 0.95
) %>%
  dplyr::select(repetition, context, ci_g = ci)

# SD WS CI widths, computed on raw SD scale
ws_SD_df <- df_SD %>%
  dplyr::group_by(subject, repetition, context) %>%
  dplyr::summarise(
    SD_mean = mean(SD, na.rm = TRUE),
    .groups = "drop"
  )

ws_SD <- Rmisc::summarySEwithin(
  data = ws_SD_df,
  measurevar = "SD_mean",
  withinvars = c("repetition", "context"),
  idvar = "subject",
  conf.interval = 0.95
) %>%
  dplyr::select(repetition, context, ci_SD = ci)

# Attach WS CI widths to original EMM point estimates
ctx_g_ws <- ctx_g %>%
  dplyr::left_join(ws_g, by = c("repetition", "context")) %>%
  dplyr::mutate(
    lower_ws = pmax(0, response - ci_g),
    upper_ws = pmin(1, response + ci_g)
  )

ctx_SD_ws <- ctx_SD %>%
  dplyr::left_join(ws_SD, by = c("repetition", "context")) %>%
  dplyr::mutate(
    lower_ws = response - ci_SD,
    upper_ws = response + ci_SD
  )

# Guess-rate figure: same EMM points, WS error bars
p_g_ws <- ggplot() +
  geom_point(
    data = ctx_g_ws,
    aes(x = repetition, y = response, color = context),
    size = 5
  ) +
  geom_errorbar(
    data = ctx_g_ws,
    aes(x = repetition, ymin = lower_ws, ymax = upper_ws, color = context),
    width = 0.3,
    linewidth = 1.0
  ) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(
    labels = scales::percent_format(accuracy = 0.5),
    breaks = seq(0, 0.06, 0.01),
    expand = expansion(mult = c(0.05, 0.1))
  ) +
  coord_cartesian(ylim = c(0, 0.06)) +
  scale_color_manual(values = c("No Change" = "orange", "Change" = "steelblue")) +
  labs(
    x = "Repetition",
    y = "g (%)",
    color = "Context"
  ) +
  ggtitle("Guess Rate") +
  my_theme

# SD figure: same EMM points, WS error bars
p_SD_ws <- ggplot() +
  geom_point(
    data = ctx_SD_ws,
    aes(x = repetition, y = response, color = context),
    size = 5
  ) +
  geom_errorbar(
    data = ctx_SD_ws,
    aes(x = repetition, ymin = lower_ws, ymax = upper_ws, color = context),
    width = 0.3,
    linewidth = 1.0
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

p_mixture_ws <- p_g_ws + p_SD_ws +
  plot_layout(guides = "collect") &
  theme(
    legend.position = "right",
    plot.title = element_text(
      hjust = 0.5,
      face = "bold",
      size = 28
    )
  )

print(p_mixture_ws)

ggsave(
  filename = "mixture_model_results_EMM_POINTS_WITHIN_SUBJECT_CIs.png",
  plot = p_mixture_ws,
  width = 13.52756,
  height = 8.090551,
  dpi = 300
)























