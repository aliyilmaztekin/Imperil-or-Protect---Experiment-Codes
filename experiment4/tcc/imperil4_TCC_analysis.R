library(R.matlab)
library(dplyr)
library(grid)
library(showtext)
library(sysfonts)


file <- "/Users/ali/Desktop/imperil4_TCC_subjectwise_dprime.mat"

mat <- R.matlab::readMat(file)

names(mat)  # check variable names inside the .mat file

combinedData <- as.data.frame(mat$finalMatrix)

colnames(combinedData) <- c(
  "subject", "repetition", "context", "dp1", "dp2"
)

combinedData_sub <- combinedData %>%
  mutate(
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context = factor(context, levels = c(0, 1), labels = c("No Change", "Change"))
  )


library(afex)
library(dplyr)
library(emmeans)
library(ggplot2)

combinedData_sub <- combinedData_sub %>%
  mutate(
    subject = factor(subject),
    repetition = factor(repetition),
    context = factor(context)
  )

anova_dp1 <- aov_ez(
  id = "subject",
  dv = "dp1",
  data = combinedData_sub,
  within = c("repetition", "context"),
  type = 3
)

anova_dp1

anova_dp2 <- aov_ez(
  id = "subject",
  dv = "dp2",
  data = combinedData_sub,
  within = c("repetition", "context"),
  type = 3
)

anova_dp2

qqnorm(resid(anova_dp1))
qqline(resid(anova_dp1))


emm <- emmeans(anova_dp1, ~ context | repetition)
pairs(emm)

emm <- emmeans(anova_dp2, ~ context | repetition)
pairs(emm)


library(lme4)
library(lmerTest)
library(emmeans)
library(cowplot)

mod_dp1 <- lmer(
  dp1 ~ repetition * context + (1 | subject),
  data = combinedData_sub
)

summary(mod_dp1)
anova(mod_dp1)

emm_dp1 <- emmeans(mod_dp1, ~ context | repetition)
pairs(emm_dp1)


## Plot the results
emm_plot <- emmeans(mod_dp1, ~ repetition * context)
emm_df <- as.data.frame(confint(emm_plot))

star_y = emm_df$emmean[4] + (emm_df$emmean[2] - emm_df$emmean[4])/2

library(showtext)
library(sysfonts)

font_add(
  family = "Arial",
  regular = "/System/Library/Fonts/Supplemental/Arial.ttf",
  bold    = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
)

showtext_auto()

library(Rmisc)

## Within-subjects d'prime

ws_dp1 <- Rmisc::summarySEwithin(
  data = combinedData_sub,
  measurevar = "dp1",
  withinvars = c("repetition", "context"),
  idvar = "subject",
  conf.interval = 0.95
) %>%
  dplyr::select(
    repetition,
    context,
    ws_mean = dp1,
    ws_ci = ci
  )

emm_df <- emm_df %>%
  left_join(ws_dp1, by = c("repetition", "context")) %>%
  mutate(
    ws_lower = emmean - ws_ci,
    ws_upper = emmean + ws_ci
  )

plot2save_base <- ggplot(
  emm_df,
  aes(
    x = factor(repetition),
    y = emmean,
    color = context,
    group = context
  )
) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 3) +
  geom_errorbar(
    aes(ymin = ws_lower, ymax = ws_upper),
    width = 0.1,
    linewidth = 0.8
  ) +
  annotate(
    "text",
    x = 2.15,
    y = star_y,
    label = "*",
    fontface = "bold",
    color = "red",
    size = 11
  ) +
  scale_color_manual(values = c("No Change" = "orange", "Change" = "steelblue")) +
  labs(
    title = "Imperil 4 - TCC Results",
    x = "Repetition",
    y = "Memory Strength (d')",
    color = "Context"
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0.125, 0.20)),
    breaks = scales::breaks_width(0.10)
  ) +
  theme_classic() +
  theme(
    legend.title = element_blank(),
    legend.text = element_text(size = 10),
    plot.background = element_rect(fill = "white"),
    panel.background = element_rect(fill = "white"),
    axis.title.x = element_text(
      face = "bold",
      size = 16,
      margin = margin(t = 4)
    ),
    axis.title.y = element_text(
      face = "bold",
      size = 16,
      margin = margin(r = 12)
    ),
    axis.text.x = element_text(
      size = 14,
      margin = margin(t = 8),
      color = "black"
    ),
    axis.text.y = element_text(
      size = 14,
      margin = margin(r = 8),
      color = "black"
    ),
    axis.ticks.length = unit(0.2, "cm"),
    text = element_text(family = "Arial"),
    plot.title = element_text(
      face = "bold",
      size = 18,
      hjust = 0.6,
      margin = margin(b = 10)
    )
  )

library(cowplot)
library(grid)


plot2save <- ggdraw(plot2save_base) +
  draw_grob(
    roundrectGrob(
      x = 0.87,
      y = 0.88,
      width = 0.25,
      height = 0.09,
      r = unit(0.02, "npc"),
      gp = gpar(fill = "white", col = "black", lwd = 1)
    )
  ) +
  draw_label(
    "Repetition: p < .000\nInteraction: p = .049",
    x = 0.87,
    y = 0.88,
    hjust = 0.5,
    vjust = 0.5,
    fontface = "bold",
    fontfamily = "Arial",
    size = 12,
    color = "black",
    lineheight = 0.9
  ) +
  draw_grob(
    roundrectGrob(
      x = 0.75,
      y = 0.65,
      width = 0.10,
      height = 0.05,
      r = unit(0.02, "npc"),
      gp = gpar(fill = "white", col = "black", lwd = 1)
      )
  ) +
    draw_label(
      "p = .004",
      x = 0.75,
      y = 0.65,
      hjust = 0.5,
      vjust = 0.5,
      fontface = "bold",
      fontfamily = "Arial",
      size = 12,
      color = "black"
  )

plot2save






