

library(tidyverse)
library(lmerTest)
library(emmeans)
library(afex)
library(glmmTMB)
library(patchwork)

afex_options(type = 3, check_contrasts = TRUE)

# =========================
# Load and prepare data
# =========================

df <- read.csv("/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/mixture_modelling/mixture_parameters_all_repetitions_test1_test2.csv") %>%
  mutate(
    subject = factor(subject),
    test = factor(test, levels = c(1, 2),
                  labels = c("Test 1", "Test 2")),
    repetition = factor(repetition, levels = 1:6)
  ) %>%
  filter(is.finite(g), is.finite(SD))

# =========================
# Guess-rate preprocessing
# =========================

df_g <- df %>%
  mutate(
    g_raw = g,
    g_model = pmin(pmax(g, 1e-4), 1 - 1e-4),
    logit_g = qlogis(g_model)
  ) %>%
  filter(is.finite(logit_g))

# =========================
# SD preprocessing
# =========================

df_SD <- df %>%
  filter(is.finite(SD), SD > 0)

# =========================
# Split Test 1 and Test 2
# =========================

df_g_t1 <- df_g %>% filter(test == "Test 1")
df_g_t2 <- df_g %>% filter(test == "Test 2")

df_SD_t1 <- df_SD %>% filter(test == "Test 1")
df_SD_t2 <- df_SD %>% filter(test == "Test 2")

# =========================
# Guess-rate models
# =========================

m_g_t1 <- lmer(
  logit_g ~ repetition + (1 | subject),
  data = df_g_t1
)

m_g_t2 <- lmer(
  logit_g ~ repetition + (1 | subject),
  data = df_g_t2
)

summary(m_g_t1)
anova(m_g_t1)

summary(m_g_t2)
anova(m_g_t2)

emm_g_t1 <- emmeans(m_g_t1, ~ repetition)
pairs(emm_g_t1)

emm_g_t2 <- emmeans(m_g_t2, ~ repetition)
pairs(emm_g_t2)

# =========================
# SD models
# =========================

m_SD_t1 <- glmmTMB(
  SD ~ repetition + (1 | subject),
  data = df_SD_t1,
  family = Gamma(link = "log")
)

m_SD_t2 <- glmmTMB(
  SD ~ repetition + (1 | subject),
  data = df_SD_t2,
  family = Gamma(link = "log")
)

summary(m_SD_t1)
car::Anova(m_SD_t1, type = 3)

summary(m_SD_t2)
car::Anova(m_SD_t2, type = 3)

emm_SD_t1 <- emmeans(m_SD_t1, ~ repetition, type = "response")
pairs(emm_SD_t1)

emm_SD_t2 <- emmeans(m_SD_t2, ~ repetition, type = "response")
pairs(emm_SD_t2)

# =========================
# Plot data (EMMs)
# =========================

ctx_g_t1 <- as.data.frame(confint(emmeans(m_g_t1, ~ repetition))) %>%
  mutate(
    test = "Test 1",
    response = plogis(emmean),
    lower = plogis(lower.CL),
    upper = plogis(upper.CL)
  )

ctx_g_t2 <- as.data.frame(confint(emmeans(m_g_t2, ~ repetition))) %>%
  mutate(
    test = "Test 2",
    response = plogis(emmean),
    lower = plogis(lower.CL),
    upper = plogis(upper.CL)
  )

ctx_g <- bind_rows(ctx_g_t1, ctx_g_t2)

ctx_SD_t1 <- as.data.frame(emmeans(m_SD_t1, ~ repetition, type = "response")) %>%
  mutate(test = "Test 1")

ctx_SD_t2 <- as.data.frame(emmeans(m_SD_t2, ~ repetition, type = "response")) %>%
  mutate(test = "Test 2")

ctx_SD <- bind_rows(ctx_SD_t1, ctx_SD_t2)

if ("lower.CL" %in% names(ctx_SD)) {
  ctx_SD <- ctx_SD %>%
    dplyr::rename(lower = lower.CL, upper = upper.CL)
} else if ("asymp.LCL" %in% names(ctx_SD)) {
  ctx_SD <- ctx_SD %>%
    dplyr::rename(lower = asymp.LCL, upper = asymp.UCL)
}

x_levels <- as.character(1:6)

# =========================
# Shared theme
# =========================

my_theme <- theme_classic() +
  theme(
    plot.title = element_text(size = 28),
    legend.title = element_blank(),
    legend.text = element_text(size = 24),
    legend.position = "none",
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    axis.title.x = element_text(face = "bold", size = 28),
    axis.title.y = element_text(face = "bold", size = 28),
    axis.text.x = element_text(size = 24, color = "black"),
    axis.text.y = element_text(size = 24, color = "black"),
    text = element_text(family = "Arial")
  )

# =========================
# Guess-rate plot
# =========================

p_g <- ggplot(ctx_g, aes(x = repetition, y = response, group = test, color = test)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 5) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.5)) +
  labs(x = "Repetition", y = "g (%)", color = "Test") +
  ggtitle("Guess Rate") +
  my_theme

# =========================
# SD plot
# =========================

p_SD <- ggplot(ctx_SD, aes(x = repetition, y = response, group = test, color = test)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 5) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2) +
  scale_x_discrete(limits = x_levels) +
  labs(x = "Repetition", y = "SD (°)", color = "Test") +
  ggtitle("Precision") +
  my_theme

# =========================
# Combine plots
# =========================

p_mixture <- p_g + p_SD +
  plot_layout(guides = "collect") &
  theme(
    legend.position = "right",
    plot.title = element_text(hjust = 0.5, face = "bold", size = 28)
  )

print(p_mixture)

ggsave(
  filename = "mixture_model_results_repetition_1_to_6_separate_tests.png",
  plot = p_mixture,
  width = 13.5,
  height = 8.1,
  dpi = 300
)






# =========================
# Separate plots by test
# =========================

p_g_t1 <- ggplot(ctx_g %>% filter(test == "Test 1"),
                 aes(x = repetition, y = response, group = 1)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 5) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.5)) +
  labs(x = "Repetition", y = "g (%)") +
  ggtitle("Guess Rate - Test 1") +
  my_theme

p_SD_t1 <- ggplot(ctx_SD %>% filter(test == "Test 1"),
                  aes(x = repetition, y = response, group = 1)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 5) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2) +
  scale_x_discrete(limits = x_levels) +
  labs(x = "Repetition", y = "SD (°)") +
  ggtitle("Precision - Test 1") +
  my_theme

p_g_t2 <- ggplot(ctx_g %>% filter(test == "Test 2"),
                 aes(x = repetition, y = response, group = 1)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 5) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2) +
  scale_x_discrete(limits = x_levels) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 0.5)) +
  labs(x = "Repetition", y = "g (%)") +
  ggtitle("Guess Rate - Test 2") +
  my_theme

p_SD_t2 <- ggplot(ctx_SD %>% filter(test == "Test 2"),
                  aes(x = repetition, y = response, group = 1)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 5) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2) +
  scale_x_discrete(limits = x_levels) +
  labs(x = "Repetition", y = "SD (°)") +
  ggtitle("Precision - Test 2") +
  my_theme

# Test 1 only
p_test1 <- p_g_t1 + p_SD_t1

print(p_test1)

ggsave(
  filename = "mixture_model_results_test1_only.png",
  plot = p_test1,
  width = 13.5,
  height = 8.1,
  dpi = 300
)

# Test 2 only
p_test2 <- p_g_t2 + p_SD_t2

print(p_test2)

ggsave(
  filename = "mixture_model_results_test2_only.png",
  plot = p_test2,
  width = 13.5,
  height = 8.1,
  dpi = 300
)



