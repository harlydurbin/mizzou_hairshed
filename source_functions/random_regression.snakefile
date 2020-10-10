# snakemake -s source_functions/random_regression.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/random_regression.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/random_regression/201009.random_regression.log

import os

configfile: "source_functions/config/random_regression.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/random_regression", exist_ok = True)
for x in expand("log/slurm_out/random_regression/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

os.makedirs("log/psrecord/random_regression", exist_ok = True)
os.makedirs("log/psrecord/random_regression/airemlf90", exist_ok = True)

rule base_all:
	input: expand("data/derived_data/random_regression/{model}/airemlf90.{model}.log", model = config['model'])

rule setup_data:
	input:
		script = "source_functions/setup.random_regression.{model}.R",
		cleaned = "data/derived_data/import_join_clean/cleaned.rds",
		full_ped = "data/derived_data/3gen/full_ped.rds",
		weather_data = "data/derived_data/environmental_data/weather.rds",
		coord_key = "data/derived_data/environmental_data/coord_key.csv",
		score_groups = "data/derived_data/score_groups.xlsx",
		ua_score_groups = "data/derived_data/score_groups.xlsx"
	params:
		r_module = config['r_module']
	output:
		sanity_key = "data/derived_data/random_regression/{model}/sanity_key.csv",
		data = "data/derived_data/random_regression/{model}/data.txt"
	shell:
		"""
		module load {params.r_module}
		Rscript --vanilla {input.script}
		"""
rule copy_par:
	input:
		par = "source_functions/par/random_regression.{model}.par",
		fwf = config['geno_prefix'] + '.fwf.txt',
		blupf90_ped = "data/derived_data/3gen/blupf90_ped.txt"
	output:
		par = "data/derived_data/random_regression/{model}/random_regression.{model}.par",
		moved_geno = "data/derived_data/random_regression/{model}/genotypes.txt",
		ped = "data/derived_data/random_regression/{model}/ped.txt",
	shell:
		"""
		cp {input.fwf} {output.moved_geno}
		cp {input.par} {output.par}
		cp {input.blupf90_ped} {output.ped}
		"""

rule renumf90:
	input:
		input_par = "data/derived_data/random_regression/{model}/random_regression.{model}.par",
		datafile = "data/derived_data/random_regression/{model}/data.txt",
		moved_geno = "data/derived_data/random_regression/{model}/genotypes.txt",
		pedfile = "data/derived_data/random_regression/{model}/ped.txt",
		map = config['geno_prefix'] + '.chrinfo.txt'
	params:
		dir = "data/derived_data/random_regression/{model}",
		renumf90_path = config['renumf90_path'],
		renf90_in_name = "random_regression.{model}.par",
		renf90_out_name = "renf90.{model}.out"
	output:
		renf90_par = "data/derived_data/random_regression/{model}/renf90.par",
		renf90_tables = "data/derived_data/random_regression/{model}/renf90.tables",
		renf90_dat = "data/derived_data/random_regression/{model}/renf90.dat"
	shell:
		"""
		cd {params.dir}
		{params.renumf90_path} {params.renf90_in_name} &> {params.renf90_out_name}
		"""

rule airemlf90:
	input:
		renf90_par = "data/derived_data/random_regression/{model}/renf90.par",
		renf90_tables = "data/derived_data/random_regression/{model}/renf90.tables",
		renf90_dat = "data/derived_data/random_regression/{model}/renf90.dat",
		map = config['geno_prefix'] + '.chrinfo.txt',
		moved_geno = "data/derived_data/random_regression/{model}/genotypes.txt"
	params:
		dir = "data/derived_data/random_regression/{model}",
		aireml_out_name = "aireml.{model}.out",
		aireml_log_name = "airemlf90.{model}.log",
		aireml_path = config['aireml_path'],
		psrecord = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/log/psrecord/random_regression/airemlf90/airemlf90.{model}.psrecord",
		mpi_module = config['mpi_module']
	output:
		aireml_log = "data/derived_data/random_regression/{model}/airemlf90.{model}.log"
	shell:
		"""
		module load {params.mpi_module}
		cd {params.dir}
		psrecord "{params.aireml_path} renf90.par &> {params.aireml_out_name}" --log {params.psrecord} --include-children --interval 2
		mv airemlf90.log {params.aireml_log_name}
		"""
