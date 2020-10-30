# snakemake -s source_functions/gcta_gwas.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/gcta_gwas.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/gcta_gwas/201030.gcta_gwas.log

import os

configfile: "source_functions/config/gcta_gwas.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/gcta_gwas", exist_ok = True)
for x in expand("log/slurm_out/gcta_gwas/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

rule all:
	input: expand("data/derived_data/gcta_gwas/{model}/{model}.mlma", model = config['model'])

rule pheno_file:
	input:
		script = "source_functions/setup.gcta_gwas.{model}.R",
		cleaned = "data/derived_data/import_join_clean/cleaned.rds",
		genotyped = "data/derived_data/grm_inbreeding/mizzou_hairshed.diagonal.full_reg.csv",
		breed_key = "data/derived_data/breed_key/breed_key.rds",
		score_groups = "data/derived_data/score_groups.xlsx",
		full_ped = "data/derived_data/3gen/full_ped.rds"
	params:
		r_module = config['r_module']
	output:
		pheno = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/pheno.txt",
		covar = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/covar.txt"
	shell:
		"""
		module load {params.r_module}
		Rscript --vanilla {input.script}
		"""

rule mlma:
	input:
		plink = expand("{geno_prefix}.qc.{extension}", geno_prefix = config['geno_prefix'], extension = ['bed', 'bim', 'fam']),
		grm = expand("{grm}", grm = config['grm_path']),
		pheno = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/pheno.txt",
		covar = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/covar.txt"
	params:
		gcta_path = config['gcta_path'],
		mpi_module = config['mpi_module'],
		in_prefix = config['geno_prefix'] + '.qc',
		threads = config['mlma_threads'],
		out_prefix = "data/derived_data/gcta_gwas/{model}/{model}"
	output:
		out = "data/derived_data/gcta_gwas/{model}/{model}.mlma"
	shell:
		"""
		export OMPI_MCA_btl_openib_if_include='mlx5_3:1'
		module load {params.mpi_module}
		{params.gcta_path} --mlma --bfile {params.in_prefix} --pheno {input.pheno} --covar {input.covar} --grm-gz {input.grm}  --thread-num {params.threads} --out {params.out_prefix}
		"""
