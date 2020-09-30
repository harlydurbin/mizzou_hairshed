# snakemake -s source_functions/base_varcomp.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/base_varcomp.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/200420.base_varcomp.log

import os

configfile: "source_functions/config/base_varcomp.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/base_varcomp", exist_ok = True)
for x in expand("log/slurm_out/base_varcomp/{rules}", rules = config['rules']):
    os.makedirs(x, exist_ok = True)

os.makedirs("log/psrecord/base_varcomp", exist_ok = True)
for x in expand("log/psrecord/base_varcomp/{rules}", rules = config['rules']):
    os.makedirs(x, exist_ok = True)

rule all:
	input: expand("data/derived_data/base_varcomp/{model}/solutions", model = config['model'])

rule copy_par:
	resources:
		load = 1
	input:
		par = "source_functions/par/base_varcomp.{model}.par",
		formatted_geno = config['geno_prefix'] + '.format.txt'
	output:
		par = "data/derived_data/base_varcomp/{model}/base_varcomp.{model}.par",
		moved_geno = "data/derived_data/base_varcomp/{model}/genotypes.txt"
	shell:
    # awk command creates fixed width file
		"""
		awk '{{printf "%-20s %s\\n", $1, $2}}' {input.formatted_geno} &> {output.moved_geno}
		cp {input.par} {output.par}
		"""

rule renumf90:
	input:
		input_par = "data/derived_data/base_varcomp/{model}/base_varcomp.{model}.par",
		datafile = "data/derived_data/base_varcomp/{model}/data.txt",
		moved_geno = "data/derived_data/base_varcomp/{model}/genotypes.txt",
		pedfile = "data/derived_data/base_varcomp/{model}/ped.txt",
		format_map = config['mapfile']
	params:
		dir = "data/derived_data/base_varcomp/{model}",
		renumf90_path = config['renumf90_path'],
		renf90_in_name = "base_varcomp.{model}.par",
		renf90_out_name = "renf90.base_varcomp.{model}.out"
	output:
		renf90_par = "data/derived_data/base_varcomp/{model}/renf90.par"
	shell:
		"""
		cd {params.dir}
		{params.renumf90_path} {params.renf90_in_name} &> {params.renf90_out_name}
		"""

rule airemlf90:
	resources:
		load = 100
	input:
		renf90_par = "data/derived_data/base_varcomp/{model}/renf90.par",
		format_map = config['mapfile'],
		moved_geno = "data/derived_data/base_varcomp/{model}/genotypes.txt"
	params:
		dir = "data/derived_data/base_varcomp/{model}",
		aireml_out_name = "aireml.base_varcomp.{model}.out",
		aireml_log_name = "airemlf90.base_varcomp.{model}.log",
		aireml_path = config['aireml_path'],
		psrecord = "/storage/hpc/group/UMAG/WORKING/hjdzpd/hair_shed/log/psrecord/base_varcomp/airemlf90.base_varcomp.{model}.psrecord"
	output:
		aireml_solutions = "data/derived_data/base_varcomp/{model}/solutions",
		aireml_log = "data/derived_data/base_varcomp/{model}/airemlf90.base_varcomp.{model}.log"
	shell:
		"""
		cd {params.dir}
		psrecord "{params.aireml_path} renf90.par &> {params.aireml_out_name}" --log {params.psrecord} --include-children --interval 2
		mv airemlf90.log {params.aireml_log_name}
		rm genotypes*
		"""
