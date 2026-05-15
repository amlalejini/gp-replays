rm(list = ls())

df_reps = read.csv('../data/combined_evo_data.csv')

df_stopped = df_reps[is.na(df_reps$found_solution) | (df_reps$max_update != 200 & df_reps$found_solution != '1'),]
print(df_stopped$rep)
