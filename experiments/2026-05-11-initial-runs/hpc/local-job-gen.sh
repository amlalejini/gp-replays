#!/usr/bin/env bash

REPLICATES=50
EXP_SLUG=2026-05-11-initial-runs
SEED_OFFSET=10000
JOB_TIME=08:00:00
JOB_MEM=8G
PROJECT_NAME=gp-replays
USERNAME=lalejini
ACCOUNT=devolab
HPC_ENV_FILE=msu-hpc-env.sh
RUNS_PER_SUBDIR=1000

SCRATCH_EXP_DIR=./test/data/${PROJECT_NAME}
REPO_DIR=/Users/lalejina/devo_ws/${PROJECT_NAME}
HOME_EXP_DIR=${REPO_DIR}/experiments

DATA_DIR=${SCRATCH_EXP_DIR}/${EXP_SLUG}
JOB_DIR=${SCRATCH_EXP_DIR}/${EXP_SLUG}/jobs
# CONFIG_DIR_SRC=${HOME_EXP_DIR}/${EXP_SLUG}/hpc/config
CONFIG_DIR=${HOME_EXP_DIR}/${EXP_SLUG}/hpc/config
HPC_ENV_FILEPATH=${REPO_DIR}/hpc-env/${HPC_ENV_FILE}

# (1) Activate appropriate Python virtual environment
source ${REPO_DIR}/pyenv/bin/activate

# python3 gen-sub.py --runs_per_subdir 1000 --time_request ${JOB_TIME} --mem ${JOB_MEM} --data_dir ${DATA_DIR} --config_dir ${CONFIG_DIR} --repo_dir ${REPO_DIR} --replicates ${REPLICATES} --job_dir ${JOB_DIR} --account ${ACCOUNT} --seed_offset ${SEED_OFFSET}
python3 gen-slurm.py \
  --runs_per_subdir ${RUNS_PER_SUBDIR} \
  --time_request ${JOB_TIME} \
  --mem ${JOB_MEM} \
  --data_dir ${DATA_DIR} \
  --config_dir ${CONFIG_DIR} \
  --repo_dir ${REPO_DIR} \
  --replicates ${REPLICATES} \
  --job_dir ${JOB_DIR} \
  --seed_offset ${SEED_OFFSET} \
  --hpc_account ${ACCOUNT} \
  --hpc_env_file ${HPC_ENV_FILEPATH}