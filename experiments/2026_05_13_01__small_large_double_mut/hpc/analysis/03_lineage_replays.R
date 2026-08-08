rm(list = ls())

library(dplyr)

df_lineage = read.csv('../data/combined_lineage_replay_data.csv')

df_summary = df_lineage %>% 
  dplyr::group_by(rep, replay_gen) %>%
  dplyr::summarize(successes = sum(found_solution), total = dplyr::n())
