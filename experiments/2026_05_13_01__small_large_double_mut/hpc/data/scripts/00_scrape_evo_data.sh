#!/bin/bash

# Configuration options
output_file=../combined_evo_data.csv
header="rep,max_update,best_org_fitness,best_org_id,update,evaluations,test_estimations,found_solution,pop_training_coverage,max_approx_agg_score,num_unique_selected,entropy_selected_ids,parents_training_coverage,training_coverage_loss"

# Grab global variables and helper functions
# The root level of the repo should be directory just above 'experiments'
REPO_ROOT_DIR=$(pwd | grep -oP ".+(?=/experiments/)")

# Fetch global configuration options
# Mainly to define SCRATCH_ROOT_DIR variable (root scratch dir for this experiment)
source ${REPO_ROOT_DIR}/config_global.sh

# Fetch helper functions
source ${REPO_ROOT_DIR}/global_shared_files/bash_helper_functions.sh

# Parse command-line arguments
# Will set two variables (each will be set to 0 or 1):
#   1. IS_MOCK -- is this a mock (local) job
#   2. IS_VERBOSE -- should we print extra debugging info?
source ${REPO_ROOT_DIR}/scripts/parse_cmd_args.sh "$@"

if (($IS_VERBOSE == 1)); then
    echo "Running in verbose mode."
fi

# Extract useful information about our setup
EXP_SLUG=$( get_cur_exp_name )
EXP_REL_PATH=$( get_cur_relative_exp_path)
EXP_ROOT_DIR=$(pwd)

if (($IS_VERBOSE == 1)); then
    echo "[VERBOSE] Found repo root dir: ${REPO_ROOT_DIR}"
    echo "[VERBOSE] Root directory for this experiment in scratch: ${SCRATCH_ROOT_DIR}"
    echo "[VERBOSE] Slug of current experiment: ${EXP_SLUG}"
    echo "[VERBOSE] Relative path of experiment: ${EXP_REL_PATH}"
fi

SCRATCH_EXP_DIR=${SCRATCH_ROOT_DIR}/${EXP_REL_PATH}
SCRATCH_REP_DIR=${SCRATCH_EXP_DIR}/reps
if [ ! ${IS_VERBOSE} -eq 0 ]; then
  echo ""
  echo "[VERBOSE] Scratch directories:"
  echo "[VERBOSE]     Main exp dir: ${SCRATCH_EXP_DIR}"
  echo "[VERBOSE]     Rep dir: ${SCRATCH_REP_DIR}"
fi

echo "$header" > ${output_file}
for rep_id in $( ls ${SCRATCH_REP_DIR} | sort)
do
    full_path=${SCRATCH_REP_DIR}/${rep_id}
    if ! [ -d $full_path ]
    then
      continue
    fi
    echo ${rep_id}
    last_log_line=$(tail -n 1 ${full_path}/run.log)
    echo "${last_log_line}"
    max_update=$(echo "${last_log_line}" | sed -E "s/update: ([0-9]+);.+/\1/g")
    best_org_id=$(echo "${last_log_line}" | sed -E "s/.+score \(([0-9]+)\).+/\1/g")
    best_org_fitness=$(echo "${last_log_line}" | sed -E "s/.+ ([0-9]+)$/\1/g")
    last_summary_line=$(tail -n 1 ${full_path}/output/summary.csv)
    echo "${rep_id},${max_update},${best_org_fitness},${best_org_id},${last_summary_line}" >> $output_file

done
