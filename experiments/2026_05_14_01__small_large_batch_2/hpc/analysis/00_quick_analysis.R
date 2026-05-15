rm(list = ls())

library(ggplot2)
library(dplyr)
library(cowplot)

plot_dir = '../plots'
if(!dir.exists(plot_dir)) dir.create(plot_dir)

df_replays = read.csv('../data/combined_replay_data.csv')
df_replays = df_replays[!is.na(df_replays$found_solution) & df_replays$found_solution != '' & df_replays$found_solution != 'found_solution',]
df_replays$replay_gen = as.numeric(substr(df_replays$replay_gen, 5, 10000000))
df_replays$found_solution = as.numeric(df_replays$found_solution)
df_summary = df_replays %>% 
  dplyr::group_by(rep, replay_gen) %>%
  dplyr::summarize(successes = sum(found_solution, na.rm = T), total_reps = dplyr::n())

df_summary$potentiation = (df_summary$successes / df_summary$total_reps) * 100

ggplot(df_summary, aes(x = replay_gen, y = potentiation)) + 
  geom_line() + 
  geom_point()

df_ts = read.csv('../data/replicate_timeseries/305_summary.csv')

point_size = 0.7
ggplot(df_summary, aes(x = replay_gen, y = potentiation)) + 
  geom_vline(xintercept = 93, linetype = 'dashed', alpha = 0.5) + 
  geom_line(aes(color = 'Potentiation')) + 
  geom_point(aes(color = 'Potentiation'), size = point_size) + 
  geom_line(data = df_ts, aes(x = update, y = max_approx_agg_score, color = 'Fitness')) +
  geom_point(data = df_ts, aes(x = update, y = max_approx_agg_score, color = 'Fitness'), size = point_size) + 
  xlab('Generation') + 
  ylab('Percentage') + 
  labs(color = '') + 
  scale_color_manual(values = c('Potentiation'='#ff0000', 'Fitness'='#000000')) + 
  theme_cowplot() + 
  theme(legend.position='bottom')
ggsave(paste0(plot_dir, '/potentiation_and_fitness.png'), units = 'in', width = 8, height = 6)  
ggsave(paste0(plot_dir, '/potentiation_and_fitness.pdf'), units = 'in', width = 6, height = 4)  
