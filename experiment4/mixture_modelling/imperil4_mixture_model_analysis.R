library(tidyverse)
library(lmerTest)
library(emmeans)
library(dplyr)

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
descriptives <- df %>%
  group_by(repetition, context) %>%
  summarise(
    mean_g = mean(g),
    sd_g = sd(g),
    n_subj = n_distinct(subject),
    se = sd_g / sqrt(n_subj),
    .groups = "drop"
  )

print(descriptives)

# =========================
# Guess-rate model
# =========================
df <- df %>%
  mutate(logit_g = qlogis(g))

m_g <- lmer(logit_g ~ repetition * context + (1 | subject), data = df)

summary(m_g)
anova(m_g)

emm_ctx <- emmeans(m_g, ~ context | repetition)
pairs(emm_ctx)

# =========================
# Plot guess-rate interaction
# =========================
emm_g <- emmeans(m_g, ~ repetition * context)
emm_g_df <- as.data.frame(emm_g)

emm_g_df <- emm_g_df %>%
  mutate(
    mean_g = plogis(emmean),
    lower_g = plogis(emmean - 1.96 * SE),
    upper_g = plogis(emmean + 1.96 * SE)
  )

p_g <- ggplot(emm_g_df,
              aes(x = repetition, y = mean_g,
                  group = context, linetype = context, shape = context)) +
  geom_line(linewidth = 0.8, color = "black") +
  geom_point(size = 3, color = "black") +
  geom_errorbar(aes(ymin = lower_g, ymax = upper_g),
                width = 0.08, linewidth = 0.6, color = "black") +
  labs(
    x = "Repetition",
    y = "Estimated guess rate (g)",
    linetype = "Context",
    shape = "Context"
  ) +
  theme_classic(base_size = 13)

print(p_g)

# =========================
# SD descriptives / checks
# =========================
summary(df$SD)
hist(df$SD)

df_SD <- df %>%
  filter(is.finite(SD), SD > 0)

boxplot(df_SD$SD)

df_SD <- df_SD %>%
  mutate(logSD = log(SD))

# =========================
# SD model
# =========================
m_SD <- lmer(SD ~ repetition * context + (1 | subject), data = df_SD)

summary(m_SD)
anova(m_SD)

emm_SD_ctx <- emmeans(m_SD, ~ context | repetition)
pairs(emm_SD_ctx)



df_SD <- df %>%
  filter(is.finite(SD), SD > 0) %>%
  mutate(
    SD = (SD),
    repetition = factor(repetition, levels = c(1, 5)),
    context = factor(context, levels = c("No Change", "Change"))
  )

anova_SD <- aov_ez(
  id = "subject",
  dv = "SD",
  data = df_SD,
  within = c("repetition", "context"),
  type = 3
)

anova_SD




# =========================
# Plot SD interaction
# =========================
emm_SD <- emmeans(m_SD, ~ repetition * context)
emm_SD_df <- as.data.frame(emm_SD)

emm_SD_df <- emm_SD_df %>%
  mutate(
    mean_SD = exp(emmean),
    lower_SD = exp(emmean - 1.96 * SE),
    upper_SD = exp(emmean + 1.96 * SE)
  )

p_SD <- ggplot(emm_SD_df,
               aes(x = repetition, y = mean_SD,
                   group = context, linetype = context, shape = context)) +
  geom_line(linewidth = 0.8, color = "black") +
  geom_point(size = 3, color = "black") +
  geom_errorbar(aes(ymin = lower_SD, ymax = upper_SD),
                width = 0.08, linewidth = 0.6, color = "black") +
  labs(
    x = "Repetition",
    y = "Estimated SD",
    linetype = "Context",
    shape = "Context"
  ) +
  theme_classic(base_size = 13)

print(p_SD)



library(glmmTMB)
library(emmeans)

df_SD <- df %>%
  filter(is.finite(SD), SD > 0)

m_SD_gamma <- glmmTMB(
  SD ~ repetition * context + (1 | subject),
  data = df_SD,
  family = Gamma(link = "log")
)

summary(m_SD_gamma)
car::Anova(m_SD_gamma, type = 3)

df_g <- df %>%
  filter(is.finite(g), g > 0)

m_g_gamma <- glmmTMB(
  g ~ repetition * context + (1 | subject),
  data = df_g,
  family = Gamma(link = "log")
)

summary(m_g_gamma)










