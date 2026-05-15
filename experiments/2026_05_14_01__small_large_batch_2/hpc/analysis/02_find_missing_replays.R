rm(list = ls())

library(ggplot2)
library(dplyr)

df_replays = read.csv('../data/combined_replay_data.csv')
min_replay_id = min(df_replays$replay_rep)
max_replay_id = max(df_replays$replay_rep)
min_replay_id_num = as.numeric(substr(min_replay_id, 5, 10000))
max_replay_id_num = as.numeric(substr(max_replay_id, 5, 10000))
num_replays = max_replay_id_num - min_replay_id_num + 1
real_ids=min_replay_id_num:max_replay_id_num

cat('declare -A reps_to_gens\n')
cat('declare -A rep_gens_to_reps\n')

for(rep in unique(df_replays$rep)){
  df_rep = df_replays[df_replays$rep == rep,]
  gens_to_rerun = c()
  gen_rep_map = c()
  for(replay_gen in unique(df_rep$replay_gen)){
    df_gen = df_rep[df_rep$replay_gen == replay_gen,]
    need_reran = c()
    if(nrow(df_gen) != num_replays){
      replay_ids = as.numeric(substr(df_gen$replay_rep, 5, 10000))
      need_reran = c(need_reran, paste0('gen_', sort(setdiff(real_ids, replay_ids))))
    }
    bad_count = sum(!grepl('^\\d+$', df_gen$max_update, perl=T))
    if(bad_count > 0){
      need_reran = c(need_reran, df_gen[!grepl('^\\d+$', df_gen$max_update, perl=T),]$replay_rep)
    }
    if(length(need_reran) > 0){
      #cat('Rep:', rep, 'replay gen:', replay_gen, '\n')
      gen_num = as.numeric(substr(replay_gen, 5, 10000))
      gens_to_rerun = c(gens_to_rerun, gen_num)
      #print(need_reran)
      need_reran_num = as.numeric(substr(need_reran, 5, 10000))
      old_names = names(gen_rep_map)
      gen_rep_map = c(gen_rep_map, paste(need_reran_num, collapse = ' '))
      #print(paste(need_reran_num, collapse = ' '))
      names(gen_rep_map) = c(old_names, as.character(gen_num))
    }
  }
  cat('reps_to_gens[', rep, ']="', paste(sort(gens_to_rerun), collapse = ' '), '"\n', sep = '')
  for(replay_gen in sort(gens_to_rerun)){
    reps = gen_rep_map[as.character(replay_gen)]
    cat('rep_gens_to_reps["', rep, 'x', replay_gen, '"]="', paste(sort(reps), collapse = ' '), '"\n', sep = '')
  }
}
