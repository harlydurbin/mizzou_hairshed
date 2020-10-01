# snakemake -s source_functions/seekparentf90.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/seekparentf90.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/seekparentf90/200930.seekparentf90.log

import os

configfile: "source_functions/config/seekparentf90.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/seekparentf90", exist_ok = True)
for x in expand("log/slurm_out/seekparentf90/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

rule seekparent_all:
	input: "data/derived_data/seekparentf90/Check_Parent_Pedigree.txt"

rule setup:
	input:
		fwf = config['geno_prefix'] + '.fwf.txt',
		blupf90_ped = "data/derived_data/3gen/blupf90_ped.txt",
		chr_info = config['geno_prefix'] + '.chr_info.txt'
	output:
		genotypes = "data/derived_data/seekparentf90/genotypes.txt",
		ped = "data/derived_data/seekparentf90/ped.txt",
		map = "data/derived_data/seekparentf90/map.txt"
	shell:
		"""
		cp {input.fwf} {output.genotypes}
		cp {input.blupf90_ped} {output.ped}
		cp {input.chr_info} {output.map}
		"""

rule seekparentf90:
	input:
		genotypes = "data/derived_data/seekparentf90/genotypes.txt",
		ped = "data/derived_data/seekparentf90/ped.txt",
		map = "data/derived_data/seekparentf90/map.txt"
	params:
		path = config['seekparentf90_path'],
		directory = "data/derived_data/seekparentf90",
		seektype = config['seektype']
	output:
		check = "data/derived_data/seekparentf90/Check_Parent_Pedigree.txt"
	shell:
		"""
		cd {params.directory}
		ulimit -s unlimited
		{params.path} --pedfile ped.txt --snpfile genotypes.txt --mapfile map.txt --seektype {params.seektype} --trio --maxsnp 1000000 --full_log_checks --duplicate --chr_x 30
		"""
