rm(list = ls())

library(ggplot2)
library(cowplot)

plot_dir = '../plots'
if(!dir.exists(plot_dir)) dir.create(plot_dir)

df_1 = read.csv('../data/combined_evo_data.csv')
df_2 = read.csv('../../../2026_05_13_01__small_large_double_mut//hpc/data/combined_evo_data.csv')
df_base = rbind(df_1, df_2)

ggplot(df_base, aes(x = best_org_fitness)) + 
  geom_histogram(binwidth = 1) + 
  geom_histogram(data = df_base[df_base$best_org_fitness == 100,], fill = '#ff0000', binwidth = 1) + 
  scale_x_continuous(limits = c(-2,102)) + 
  scale_y_continuous(limits = c(0, 550), expand = c(0.01, 0.01)) +
  annotate(geom = 'text', x = 75, y = sum(df_base$best_org_fitness %in% 75) + 15, label = sum(df_base$best_org_fitness %in% 75)) +
  annotate(geom = 'text', x = 100, y = sum(df_base$best_org_fitness %in% 100) + 15, label = sum(df_base$best_org_fitness %in% 100), color = '#ff0000')  +
  theme_cowplot() + 
  xlab('Maximum fitness') +
  ylab('Number of replicates')
ggsave(paste0(plot_dir, '/combined_initial_histogram.pdf'), units = 'in', width = 6, height = 4)
  
