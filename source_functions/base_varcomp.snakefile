# snakemake -s source_functions/base_varcomp.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/base_varcomp.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/base_varcomp/201002.base_varcomp.log

import os

configfile: "source_functions/config/base_varcomp.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/base_varcomp", exist_ok = True)
for x in expand("log/slurm_out/base_varcomp/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

os.makedirs("log/psrecord/base_varcomp", exist_ok = True)
os.makedirs("log/psrecord/base_varcomp/airemlf90", exist_ok = True)

rule base_all:
	input: expand("data/derived_data/base_varcomp/{model}/airemlf90.{model}.log", model = config['model'])

rule setup_data:
	input:
		script = "source_functions/setup.base_varcomp.{model}.R",
		cleaned = "data/derived_data/import_join_clean/cleaned.rds",
		full_ped = "data/derived_data/3gen/full_ped.rds",
	params:
		r_module = config['r_module']
	output:
		sanity_key = "data/derived_data/base_varcomp/{model}/sanity_key.csv",
		data = "data/derived_data/base_varcomp/{model}/data.txt"
	shell:
		"""
		module load {params.r_module}
		Rscript --vanilla {input.script}
		"""
rule copy_par:
	input:
		par = "source_functions/par/base_varcomp.{model}.par",
		fwf = config['geno_prefix'] + '.fwf.txt',
		blupf90_ped = "data/derived_data/3gen/blupf90_ped.txt"
	output:
		par = "data/derived_data/base_varcomp/{model}/base_varcomp.{model}.par",
		moved_geno = "data/derived_data/base_varcomp/{model}/genotypes.txt",
		ped = "data/derived_data/base_varcomp/{model}/ped.txt",
	shell:
		"""
		cp {input.fwf} {output.moved_geno}
		cp {input.par} {output.par}
		cp {input.blupf90_ped} {output.ped}
		"""

rule renumf90:
	input:
		input_par = "data/derived_data/base_varcomp/{model}/base_varcomp.{model}.par",
		datafile = "data/derived_data/base_varcomp/{model}/data.txt",
		moved_geno = "data/derived_data/base_varcomp/{model}/genotypes.txt",
		pedfile = "data/derived_data/base_varcomp/{model}/ped.txt",
		map = config['geno_prefix'] + '.chrinfo.txt'
	params:
		dir = "data/derived_data/base_varcomp/{model}",
		renumf90_path = config['renumf90_path'],
		renf90_in_name = "base_varcomp.{model}.par",
		renf90_out_name = "renf90.base_varcomp.{model}.out"
	output:
		renf90_par = "data/derived_data/base_varcomp/{model}/renf90.par",
		renf90_tables = "data/derived_data/base_varcomp/{model}/renf90.tables",
		renf90_dat = "data/derived_data/base_varcomp/{model}/renf90.dat"
	shell:
		"""
		cd {params.dir}
		{params.renumf90_path} {params.renf90_in_name} &> {params.renf90_out_name}
		"""

rule airemlf90:
	input:
		renf90_par = "data/derived_data/base_varcomp/{model}/renf90.par",
		renf90_tables = "data/derived_data/base_varcomp/{model}/renf90.tables",
		renf90_dat = "data/derived_data/base_varcomp/{model}/renf90.dat",
		map = config['geno_prefix'] + '.chrinfo.txt',
		moved_geno = "data/derived_data/base_varcomp/{model}/genotypes.txt"
	params:
		dir = "data/derived_data/base_varcomp/{model}",
		aireml_out_name = "aireml.base_varcomp.{model}.out",
		aireml_log_name = "airemlf90.base_varcomp.{model}.log",
		aireml_path = config['aireml_path'],
		psrecord = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/log/psrecord/base_varcomp/airemlf90/airemlf90.{model}.psrecord"
	output:
		aireml_log = "data/derived_data/base_varcomp/{model}/airemlf90.{model}.log"
	shell:
		"""
		cd {params.dir}
		psrecord "{params.aireml_path} renf90.par &> {params.aireml_out_name}" --log {params.psrecord} --include-children --interval 2
		cp airemlf90.log {params.aireml_log_name}
		"""
