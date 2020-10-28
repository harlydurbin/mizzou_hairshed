# snakemake -s source_functions/ssgwas.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/ssgwas.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/ssgwas/201028.ssgwas.log

import os

configfile: "source_functions/config/ssgwas.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/ssgwas", exist_ok = True)
for x in expand("log/slurm_out/ssgwas/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

rule all:
	input: expand("data/derived_data/ssgwas/{model}/snp_sol", model = config['model'])

rule cp:
	input:
		airemlf90_solutions = lambda wildcards: expand("{dir}/solutions", dir = config['dir'][wildcards.model])
	params:
		in_dir = lambda wildcards: expand("{dir}", dir = config['dir'][wildcards.model]),
		out_dir = "data/derived_data/ssgwas/{model}",
		airemlf90_solutions = "data/derived_data/ssgwas/{model}/solutions"
	output:
		par = "data/derived_data/ssgwas/{model}/renf90.par"
	shell:
		"""
		cp {params.in_dir}/* {params.out_dir}
		rm {params.airemlf90_solutions}
		"""

rule blupf90:
	input:
		par = "data/derived_data/ssgwas/{model}/renf90.par"
	params:
		dir = "data/derived_data/ssgwas/{model}",
		blupf90_out = "blupf90.{model}.out",
		blupf90_path = config['blupf90_path'],
		mpi_export = config['mpi_export'],
		mpi_module = config['mpi_module']
	output:
		blupf90_solutions = "data/derived_data/ssgwas/{model}/solutions"
	shell:
		"""
		{params.mpi_export}
		module load {params.mpi_module}
		cd {params.dir}
		{params.blupf90_path} renf90.par &> {params.blupf90_out}
		"""

# Remove BLUP OPTIONs, add postGSf90 OPTIONs
rule ssgwas_par:
	input:
		blupf90_solutions = "data/derived_data/ssgwas/{model}/solutions",
		blupf90_par = "data/derived_data/ssgwas/{model}/renf90.par",
		ssgwas_options = "source_functions/par/ssgwas_options.txt"
	output:
		postGSf90_par = "data/derived_data/ssgwas/{model}/renf90.ssgwas.par"
	shell:
		"""
		head -n 34 {input.blupf90_par} > {output.postGSf90_par}
		cat {input.ssgwas_options} >> {output.postGSf90_par}
		"""

rule ssgwas:
	input:
		blupf90_solutions_moved = "data/derived_data/ssgwas/{model}/solutions",
		postGSf90_par = "data/derived_data/ssgwas/{model}/renf90.ssgwas.par"
	params:
		dir = "data/derived_data/ssgwas/{model}",
		postGSf90_out = "ssgwas.{model}.out",
		postGSf90_path = config['postGSf90_path'],
		mpi_export = config['mpi_export'],
		mpi_module = config['mpi_module']
	output:
		snp_sol = "data/derived_data/ssgwas/{model}/snp_sol"
	shell:
		"""
		{params.mpi_export}
		module load {params.mpi_module}
		ulimit -s unlimited
		ulimit -v unlimited
		cd {params.dir}
		{params.postGSf90_path} renf90.ssgwas.par &> {params.postGSf90_out}
		"""
