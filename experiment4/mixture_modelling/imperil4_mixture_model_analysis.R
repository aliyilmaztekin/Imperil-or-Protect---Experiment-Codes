library(tidyverse)
library(lme4)
library(lmerTest)  # gives p-values

# Read in CSV
df_test1 <- read.csv("/Users/ali/Desktop/visual imperil project/mixture_parameters_test1.csv")
df_test2 <- read.csv("/Users/ali/Desktop/visual imperil project/mixture_parameters_test2.csv")

# Make sure categorical variables are factors
df_test1 <- df_test1 %>%
  mutate(
    subject = factor(subject),
    repetition = factor(repetition),
    context = factor(context)
  )

df_test2 <- df_test2 %>%
  mutate(
    subject = factor(subject),
    repetition = factor(repetition),
    context = factor(context)
  )

# Keep only SD values in a reasonable range
df_test1_clean <- df_test1 %>%
  filter(SD > 0 & SD < 100)

df_test2_clean <- df_test2 %>%
  filter(SD > 0 & SD < 100)

summary(df_test1_clean$SD)
summary(df_test2_clean$SD)

# Test 1
m_SD_test1 <- lmer(SD ~ repetition * context + (1 | subject), data = df_test1_clean)
summary(m_SD_test1)
anova(m_SD_test1)

# Test 2
m_SD_test2 <- lmer(SD ~ repetition * context + (1 | subject), data = df_test2_clean)
summary(m_SD_test2)
anova(m_SD_test2)


