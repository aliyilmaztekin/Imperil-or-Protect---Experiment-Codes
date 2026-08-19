## =========================================================================
## Experiment 4 — TCC d' results, hybrid-style figure
## (same style as the mixture-model figure: grey rep 1-6 baseline band/line,
##  black dots at every rep, black bars at reps 2/3/4/6, colored context dots
##  over reps 1 & 5, orange/blue/black palette, 12x7, bottom legend, A/B tags)
## =========================================================================

library(R.matlab)
library(dplyr)
library(ggplot2)
library(lme4)
library(lmerTest)     
library(emmeans)
library(Rmisc)         
library(patchwork)
library(scales)
library(showtext)
library(sysfonts)
library(car)
library(ggtext)

## ---- USER SETTINGS ------------------------------------------------------
## Which item(s) to analyze + plot. Both -> two panels side by side.
items   <- c("novel", "repeated")   # or "novel"  / "repeated" for a single panel
share_y <- FALSE                      # share one d' axis across panels (same units)

## ---- DATA ---------------------------------------------------------------
file          <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/tcc/imperil4_TCC_subjectwise_dprime.mat"
file_all_reps <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/experiment4/tcc/imperil4_TCC_subjectwise_dprime_all_reps.mat"

mat_15  <- R.matlab::readMat(file)            # reps 1 & 5, split by context
mat_all <- R.matlab::readMat(file_all_reps)   # reps 1-6, collapsed

combinedData          <- as.data.frame(mat_15$finalMatrix)
combinedData_all_reps <- as.data.frame(mat_all$finalMatrix)

colnames(combinedData)          <- c("subject", "repetition", "context", "dp1", "dp2")
colnames(combinedData_all_reps) <- c("subject", "repetition", "dp1", "dp2")

combinedData_sub <- combinedData %>%
  dplyr::mutate(
    subject    = factor(subject),
    repetition = factor(repetition, levels = c(1, 5), labels = c("1", "5")),
    context    = factor(context, levels = c(0, 1), labels = c("No Change", "Change"))
  )

combinedData_sub_all <- combinedData_all_reps %>%
  dplyr::mutate(
    subject    = factor(subject),
    repetition = factor(repetition, levels = 1:6, labels = c("1","2","3","4","5","6"))
  )

## ---- FONT ---------------------------------------------------------------
font_add(
  family     = "Arial",
  regular    = "/System/Library/Fonts/Supplemental/Arial.ttf",
  bold       = "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
  italic     = "/System/Library/Fonts/Supplemental/Arial Italic.ttf",
  bolditalic = "/System/Library/Fonts/Supplemental/Arial Bold Italic.ttf"
)
showtext_auto()
showtext_opts(dpi = 300)   # match ggsave() dpi so text isn't rendered tiny

## ---- HELPERS ------------------------------------------------------------
dp_col     <- function(item) if (item == "novel") "dp1" else "dp2"
item_title <- function(item) if (item == "novel") "Novel Item" else "Repeated Item"

# raw within-subject mean + Cousineau-Morey CI for the black baseline.
# Reps 2,3,4,6: pooled d' from the all-reps file.
# Reps 1 & 5:   collapse the two per-context d' fits over context, per subject,
#               so the black dot lands on the exact midpoint of the colored dots
#               (pooled TCC d' is a nonlinear refit, not the average of the
#                per-context fits, so it must not be used at reps 1 & 5).
build_baseline <- function(dp) {
  # pooled fits, all 6 reps
  pooled <- Rmisc::summarySEwithin(
    data = combinedData_sub_all, measurevar = dp,
    withinvars = "repetition", idvar = "subject", conf.interval = 0.95
  ) %>%
    dplyr::transmute(
      repetition = factor(repetition, levels = 1:6),
      response   = .data[[dp]],
      lower_ws   = .data[[dp]] - ci,
      upper_ws   = .data[[dp]] + ci
    )
  
  # collapsed-over-context fits, reps 1 & 5 only
  coll_15 <- combinedData_sub %>%
    dplyr::group_by(subject, repetition) %>%
    dplyr::summarise(!!dp := mean(.data[[dp]], na.rm = TRUE), .groups = "drop") %>%
    dplyr::mutate(repetition = droplevels(factor(repetition, levels = c(1, 5)))) %>%
    Rmisc::summarySEwithin(
      measurevar = dp, withinvars = "repetition",
      idvar = "subject", conf.interval = 0.95
    ) %>%
    dplyr::transmute(
      repetition = factor(as.character(repetition), levels = 1:6),
      response   = .data[[dp]],
      lower_ws   = .data[[dp]] - ci,
      upper_ws   = .data[[dp]] + ci
    )
  
  # splice: pooled for 2,3,4,6 + collapsed for 1,5
  dplyr::bind_rows(
    pooled %>% dplyr::filter(!repetition %in% c("1", "5")),
    coll_15
  ) %>%
    dplyr::arrange(as.numeric(as.character(repetition)))
}

# raw within-subject mean + CI, split by context (reps 1 & 5)
build_ctx <- function(dp) {
  Rmisc::summarySEwithin(
    data = combinedData_sub, measurevar = dp,
    withinvars = c("repetition", "context"), idvar = "subject", conf.interval = 0.95
  ) %>%
    dplyr::transmute(
      repetition = factor(repetition, levels = c(1, 5)),
      context    = factor(context, levels = c("No Change", "Change")),
      response   = .data[[dp]],
      lower_ws   = .data[[dp]] - ci,
      upper_ws   = .data[[dp]] + ci
    )
}

# inferential stats (reps 1 & 5 context model), printed per item
run_stats <- function(item) {
  dp <- dp_col(item)
  f  <- as.formula(paste0(dp, " ~ repetition * context + (1 | subject)"))
  m  <- lmer(f, data = combinedData_sub)
  cat("\n========== ", item_title(item), " ==========\n")
  print(car::Anova(m, type = 2, test.statistic = "F"))
  emm <- emmeans(m, ~ context | repetition)
  print(contrast(emm, method = "pairwise", infer = TRUE))
  invisible(m)
}

## ---- SHARED STYLE -------------------------------------------------------
x_levels <- c("1", "2", "3", "4", "5", "6")

pal <- c(
  "No Change"       = "orange",
  "Change"          = "steelblue",
  "Repetition only" = "black"
)

pd <- position_dodge(width = 0.65)

hybrid_theme <- theme_classic() +
  theme(
    plot.title       = element_text(size = 22, face = "bold", hjust = 0.5),
    legend.title     = element_blank(),
    legend.text      = element_text(size = 16),
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    axis.title.x = element_text(face = "bold", size = 20, margin = margin(t = 4)),
    axis.title.y = element_markdown(face = "bold", size = 20, margin = margin(r = 12)),
    axis.text.x  = element_text(size = 15, margin = margin(t = 8), color = "black"),
    axis.text.y  = element_text(size = 15, margin = margin(r = 8), color = "black"),
    axis.ticks.length = unit(0.3, "cm"),
    text = element_text(family = "Arial")
  )

make_panel <- function(item, ylim = NULL, show_y = TRUE, show_y_title = TRUE) {
  dp       <- dp_col(item)
  base     <- build_baseline(dp) %>% dplyr::mutate(rep_x = as.numeric(as.character(repetition)))
  base_pts <- base %>% dplyr::filter(!repetition %in% c("1", "5"))  # black bars only at 2,3,4,6
  ctx      <- build_ctx(dp)
  
  y_breaks <- if (!is.null(ylim)) {
    seq(floor(ylim[1] / 0.25) * 0.25,
        ceiling(ylim[2] / 0.25) * 0.25,
        by = 0.25)
  } else {
    scales::breaks_width(0.25)
  }
  
  p <- ggplot() +
    geom_ribbon(data = base,
                aes(x = rep_x, ymin = lower_ws, ymax = upper_ws),
                fill = "grey50", alpha = 0.15, inherit.aes = FALSE) +
    geom_line(data = base,
              aes(x = rep_x, y = response),
              color = "grey40", linewidth = 1, inherit.aes = FALSE) +
    geom_point(data = base_pts,
               aes(x = repetition, y = response, color = "Repetition only"),
               size = 4) +
    geom_errorbar(data = base_pts,
                  aes(x = repetition, ymin = lower_ws, ymax = upper_ws),
                  width = 0.2, linewidth = 1.0, color = "black") +
    geom_errorbar(data = ctx,
                  aes(x = repetition, ymin = lower_ws, ymax = upper_ws, color = context),
                  width = 0.4, linewidth = 1.0, position = pd) +
    geom_point(data = ctx,
               aes(x = repetition, y = response, color = context),
               size = 4, position = pd) +
    scale_x_discrete(limits = x_levels) +
    scale_y_continuous(breaks = y_breaks,
                       expand = expansion(mult = c(0.02, 0.02))) +
    scale_color_manual(values = pal,
                       breaks = c("No Change", "Change", "Repetition only")) +
    labs(x = "Repetition", y = "Memory Strength (d')", color = NULL) + 
    ggtitle(item_title(item)) +
    hybrid_theme +
    guides(color = guide_legend(override.aes = list(linetype = 0, shape = 16, size = 4)))
  
  
  if (!is.null(ylim)) p <- p + coord_cartesian(ylim = ylim)
  if (!show_y) {
    p <- p + theme(
      axis.title.y = element_blank(),
      axis.text.y  = element_blank(),
      axis.ticks.y = element_blank(),
      axis.line.y  = element_blank()
    )
  }
  if (!show_y_title) {
    p <- p + theme(axis.title.y = element_blank())
  }
  p
}

## ---- RUN STATS ----------------------------------------------------------
for (it in items) run_stats(it)

## ---- BUILD + COMBINE PANELS --------------------------------------------
# optional shared y-range across panels (same d' units)
ylim_shared <- NULL
if (share_y && length(items) > 1) {
  rngs <- lapply(items, function(it) {
    dp <- dp_col(it)
    b  <- build_baseline(dp); c <- build_ctx(dp)
    c(b$lower_ws, b$upper_ws, c$lower_ws, c$upper_ws)
  })
  yr <- range(unlist(rngs), na.rm = TRUE)
  pad <- diff(yr) * 0.08
  ylim_shared <- c(yr[1] - pad, yr[2] + pad)
}

panels   <- lapply(items, make_panel, ylim = ylim_shared)
drop_y   <- share_y && length(items) > 1   # redundant y-axis on shared-scale panels

## per-panel y-limits (NULL = auto-scale that panel)
ylim_by_item <- list(
  novel    = c(2.5, 3.5),   # Test 1 range
  repeated = c(2.0, 3.5)    # Test 2 range
)

plot_items <- rev(items)

panels <- Map(
  function(it, i) make_panel(
    it,
    ylim         = ylim_by_item[[it]],
    show_y       = !(drop_y && i > 1),
    show_y_title = (i == 1)
  ),
  plot_items, seq_along(plot_items)
)

p_hybrid <- wrap_plots(panels, nrow = 1) +
  plot_layout(guides = "collect", axis_titles = "collect_x") +  # one shared "Repetition"
  plot_annotation(tag_levels = "A") &
  theme(
    legend.position = "none",
    plot.tag = element_text(size = 18, face = "bold")
  )

print(p_hybrid)

## ---- SAVE ---------------------------------------------------------------
save_dest <- "/Users/ali/Desktop/Imperil-or-Protect---Experiment-Codes/figures"
dir.create(save_dest, recursive = TRUE, showWarnings = FALSE)

out_name <- if (length(items) == 1) {
  paste0("exp4_tcc_", items, ".png")
} else {
  "exp4_tcc_hybrid.png"
}

ggsave(
  filename = file.path(save_dest, out_name),
  plot   = p_hybrid,
  width  = if (length(items) == 1) 7 else 14,
  height = 7, units = "in",
  dpi    = 300
)