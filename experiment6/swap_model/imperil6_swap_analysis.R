library(tidyverse)
library(lmerTest)
library(emmeans)
library(glmmTMB)
library(patchwork)
library(Rmisc)
library(performance)
library(car)
library(dplyr)
library(lmerTest)
library(emmeans)
library(car)
library(Rmisc)
library(ggplot2)
library(scales)
library(cowplot)


exp_handle <- 6
probedItem <- "old1" # "old1, old2 or novel in exp6"
swap_col <- "swap"

data_csv <- sprintf(
  "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment6/swap_model/param_out/exp_6_swap_full_model.csv",
  exp_handle, exp_handle
)

df_ctx <- read.csv(data_csv) %>%
  dplyr::mutate(
    subject      = factor(subject),
    repetition   = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context      = factor(context, levels = c(0, 1),
                          labels = c("No Change", "Change"))
  ) %>%
  dplyr::filter(is.finite(g), is.finite(SD), SD > 0,
                is.finite(.data[[swap_col]]))

df_ctx_g <- df_ctx %>%
  dplyr::mutate(
    g_raw   = g,
    logit_g = qlogis(g_raw)
  )

df_ctx_swap <- df_ctx_g %>%
  dplyr::mutate(
    swap_raw   = .data[[swap_col]],

    logit_swap = qlogis(swap_raw)
  )

df_ctx_SD <- df_ctx_g %>% dplyr::filter(is.finite(SD), SD > 0, SD < 100)

# Filter the data down to trials where the specified probe was tested
df_ctx_g <- df_ctx_g %>% dplyr::filter(probe == dplyr::case_when(
  probedItem == "old1" || probedItem == "old2" ~ 1,
  probedItem == "novel" ~ 2
))

df_ctx_SD <- df_ctx_SD %>% dplyr::filter(probe == dplyr::case_when(
  probedItem == "old1" || probedItem == "old2" ~ 1,
  probedItem == "novel" ~ 2
))

df_ctx_swap <- df_ctx_swap %>% dplyr::filter(probe == dplyr::case_when(
  probedItem == "old1" || probedItem == "old2" ~ 1,
  probedItem == "novel" ~ 2
))

df_rep <- read.csv(data_csv_allreps) %>%
  dplyr::mutate(
    subject    = factor(subject),
    repetition = factor(repetition, levels = 1:6,
                        labels = c("1", "2", "3", "4", "5", "6"))
  ) %>%
  dplyr::filter(is.finite(g), is.finite(SD), SD > 0,
                is.finite(.data[[swap_col]])) %>%
  dplyr::mutate(
    g_model    = pmin(pmax(g, 1e-4), 1 - 1e-4),
    logit_g    = qlogis(g_model),
    swap_model = pmin(pmax(.data[[swap_col]], 1e-4), 1 - 1e-4),
    logit_swap = qlogis(swap_model)
  )

df_rep_SD <- df_rep %>% dplyr::filter(SD < 100)   

m_SD_ctx <- lmerTest::lmer(
  SD ~ repetition * context  + (1 | subject),
  data = df_ctx_SD
)

print(car::Anova(m_SD_ctx, type = 3, test.statistic = "F"))

emms_SD <- emmeans(m_SD_ctx, ~  context)
print(contrast(emms_SD, method = "pairwise", infer = TRUE))

m_g_ctx <- lmerTest::lmer(
  logit_g ~ repetition * context  +
    (1 | subject),
  data = df_ctx_g
)
print(car::Anova(m_g_ctx, type = 3, test.statistic = "F"))

emms_g <- emmeans(ref_grid(m_g_ctx, tran = "logit"),
                  ~ repetition , type = "response")
print(contrast(emms_g, method = "pairwise", infer = TRUE))

m_swap_ctx <- lmerTest::lmer(
  logit_swap ~ repetition * context + (1 | subject),
  data = df_ctx_swap
)

print(car::Anova(m_swap_ctx, type = 3, test.statistic = "F"))

