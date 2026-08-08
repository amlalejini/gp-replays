rm(list = ls())

library(ggplot2)
library(dplyr)
library(cowplot)

plot_dir = '../plots'
if(!dir.exists(plot_dir)) dir.create(plot_dir)
processed_data_dir = '../data/processed'
if(!dir.exists(processed_data_dir)) dir.create(processed_data_dir)

df_pot_a = read.csv('../../2026_05_13_01__small_large_double_mut/hpc/data/processed/processed_potentiation_summary_rep_296.csv')
df_ts_a = read.csv('../../2026_05_13_01__small_large_double_mut/hpc/data/replicate_timeseries/296_summary.csv')
df_ts_a$rep = 296
df_pot_a$pop = 'Population A'
df_ts_a$pop = 'Population A'

df_pot_b = read.csv('../../2026_05_14_01__small_large_batch_2/hpc/data/processed/processed_potentiation_summary_rep_305.csv')
df_ts_b = read.csv('../../2026_05_14_01__small_large_batch_2/hpc/data/replicate_timeseries/305_summary.csv')
df_ts_b$rep = 305
df_pot_b$pop = 'Population B'
df_ts_b$pop = 'Population B'

df_pot_c = read.csv('../../2026_05_14_01__small_large_batch_2/hpc/data/processed/processed_potentiation_summary_rep_457.csv')
df_ts_c = read.csv('../../2026_05_14_01__small_large_batch_2/hpc/data/replicate_timeseries/457_summary.csv')
df_ts_c$rep = 457
df_pot_c$pop = 'Population C'
df_ts_c$pop = 'Population C'

df_pot = rbind(df_pot_a, df_pot_b, df_pot_c)
df_ts = rbind(df_ts_a, df_ts_b, df_ts_c)


max_diff_a = max(df_pot_a$potentiation_diff, na.rm = T)
max_diff_gen_a = df_pot_a[!is.na(df_pot_a$potentiation_diff) & df_pot_a$potentiation_diff == max_diff_a,]$replay_gen
max_diff_b = max(df_pot_b$potentiation_diff, na.rm = T)
max_diff_gen_b = df_pot_b[!is.na(df_pot_b$potentiation_diff) & df_pot_b$potentiation_diff == max_diff_b,]$replay_gen
max_diff_c = max(df_pot_c$potentiation_diff, na.rm = T)
max_diff_gen_c = df_pot_c[!is.na(df_pot_c$potentiation_diff) & df_pot_c$potentiation_diff == max_diff_c,]$replay_gen
df_diff = data.frame(data = matrix(nrow = 3, ncol = 3))
colnames(df_diff) = c('rep', 'gen', 'pop')
df_diff[1,] = c(296, max_diff_gen_a, 'Population A')
df_diff[2,] = c(305, max_diff_gen_b, 'Population B')
df_diff[3,] = c(457, max_diff_gen_c, 'Population C')
df_diff$gen = as.numeric(df_diff$gen)

font_size_small = 16
font_size_large = 20
point_size = 1.0
line_size = 1.1
ggplot(df_pot, aes(x = replay_gen, y = potentiation)) + 
  geom_vline(data = df_diff, aes(xintercept = gen), linetype = 'dashed', alpha = 0.5, linewidth = line_size) + 
  geom_line(aes(color = 'Potentiation'), linewidth = line_size) + 
  geom_point(aes(color = 'Potentiation'), size = point_size) + 
  geom_line(data = df_ts, aes(x = update, y = max_approx_agg_score, color = 'Fitness'), linewidth = line_size) +
  geom_point(data = df_ts, aes(x = update, y = max_approx_agg_score, color = 'Fitness'), size = point_size) + 
  scale_y_continuous(limits = c(0,100)) +
  xlab('Generation') + 
  ylab('Percentage') + 
  labs(color = '') + 
  scale_color_manual(values = c('Potentiation'='#ff0000', 'Fitness'='#000000')) + 
  facet_grid(rows = vars(pop)) +
  theme_cowplot() + 
  theme(panel.background = element_rect(fill = NA, color = '#000000')) + 
  theme(legend.position='bottom') + 
  theme(axis.title = element_text(size = font_size_large), axis.text = element_text(size = font_size_small)) + 
  theme(legend.text = element_text(size = font_size_large), strip.text = element_text(size = font_size_large))
ggsave(paste0(plot_dir, '/potentiation_and_fitness.png'), units = 'in', width = 10, height = 12)  
ggsave(paste0(plot_dir, '/potentiation_and_fitness.pdf'), units = 'in', width = 10, height = 12)  

