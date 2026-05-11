'''
Generate slurm job submission scripts - one per condition
'''

import argparse, os, sys, pathlib
# from asyncio import base_events
# from email.policy import default
from pyvarco import CombinationCollector
sys.path.append(
    os.path.join(
        pathlib.Path(os.path.dirname(os.path.abspath(__file__))).parents[2],
        "scripts"
    )
)
import utilities as utils

default_seed_offset = 0
default_account = "devolab"
default_num_replicates = 30
default_job_time_request = "148:00:00"
default_job_mem_request = "8G"
default_total_generations = 300000

job_name = "XX-YY"
executable = "prog_synth"

base_script_filename = "./base_script.txt"

# Create combo object to collect all conditions we'll run
combos = CombinationCollector()

fixed_parameters = {
    "POP_SIZE": "500",
    "MAX_GENS": "200",
    "MAX_EVALS": "50000000",
    "STOP_MODE": "generations",
    "POP_INIT_MODE": "random",
    "OUTPUT_SUMMARY_DATA_INTERVAL": "10",
    "PRINT_INTERVAL": "10",
    "PHYLO_SNAPSHOT_INTERVAL": "1000",
    "CURRENT_POP_SNAPSHOT_INTERVAL": "10000",
    "EVAL_ADJ_EST": "0",
    "PRG_MAX_FUNC_INST_CNT": "128",
    "EVAL_CPU_CYCLES_PER_TEST": "128",
    "PHYLO_SNAPSHOTS": "0",
    "RECORD_PHYLO_GENOTYPES": "0",
    "CURRENT_POP_GENOME_SNAPSHOTS": "0",
    "PHYLO_TRACKING": "0"
}

special_decorators = ["__DYNAMIC", "__COPY_OVER"]

combos.register_var("eval__COPY_OVER")
combos.register_var("problem__COPY_OVER")
combos.register_var("SELECTION")

combos.add_val(
    "problem__COPY_OVER",
    [
        "-PROBLEM bouncing-balls -TESTING_SET_PATH bouncing-balls-testing.json -TRAINING_SET_PATH bouncing-balls-training.json",
        "-PROBLEM fizz-buzz -TESTING_SET_PATH fizz-buzz-imbalanced-testing.json -TRAINING_SET_PATH fizz-buzz-imbalanced-training.json",
        "-PROBLEM for-loop-index -TESTING_SET_PATH for-loop-index-testing.json -TRAINING_SET_PATH for-loop-index-training.json",
        "-PROBLEM gcd -TESTING_SET_PATH gcd-testing.json -TRAINING_SET_PATH gcd-training.json",
        "-PROBLEM median -TESTING_SET_PATH median-testing.json -TRAINING_SET_PATH median-training.json",
        "-PROBLEM grade -TESTING_SET_PATH grade-imbalanced-testing.json -TRAINING_SET_PATH grade-imbalanced-training.json",
        "-PROBLEM small-or-large -TESTING_SET_PATH small-or-large-imbalanced-testing.json -TRAINING_SET_PATH small-or-large-imbalanced-training.json",
        "-PROBLEM smallest -TESTING_SET_PATH smallest-testing.json -TRAINING_SET_PATH smallest-training.json",
        "-PROBLEM snow-day -TESTING_SET_PATH snow-day-testing.json -TRAINING_SET_PATH snow-day-training.json",
        "-PROBLEM dice-game -TESTING_SET_PATH dice-game-testing.json -TRAINING_SET_PATH dice-game-training.json"
    ]
)

combos.add_val(
    "eval__COPY_OVER",
    [
        "-EVAL_MODE full -EVAL_FIT_EST_MODE none -EVAL_MAX_PHYLO_SEARCH_DEPTH 1"
    ]
)

combos.add_val(
    "SELECTION",
    [
        "lexicase"
    ]
)

def main():
    parser = argparse.ArgumentParser(description="Run submission script.")
    parser.add_argument("--data_dir", type=str, help="Where is the output directory for phase one of each run?")
    parser.add_argument("--config_dir", type=str, help="Where is the configuration directory for experiment?")
    parser.add_argument("--repo_dir", type=str, help="Where is the repository for this experiment?")
    parser.add_argument("--job_dir", type=str, default=None, help="Where to output these job files? If none, put in 'jobs' directory inside of the data_dir")
    parser.add_argument("--replicates", type=int, default=default_num_replicates, help="How many replicates should we run of each condition?")
    parser.add_argument("--seed_offset", type=int, default=default_seed_offset, help="Value to offset random number seeds by")
    parser.add_argument("--hpc_account", type=str, default=default_account, help="Value to use for the slurm ACCOUNT")
    parser.add_argument("--time_request", type=str, default=default_job_time_request, help="How long to request for each job on hpc?")
    parser.add_argument("--mem", type=str, default=default_job_mem_request, help="How much memory to request for each job?")
    parser.add_argument("--runs_per_subdir", type=int, default=-1, help="How many replicates to clump into job subdirectories")
    parser.add_argument("--hpc_env_file", type=str, default=None, help="Bash script that loads correct hpc modules")

    # Load in command line arguments
    args = parser.parse_args()
    data_dir = args.data_dir
    config_dir = args.config_dir
    job_dir = args.job_dir
    repo_dir = args.repo_dir
    num_replicates = args.replicates
    hpc_account = args.hpc_account
    seed_offset = args.seed_offset
    job_time_request = args.time_request
    job_memory_request = args.mem
    runs_per_subdir = args.runs_per_subdir

    # Load in the base slurm file
    base_sub_script = ""
    with open(base_script_filename, 'r') as fp:
        base_sub_script = fp.read()

    # Get list of all combinations to run
    combo_list = combos.get_combos()
    for c in combo_list:
        print(c)

    # Calculate how many jobs we have, and what the last id will be
    num_jobs = num_replicates * len(combo_list)
    runs_per_subdir = runs_per_subdir if runs_per_subdir > 0 else 2 * num_jobs
    print(f'Generating {num_jobs} across {len(combo_list)} files!')
    print(f' - Data directory: {data_dir}')
    print(f' - Config directory: {config_dir}')
    print(f' - Repository directory: {repo_dir}')
    print(f' - Replicates: {num_replicates}')
    print(f' - Account: {hpc_account}')
    print(f' - Time Request: {job_time_request}')
    print(f' - Seed offset: {seed_offset}')

    # If no job_dir provided, default to data_dir/jobs
    if job_dir == None:
        job_dir = os.path.join(data_dir, "jobs")

    # Create job file for each condition
    cur_job_id = 0
    cond_i = 0
    generated_files = set()
    cur_subdir_run_cnt = 0
    cur_run_subdir_id = 0
    for condition_dict in combo_list:
        cur_seed = seed_offset + (cur_job_id * num_replicates)
        # Figure out current problem
        testing_set = condition_dict["problem__COPY_OVER"].split("-TESTING_SET_PATH")[-1].strip().split(" ")[0]
        training_set = condition_dict["problem__COPY_OVER"].split("-TRAINING_SET_PATH")[-1].strip().split(" ")[0]
        problem_name = condition_dict["problem__COPY_OVER"].split("-PROBLEM")[-1].strip().split(" ")[0]
        filename_prefix = f'RUN_C{cond_i}_{problem_name}'
        file_str = base_sub_script
        file_str = file_str.replace("<<TIME_REQUEST>>", job_time_request)
        file_str = file_str.replace("<<MEMORY_REQUEST>>", job_memory_request)
        file_str = file_str.replace("<<JOB_NAME>>", f"C{cond_i}")
        file_str = file_str.replace("<<CONFIG_DIR>>", config_dir)
        file_str = file_str.replace("<<REPO_DIR>>", repo_dir)
        file_str = file_str.replace("<<EXEC>>", executable)
        file_str = file_str.replace("<<JOB_SEED_OFFSET>>", str(cur_seed))
        file_str = file_str.replace("<<TRAINING_SET>>", training_set)
        file_str = file_str.replace("<<TESTING_SET>>", testing_set)
        file_str = file_str.replace("<<ARRAY_ID_RANGE>>", f"1-{args.replicates}")

        if args.hpc_account is None:
            file_str = file_str.replace("<<HPC_ACCOUNT_INFO>>", "")
        else:
            file_str = file_str.replace("<<HPC_ACCOUNT_INFO>>", f"#SBATCH --account {args.hpc_account}")

        if args.hpc_env_file is None:
            file_str = file_str.replace("<<SETUP_HPC_ENV>>", "")
        else:
            file_str = file_str.replace("<<SETUP_HPC_ENV>>", f"source {args.hpc_env_file}")

        ###################################################################
        # Configure the run
        ###################################################################
        run_dir = os.path.join(data_dir, f"{filename_prefix}_"+"${SEED}")
        file_str = file_str.replace("<<RUN_DIR>>", run_dir)

        # Format commandline arguments for the run
        run_param_info = {key:condition_dict[key] for key in condition_dict if not any([dec in key for dec in special_decorators])}
        # Add fixed paramters
        for param in fixed_parameters:
            if param in run_param_info: continue
            run_param_info[param] = fixed_parameters[param]
        # Set random number seed
        run_param_info["SEED"] = '${SEED}'

        ###################################################################
        # Build commandline parameters string
        ###################################################################
        fields = list(run_param_info.keys())
        fields.sort()
        set_params = [f"-{field} {run_param_info[field]}" for field in fields]
        copy_params = [condition_dict[key] for key in condition_dict if "__COPY_OVER" in key]
        run_params = " ".join(set_params + copy_params)
        ###################################################################

        ###################################################################
        # Build run command
        ###################################################################
        run_cmds = []
        run_cmds.append(f'RUN_PARAMS="{run_params}"')
        run_cmds.append('echo "./${EXEC} ${RUN_PARAMS}" > cmd.log')
        run_cmds.append('./${EXEC} ${RUN_PARAMS} > run.log')
        run_cmds_str = "\n".join(run_cmds)
        file_str = file_str.replace("<<RUN_CMDS>>", run_cmds_str)
        ###################################################################

        ###################################################################
        # Build copy configuration command
        ###################################################################
        config_cp_cmds = []
        # Copy: executable, config file, testing and training sets
        config_cp_cmds.append("cp ${CONFIG_DIR}/${EXEC} .")
        config_cp_cmds.append("cp ${CONFIG_DIR}/*.cfg .")
        config_cp_cmds.append("cp ${CONFIG_DIR}/" + f"{testing_set} .")
        config_cp_cmds.append("cp ${CONFIG_DIR}/" + f"{training_set} .")
        config_cp_cmds_str = "\n".join(config_cp_cmds)
        file_str = file_str.replace("<<CONFIG_CP_CMDS>>", config_cp_cmds_str)
        ###################################################################

        ###################################################################
        # Write job submission file
        ###################################################################
        cur_job_dir = job_dir if args.runs_per_subdir == -1 else os.path.join(job_dir, f"job-set-{cur_run_subdir_id}")
        utils.mkdir_p(cur_job_dir)
        with open(os.path.join(cur_job_dir, f'{filename_prefix}.sb'), 'w') as fp:
            fp.write(file_str)

        # Update condition id and current job id
        cur_job_id += 1
        cond_i += 1
        cur_subdir_run_cnt += args.replicates
        if cur_subdir_run_cnt > (args.runs_per_subdir - args.replicates):
            cur_subdir_run_cnt = 0
            cur_run_subdir_id += 1


if __name__ == "__main__":
    main()
