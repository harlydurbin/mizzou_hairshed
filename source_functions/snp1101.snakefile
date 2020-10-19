# snakemake -s source_functions/snp1101.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/snp1101.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" --until airemlf90 -p &> log/snakemake_log/snp1101/201016.snp1101.log

import os

configfile: "source_functions/config/snp1101.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/snp1101", exist_ok = True)
for x in expand("log/slurm_out/snp1101/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

rule all:
	input: expand("data/derived_data/snp1101/{model}/out/gwas_ssr_p_fdr_gw_{model}_bvs.txt", model = config['model'])

rule setup_snp1101:
	input:
		solutions = lambda wildcards: expand("{solutions}", solutions = config['solutions'][wildcards.model]),
		ped = lambda wildcards: expand("{ped}", ped = config['ped'][wildcards.model]),
		script = "source_functions/setup.snp1101.{model}.R"
	params:
		r_module = config['r_module']
	output:
		traitfile = "data/derived_data/snp1101/{model}/trait.txt"
	shell:
		"""
		module load {params.r_module}
		Rscript --vanilla {input.script} {input.solutions} {input.ped}
		"""

rule snp1101:
	input:
		traitfile = "data/derived_data/snp1101/{model}/trait.txt",
		ctr = "source_functions/par/snp1101.{model}.ctr",
		fwf = config['geno_prefix'] + '.fwf.txt',
		map = config['geno_prefix'] + '.chrinfo.txt'
	params:
		snp1101_path = config['snp1101_path'],
		mpi_module = config['mpi_module']
	output:
		report = "data/derived_data/snp1101/{model}/out/report.txt",
		bvs_p = "data/derived_data/snp1101/{model}/out/gwas_ssr_{model}_bvs_p.txt",
		excluded_indv = "data/derived_data/snp1101/{model}/out/excluded_indv.txt",
		excluded_snp = "data/derived_data/snp1101/{model}/out/excluded_snp.txt",
		ctr = "data/derived_data/snp1101/{model}/out/snp1101.{model}.ctr",
		ped_single_id = "data/derived_data/snp1101/{model}/out/ped_single_id.txt"
	shell:
		"""
		module load {params.mpi_module}
		{params.snp1101_path} {input.ctr}
		"""
