rm(list = ls())

library(ggplot2)
library(dplyr)
library(cowplot)

rep_id = 296

plot_dir = '../plots'
if(!dir.exists(plot_dir)) dir.create(plot_dir)
processed_data_dir = '../data/processed'
if(!dir.exists(processed_data_dir)) dir.create(processed_data_dir)

df_replays = read.csv('../data/combined_replay_data.csv')
df_replays = df_replays[df_replays$rep == rep_id,]
df_replays = df_replays[!is.na(df_replays$found_solution) & df_replays$found_solution != '' & df_replays$found_solution != 'found_solution',]
df_replays$replay_gen = as.numeric(substr(df_replays$replay_gen, 5, 10000000))
df_replays$found_solution = as.numeric(df_replays$found_solution)
df_summary = df_replays %>% 
  dplyr::group_by(rep, replay_gen) %>%
  dplyr::summarize(successes = sum(found_solution, na.rm = T), total_reps = dplyr::n())

df_summary$potentiation = (df_summary$successes / df_summary$total_reps) * 100
df_summary$potentiation_prev = c(NA, df_summary[1:(nrow(df_summary)-1),]$potentiation)
df_summary$potentiation_diff = df_summary$potentiation - df_summary$potentiation_prev
max_diff = max(df_summary$potentiation_diff, na.rm = T)
max_diff_gen = df_summary[!is.na(df_summary$potentiation_diff) & df_summary$potentiation_diff == max_diff,]$replay_gen

cat('Max potentiation gain at generation:', max_diff_gen, '\n')

output_filename = paste0(processed_data_dir, '/processed_potentiation_summary_rep_', rep_id, '.csv')
write.csv(df_summary, file=output_filename)
cat('Processed potentiation data saved to:', output_filename, '\n')

df_ts = read.csv(paste0('../data/replicate_timeseries/', rep_id, '_summary.csv'))

point_size = 0.7
ggplot(df_summary, aes(x = replay_gen, y = potentiation)) + 
  geom_line(data = df_ts, aes(x = update, y = max_approx_agg_score, color = 'Fitness')) +
  geom_point(data = df_ts, aes(x = update, y = max_approx_agg_score, color = 'Fitness'), size = point_size) + 
  scale_y_continuous(limits = c(0,100)) +
  xlab('Generation') + 
  ylab('Percentage') + 
  labs(color = '') + 
  scale_color_manual(values = c('Fitness'='#000000')) + 
  theme_cowplot() + 
  theme(legend.position='bottom')
ggsave(paste0(plot_dir, '/rep_', rep_id, '_fitness_only.png'), units = 'in', width = 8, height = 6)  
ggsave(paste0(plot_dir, '/rep_', rep_id, '_fitness_only.pdf'), units = 'in', width = 6, height = 4)  

point_size = 0.7
ggplot(df_summary, aes(x = replay_gen, y = potentiation)) + 
  geom_vline(xintercept = max_diff_gen, linetype = 'dashed', alpha = 0.5) + 
  geom_line(aes(color = 'Potentiation')) + 
  geom_point(aes(color = 'Potentiation'), size = point_size) + 
  geom_line(data = df_ts, aes(x = update, y = max_approx_agg_score, color = 'Fitness')) +
  geom_point(data = df_ts, aes(x = update, y = max_approx_agg_score, color = 'Fitness'), size = point_size) + 
  scale_y_continuous(limits = c(0,100)) +
  xlab('Generation') + 
  ylab('Percentage') + 
  labs(color = '') + 
  scale_color_manual(values = c('Potentiation'='#ff0000', 'Fitness'='#000000')) + 
  theme_cowplot() + 
  theme(legend.position='bottom')
ggsave(paste0(plot_dir, '/rep_', rep_id, '_potentiation_and_fitness.png'), units = 'in', width = 8, height = 6)  
ggsave(paste0(plot_dir, '/rep_', rep_id, '_potentiation_and_fitness.pdf'), units = 'in', width = 6, height = 4)  