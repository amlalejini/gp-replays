#!/usr/bin/env bash

# CONFIGURATION OPTIONS
EXEC_FILE=prog_synth # Name of the executable file
HPC_ENV_FILEPATH=hpc-env/msu-hpc-env.sh
TEST_PREFIX=../../shared_files/small-or-large-imbalanced
TEMPLATE_FILE=03_job_template_phylo.sb

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

# Setup the problem SLURM and Python environment
if (( $LOAD_MODULES > 0 )); then
  source ${REPO_ROOT_DIR}/${HPC_ENV_FILEPATH}
  source ${REPO_ROOT_DIR}/pyenv/bin/activate
fi


if (($IS_VERBOSE == 1)); then
    echo "Running in verbose mode."
fi

if (($IS_MOCK == 1)); then
    echo "This is a mock job. It will be configured to run locally"
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

# Switch to mock scratch, if requested
if ((${IS_MOCK} == 1)); then
  SCRATCH_ROOT_DIR=${EXP_ROOT_DIR}/mock_scratch
  mkdir -p ${SCRATCH_ROOT_DIR}
  echo "Preparing *mock* jobs for experiment: ${EXP_SLUG}"
else
  echo "Preparing jobs for experiment: ${EXP_SLUG}"
fi

# Grab references to the various directories used in setup
GLOBAL_FILE_DIR=${REPO_ROOT_DIR}/global_shared_files
SCRATCH_EXP_DIR=${SCRATCH_ROOT_DIR}/${EXP_REL_PATH}
# If using a mock scratch, don't use the full relative path
if [ ! ${IS_MOCK} -eq 0 ]; then
  SCRATCH_EXP_DIR=${SCRATCH_ROOT_DIR}
fi
SCRATCH_FILE_DIR=${SCRATCH_EXP_DIR}/shared_files
SCRATCH_SLURM_DIR=${SCRATCH_EXP_DIR}/slurm
SCRATCH_SLURM_OUT_DIR=${SCRATCH_SLURM_DIR}/out
SCRATCH_SLURM_JOB_DIR=${SCRATCH_SLURM_DIR}/jobs
if [ ! ${IS_VERBOSE} -eq 0 ]; then
  echo ""
  echo "[VERBOSE] Global shared file dir: ${GLOBAL_FILE_DIR}"
  echo "[VERBOSE] Scratch directories:"
  echo "[VERBOSE]     Main exp dir: ${SCRATCH_EXP_DIR}"
  echo "[VERBOSE]     Shared files dir: ${SCRATCH_FILE_DIR}"
  echo "[VERBOSE]     Slurm out dir: ${SCRATCH_SLURM_OUT_DIR}"
  echo "[VERBOSE]     Slurm job dir: ${SCRATCH_SLURM_JOB_DIR}"
fi

# Setup the directory structure
echo " "
echo "Creating directory structure in: ${SCRATCH_EXP_DIR}"
mkdir -p ${SCRATCH_FILE_DIR}
mkdir -p ${SCRATCH_SLURM_DIR}
mkdir -p ${SCRATCH_SLURM_OUT_DIR}
mkdir -p ${SCRATCH_SLURM_JOB_DIR}
mkdir -p ${SCRATCH_EXP_DIR}/reps
SCRATCH_LINK=scratch_link
if [ ! -e ${SCRATCH_LINK} ]; then
    ln -s ${SCRATCH_EXP_DIR} ${SCRATCH_LINK}
fi

# Initialize roll_q if needed
if [ ! -d ${ROLL_Q_DIR} ] && [ ${IS_MOCK} -eq 0 ]; then
    echo "roll_q not found in scratch! Copying and initializing..."
    cp ${BASE_ROLL_Q_DIR} ${ROLL_Q_DIR} -r
    echo "0" > ${ROLL_Q_DIR}/roll_q_idx.txt
    rm ${ROLL_Q_DIR}/roll_q_job_array.txt
    touch ${ROLL_Q_DIR}/roll_q_job_array.txt
    echo "roll_q initialized!"
    echo "roll_q dir: ${ROLL_Q_DIR}"
else
    echo "roll_q already in place. Path: ${ROLL_Q_DIR}"
fi
ROLL_Q_LINK=roll_q_link
if [ ! -e ${ROLL_Q_LINK} ]; then
    ln -s ${ROLL_Q_DIR} ${ROLL_Q_LINK}
    echo "Created a symbolic link to roll_q: ${ROLL_Q_LINK}"
fi

# Copy all files that are shared across replicates
echo "Copying files to scratch"
cp ${REPO_ROOT_DIR}/${EXEC_FILE} ${SCRATCH_FILE_DIR}
if [ $(ls -A ${GLOBAL_FILE_DIR} | wc -l ) -gt 0 ]; then
    cp ${GLOBAL_FILE_DIR}/* ${SCRATCH_FILE_DIR}
fi
if [ $(ls -A ${EXP_ROOT_DIR}/shared_files | wc -l ) -gt 0 ]; then
    cp ${EXP_ROOT_DIR}/shared_files/* ${SCRATCH_FILE_DIR}
fi
if [ ! ${IS_VERBOSE} -eq 0 ]; then
  echo ""
  echo "[VERBOSE] Copying:" 
  echo "[VERBOSE]     1. ${REPO_ROOT_DIR}/${EXEC_FILE}"
  echo "[VERBOSE]     2. Files in ${GLOBAL_FILE_DIR}"
  echo "[VERBOSE]     3. Files in ${EXP_ROOT_DIR}/shared_files"
fi

# Tell user where files are going
echo " "
echo "Sending generated slurm job file to dir: ${SCRATCH_SLURM_JOB_DIR}"
echo "Sending slurm output files to dir: ${SCRATCH_SLURM_OUT_DIR}"
echo " "

if (( ${SAVE_GIT} > 0 )); then
  GIT_FILE=git_snaphsot.txt
  echo "Saving current git information to ${GIT_FILE} in experiment folder (not scratch)"
  echo "Command ran: $0" > $GIT_FILE
  echo "Timestamp: $(get_timestamp)" >> $GIT_FILE
  echo "" >> $GIT_FILE
  echo_git_history >> $GIT_FILE
fi

# Get information about replicates to replay
source ./replay_rep_config.sh

for rep_id in ${!reps[@]}; do
  # Create output sbatch file, and find/replace key info
  sed "s/(<EXP_SLUG>)/${EXP_SLUG}/g" ${TEMPLATE_FILE} > out.sb
  sed -i "s/(<SCRATCH_SLURM_OUT_DIR>)/$(escape_slashes ${SCRATCH_SLURM_OUT_DIR})/g" out.sb
  sed -i "s/(<SCRATCH_EXP_DIR>)/$(escape_slashes ${SCRATCH_EXP_DIR})/g" out.sb
  sed -i "s/(<SCRATCH_FILE_DIR>)/$(escape_slashes ${SCRATCH_FILE_DIR})/g" out.sb
  MODULE_CMDS=$(cat ${REPO_ROOT_DIR}/${HPC_ENV_FILEPATH} | tr '\n' ';' | sed 's/;/; /g')
  ESCAPED_MODULE_CMDS=$(escape_slashes "${MODULE_CMDS}")
  sed -i "s/(<MODULE_CMDS>)/${ESCAPED_MODULE_CMDS}/g" out.sb
  ESCAPED_PYTHON_LOAD=$(escape_slashes "source ${REPO_ROOT_DIR}/pyenv/bin/activate")
  sed -i "s/(<PYTHON_LOAD>)/${ESCAPED_PYTHON_LOAD}/g" out.sb
  sed -i "s/(<EXEC_FILE>)/${EXEC_FILE}/g" out.sb
  sed -i "s/(<TEST_PREFIX_LOCAL>)/$(escape_slashes ${TEST_PREFIX})/g" out.sb
  sed -i "s/(<REP_ID>)/${rep_id}/g" out.sb


  # Move output sbatch file to final destination, and add to roll_q queue if needed
  TIMESTAMP=$( get_timestamp )
  SLURM_FILENAME=${SCRATCH_SLURM_JOB_DIR}/${EXP_SLUG}__snapshot_${rep_id}__${TIMESTAMP}.sb
  mv out.sb ${SLURM_FILENAME}

  echo ""
  if [ ${IS_MOCK} -gt 0 ]
  then
    # Make file executable
    chmod u+x ${SLURM_FILENAME}
    # Create a script to run the whole batch
    LOCAL_BATCH_RUNNER=${SCRATCH_SLURM_JOB_DIR}/run_batch__${TIMESTAMP}.sh
    echo "#!/bin/bash" > ${LOCAL_BATCH_RUNNER}
    chmod u+x ${LOCAL_BATCH_RUNNER}
    ARRAY_LINE=$( grep ${SLURM_FILENAME} -Pe "#SBATCH --array" )
    ARRAY_RANGE=$( echo "${ARRAY_LINE}" | grep -Po "\d+-\d+$" )
    ARRAY_START=$( echo "${ARRAY_RANGE}" | grep -oP "^\d+" )
    ARRAY_STOP=$( echo "${ARRAY_RANGE}" | grep -oP "\d+$" )
    OUTPUT_LINE=$( grep ${SLURM_FILENAME} -Poe "(?<=#SBATCH --output=).+$" )
    echo "OUTPUT_FILE_TEMPLATE=${OUTPUT_LINE/\%A/${TIMESTAMP}}" >> ${LOCAL_BATCH_RUNNER}
    echo "for TASK_ID in \$( seq ${ARRAY_START} ${ARRAY_STOP} )" >> ${LOCAL_BATCH_RUNNER}
    echo "do" >> ${LOCAL_BATCH_RUNNER}
    echo "  echo \"Running task \${TASK_ID}\" locally!" >> ${LOCAL_BATCH_RUNNER}
    echo "  ( export SLURM_ARRAY_TASK_ID=\${TASK_ID} ; ${SLURM_FILENAME} -m -l ) > \${OUTPUT_FILE_TEMPLATE/\%a/\${TASK_ID}}" >> ${LOCAL_BATCH_RUNNER}
    echo "done" >> ${LOCAL_BATCH_RUNNER}
  else
    echo "${SLURM_FILENAME}" >> ${ROLL_Q_DIR}/roll_q_job_array.txt
  fi
  echo ""
done


echo ""
if [ ${IS_MOCK} -gt 0 ]
then
  echo "Finished preparing *mock* jobs."
  echo "To run the whole batch, execute:"
  echo "  ${LOCAL_BATCH_RUNNER}"
else
  echo "Finished preparing jobs."
  echo "Run roll_q to queue jobs. (./roll_q.sh to run). roll_q directory:"
  echo "${ROLL_Q_DIR}"
fi
echo ""

