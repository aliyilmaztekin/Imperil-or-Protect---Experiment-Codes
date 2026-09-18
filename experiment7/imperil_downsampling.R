library(R.matlab)
library(dplyr)
library(tidyr)
library(afex)
options(scipen = 999) 

options(scipen = 999)  # Avoid scientific notation

base_dir <- "/Users/ali/Desktop/visual imperil project/imperil4materials/behavioral_data_exp4/"

files <- list.files(base_dir, pattern = "\\.mat$", full.names = TRUE)

dfs <- lapply(files, function(f) {
  mat <- R.matlab::readMat(f)
  as.data.frame(mat$outputMatrix)
})

combinedData <- bind_rows(dfs)
colnames(combinedData) <- c(
  "subject", "conditionUsed", "block", "trial", "repetition",
  "context", "contextCode", "primaryColor", "secondaryColor",
  "absError", "initiation_time1", "movement_time1", "rt1",
  "angle2", "initiation_time2", "movement_time2", "rt2",
  "breakTaken", "conditions"
)

combinedData$absError = abs(combinedData$absError)
  
## Randomly sample slices off the data
## Sample k trials from each condition in each participant
## Do that for each sampSize
sampleSizes <- seq(from = 5, to = 35 , by = 5)
allSbjs = sort(unique(combinedData$subject))
pes <- data_frame()
simPes <- data_frame()
simRound <- 100

for (sim in 1:simRound) { 
  template <- tibble(id = 1:length(sampleSizes), values = NA_real_)
  
  globalTib <- tibble(
    sbj   = seq_along(allSbjs),
    cond1 = list(template),
    cond2 = list(template),
    cond3 = list(template),
    cond4 = list(template)
  )
  
  sampCount <- 0
  for (sampSize in sampleSizes) {
    sbjCount <- 0
    sampCount <- sampCount + 1
    
    for (sbj in allSbjs) {
      sbjCount = sbjCount + 1
      
      # Slice the data-set into the rows of the current subject
      curDF <- combinedData[combinedData$subject == sbj, ]
      
      # Locate all the experimental trials
      condIdx <- tibble(id = 1:4, 
        values = 
        list(which(curDF$repetition == 1 & curDF$context == 0),
        which(curDF$repetition == 1 & curDF$context == 1),
        which(curDF$repetition == 5 & curDF$context == 0),
        which(curDF$repetition == 5 & curDF$context == 1))
      )
      
      # Down-sample the indices to the current sample size, then pull out the outcome values
      downCondIdx <- list(id = 1:4, values = list(
        curDF$absError[sample(condIdx$values[[1]], size = sampSize, replace = FALSE)],
        curDF$absError[sample(condIdx$values[[2]], size = sampSize, replace = FALSE)],
        curDF$absError[sample(condIdx$values[[3]], size = sampSize, replace = FALSE)],
        curDF$absError[sample(condIdx$values[[4]], size = sampSize, replace = FALSE)])
      )
      
      # Append to the global data container
      globalTib$cond1[[sbjCount]]$values[sampCount] = list(values = downCondIdx$values[[1]][])
      globalTib$cond2[[sbjCount]]$values[sampCount] = list(values = downCondIdx$values[[2]][])
      globalTib$cond3[[sbjCount]]$values[sampCount] = list(values = downCondIdx$values[[3]][])
      globalTib$cond4[[sbjCount]]$values[sampCount] = list(values = downCondIdx$values[[4]][])
    }
  }
  
  for (k in 1:length(sampleSizes)){
    DF2analyze <- data_frame()
    for (subject in 1:length(allSbjs)) {
      curTemp <- data_frame(
        cond1 = globalTib$cond1[[subject]]$values[k],
        cond2 = globalTib$cond2[[subject]]$values[k],
        cond3 = globalTib$cond3[[subject]]$values[k],
        cond4 = globalTib$cond4[[subject]]$values[k],
        subject = rep(subject,length(cond1)*4)
      )
      DF2analyze <- dplyr::bind_rows(DF2analyze, curTemp) 
    } 
    
    DF2analyze <- DF2analyze %>%
      tidyr::pivot_longer(
        cols = starts_with("cond"),
        names_to = "Condition",
        values_to = "absError"
      ) 
    
    DF2analyze <- DF2analyze %>% dplyr::mutate(
        repetition = rep(c(1,1,5,5),nrow(DF2analyze)/4),
        context = rep(c(0,1,0,1),nrow(DF2analyze)/4)
      ) %>%
      dplyr::select(
        -Condition
      ) %>%
      dplyr::relocate(
        repetition, context, .after = subject
      ) %>%
      tidyr::unnest(absError) %>%
      dplyr::group_by(subject, repetition, context) %>%
      dplyr::summarise(
        absError = mean(absError, na.rm = TRUE),
        .groups = "drop"
      )
    
    ## Conduct the analysis on the slice
    anovaMod <- afex::aov_ez(
      id = "subject",
      dv = "absError",
      data = DF2analyze,
      within = c("repetition", "context"),
      fun_aggregate = mean
    )
    
    anovaTable <- as.data.frame(anova(anovaMod, es = "pes"))
    
    pes[k,1] <- anovaTable$pes[3]
   
  }
  if (sim == 1) {
    simPes <- pes
  } else {
    simPes <- dplyr::bind_cols(simPes, pes, .name_repair = "unique_quiet")
  }
   
}



library(dplyr)
library(tidyr)
library(tibble)
library(ggplot2)

## --- 1. Long format ---------------------------------------------------------
## bind_cols with .name_repair = "unique_quiet" leaves messy column names,
## so go via a matrix and transpose: rows become sims, cols become sample sizes.

pesLong <- simPes %>%
  as.matrix() %>%
  t() %>%
  as_tibble(.name_repair = "minimal") %>%
  setNames(as.character(sampleSizes)) %>%
  mutate(sim = row_number()) %>%
  pivot_longer(-sim, names_to = "sampleSize", values_to = "pes") %>%
  mutate(sampleSize = factor(as.integer(sampleSize), levels = sampleSizes))

## --- 2. Summary + bootstrap CI on the SD ------------------------------------

bootStat <- function(x, FUN = sd, B = 5000, probs = c(.025, .975)) {
  force(x)
  FUN <- match.fun(FUN)
  reps <- vapply(
    seq_len(B),
    function(i) FUN(sample(x, length(x), replace = TRUE)),
    numeric(1)
  )
  as.numeric(quantile(reps, probs, na.rm = TRUE))
}

pesSummary <- pesLong %>%
  group_by(sampleSize) %>%
  summarise(
    nSim    = n(),
    mean    = mean(pes),
    median  = median(pes),
    sd      = sd(pes),
    iqr     = IQR(pes),
    lo95    = quantile(pes, .025),
    hi95    = quantile(pes, .975),
    sdLo    = bootStat(pes, sd)[1],
    sdHi    = bootStat(pes, sd)[2],
    .groups = "drop"
  )

print(pesSummary, width = Inf)

## Formal check that spread differs across trial counts
print(fligner.test(pes ~ sampleSize, data = pesLong))   # robust to non-normality
print(bartlett.test(pes ~ sampleSize, data = pesLong))  # sensitive, assumes normality

## --- 3. Plot A: full distribution of pes at each trial count -----------------

pA <- ggplot(pesLong, aes(x = sampleSize, y = pes, fill = sampleSize)) +
  geom_violin(colour = NA, alpha = .35, trim = FALSE, scale = "width") +
  geom_boxplot(width = .13, outlier.shape = NA, fill = "white", alpha = .9) +
  stat_summary(fun = mean, geom = "point", shape = 23,
               size = 2.6, fill = "black", colour = "white") +
  scale_fill_viridis_d(guide = "none", option = "D", end = .85) +
  labs(
    x = "Trials sampled per condition",
    y = expression(paste("Partial ", eta^2, " (repetition x context)")),
    title = "Sampling distribution of the interaction effect size",
    subtitle = sprintf("%d simulated down-samples, %d subjects",
                       max(pesLong$sim), length(allSbjs))
  ) +
  theme_minimal(base_size = 13) +
  theme(panel.grid.major.x = element_blank())

## --- 4. Plot B: the actual question — does spread shrink with trial count? ---

pB <- ggplot(pesSummary, aes(x = as.integer(as.character(sampleSize)), y = sd)) +
  geom_ribbon(aes(ymin = sdLo, ymax = sdHi), alpha = .18, fill = "steelblue") +
  geom_line(colour = "steelblue", linewidth = .9) +
  geom_point(size = 2.8, colour = "steelblue") +
  scale_x_continuous(breaks = sampleSizes) +
  expand_limits(y = 0) +
  labs(
    x = "Trials sampled per condition",
    y = expression(paste("SD of partial ", eta^2)),
    title = "Simulation-to-simulation variability of the effect size",
    subtitle = "Ribbon = bootstrap 95% CI on the SD"
  ) +
  theme_minimal(base_size = 13)

## --- 5. Plot C: overlaid densities + ECDF -----------------------------------

pC <- ggplot(pesLong, aes(x = pes, colour = sampleSize, fill = sampleSize)) +
  geom_density(alpha = .12, linewidth = .8, adjust = 1.1) +
  scale_colour_viridis_d(name = "Trials/cond", option = "D", end = .85) +
  scale_fill_viridis_d(guide = "none", option = "D", end = .85) +
  labs(x = expression(paste("Partial ", eta^2)), y = "Density",
       title = "Overlaid sampling distributions") +
  theme_minimal(base_size = 13)

pD <- ggplot(pesLong, aes(x = pes, colour = sampleSize)) +
  stat_ecdf(linewidth = .8) +
  scale_colour_viridis_d(name = "Trials/cond", option = "D", end = .85) +
  labs(x = expression(paste("Partial ", eta^2)), y = "Cumulative proportion",
       title = "Empirical CDF") +
  theme_minimal(base_size = 13)

## --- 6. Plot E: paired view — each sim as a connected line ------------------
## Only meaningful if the same sim index used a common random state;
## with independent draws per sample size this is a spaghetti plot of noise,
## which is itself informative about how unstable a single run is.

pE <- ggplot(pesLong, aes(x = sampleSize, y = pes, group = sim)) +
  geom_line(alpha = .04) +
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               colour = "firebrick", linewidth = 1.1) +
  stat_summary(aes(group = 1), fun = mean, geom = "point",
               colour = "firebrick", size = 2.4) +
  labs(x = "Trials sampled per condition",
       y = expression(paste("Partial ", eta^2)),
       title = "Individual simulation trajectories",
       subtitle = "Red = mean across simulations") +
  theme_minimal(base_size = 13)

## --- 7. Save ----------------------------------------------------------------

# ggsave(file.path(figDir, "pes_distributions.png"),  pA, width = 7, height = 5, dpi = 300)
# ggsave(file.path(figDir, "pes_sd_by_n.png"),        pB, width = 6, height = 4.5, dpi = 300)
# ggsave(file.path(figDir, "pes_densities.png"),      pC, width = 7, height = 4.5, dpi = 300)
# ggsave(file.path(figDir, "pes_ecdf.png"),           pD, width = 7, height = 4.5, dpi = 300)
# ggsave(file.path(figDir, "pes_trajectories.png"),   pE, width = 7, height = 5, dpi = 300)

pA; pB; pC; pD; pE


























