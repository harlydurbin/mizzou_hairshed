# snakemake -s source_functions/ss_blup.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/ss_blup.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/200420.ss_blup.log


import os

configfile: "source_functions/config/ss_blup.config.yaml"

# Make log directories if they don't exist
for x in expand("log/slurm_out/ss_blup/{rules}", rules = config['rules']):
    os.makedirs(x, exist_ok = True)

os.makedirs("log/psrecord/ss_blup", exist_ok = True)

for x in expand("log/psrecord/ss_blup/{rules}", rules = config['rules']):
    os.makedirs(x, exist_ok = True)

rule all:
	input: expand("data/derived_data/update_email2020/{model}/solutions", model = config['model'])

rule transpose_genotypes:
	input:
		mgf = config['geno_prefix'] + '.mgf.gz'
	params:
		java_module = config['java_module'],
		psrecord = "log"
	output:
		transposed = config['geno_prefix'] + '.t.txt'
	shell:
		"""
		module load {params.java_module}
		psrecord "zcat {input.mgf} | sed 's/,/ /g' | java -jar source_functions/transpose.jar > {output.transposed}" --log {params.psrecord} --include-children --interval 5
		"""

# I'm lazy and cant figure out how to pipe to awk -v
rule format_genotypes:
	input:
		transposed = config['geno_prefix'] + '.t.txt'
	output:
		temp = temp(config['geno_prefix'] + '.t.temp.txt')
	# Remove first three lines of transposed genotype file
	# Remove spaces from genotype file
	shell:
		"""
		sed '1,3d; s/ //g' {input.transposed} > {output.temp}
		"""

# I'm lazy and cant figure out how to pipe to awk -v
rule format_genotypes2:
	input:
		temp = config['geno_prefix'] + '.t.temp.txt',
		sample_ids = config['sample_ids']
	output:
		formatted = config['geno_prefix'] + '.t.format.txt'
	# paste IDs
	shell:
		"""
		awk -v f2={input.temp} ' {{ c = $1; getline < f2; print c, $1; }} ' {input.sample_ids} > {output.formatted}
		"""

rule copy_par:
	resources:
		load = 1
	input:
		par = "source_functions/par/general_varcomp.{model}.par",
		formatted_geno = config['geno_prefix'] + '.t.format.txt'
	output:
		par = "data/derived_data/update_email2020/{model}/general_varcomp.{model}.par",
		moved_geno = "data/derived_data/update_email2020/{model}/genotypes.txt"
	shell:
		"""
		awk '{{printf "%-20s %s\\n", $1, $2}}' {input.formatted_geno} &> {output.moved_geno}
		cp {input.par} {output.par}
		"""

rule renumf90:
	input:
		input_par = "data/derived_data/update_email2020/{model}/general_varcomp.{model}.par",
		datafile = "data/derived_data/update_email2020/{model}/data.txt",
		moved_geno = "data/derived_data/update_email2020/{model}/genotypes.txt",
		pedfile = "data/derived_data/update_email2020/{model}/ped.txt",
		format_map = config['mapfile']
	params:
		dir = "data/derived_data/update_email2020/{model}",
		renumf90_path = config['renumf90_path'],
		renf90_in_name = "general_varcomp.{model}.par",
		renf90_out_name = "renf90.update_email2020.{model}.out"
	output:
		renf90_par = "data/derived_data/update_email2020/{model}/renf90.par"
	shell:
		"""
		cd {params.dir}
		{params.renumf90_path} {params.renf90_in_name} &> {params.renf90_out_name}
		"""

rule airemlf90:
	resources:
		load = 100
	input:
		renf90_par = "data/derived_data/update_email2020/{model}/renf90.par",
		format_map = config['mapfile'],
		moved_geno = "data/derived_data/update_email2020/{model}/genotypes.txt"
	params:
		dir = "data/derived_data/update_email2020/{model}",
		aireml_out_name = "aireml.update_email2020.{model}.out",
		aireml_log_name = "airemlf90.update_email2020.{model}.log",
		aireml_path = config['aireml_path'],
		psrecord = "/storage/hpc/group/UMAG/WORKING/hjdzpd/hair_shed/log/psrecord/ss_blup/airemlf90.update_email2020.{model}.psrecord"
	output:
		aireml_solutions = "data/derived_data/update_email2020/{model}/solutions",
		aireml_log = "data/derived_data/update_email2020/{model}/airemlf90.update_email2020.{model}.log"
	shell:
		"""
		cd {params.dir}
		psrecord "{params.aireml_path} renf90.par &> {params.aireml_out_name}" --log {params.psrecord} --include-children --interval 2
		mv airemlf90.log {params.aireml_log_name}
		rm genotypes*
		"""
