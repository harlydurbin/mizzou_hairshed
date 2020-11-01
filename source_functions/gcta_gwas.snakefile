# snakemake -s source_functions/gcta_gwas.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/gcta_gwas.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/gcta_gwas/201101.gcta_gwas.log

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
		script = "source_functions/setup.gcta_gwas.R",
		solutions = lambda wildcards: expand("{dir}/solutions", dir = config['dir'][wildcards.model]),
		ped = lambda wildcards: expand("{dir}/renadd0{animal_effect}.ped", dir = config['dir'][wildcards.model], animal_effect = config['animal_effect'][wildcards.model]),
		accuracy_script = "source_functions/calculate_acc.R",
		full_ped = "data/derived_data/3gen/full_ped.rds"
	params:
		r_module = config['r_module'],
		dir = lambda wildcards: expand("{dir}", dir = config['dir'][wildcards.model]),
		animal_effect = lambda wildcards: expand("{animal_effect}", animal_effect = config['animal_effect'][wildcards.model]),
		gen_var = lambda wildcards: expand("{gen_var}", gen_var = config['gen_var'][wildcards.model]),
		h2 = lambda wildcards: expand("{gen_var}", gen_var = config['h2'][wildcards.model])
	output:
		pheno = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/pheno.txt",
		keep_list = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/keep_list.txt"
	shell:
		"""
		module load {params.r_module}
		Rscript --vanilla {input.script} {params.dir} {params.animal_effect} {params.gen_var} {params.h2}
		"""

rule grm_keep:
	input:
		keep_list = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/keep_list.txt"
	params:
		plink_module = config['plink_module'],
		geno_prefix = config['geno_prefix'] + '.qc',
		nt = config['plink_nt'],
		prefix_out = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/{model}"
	output:
		plink = expand("/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{{model}}/{{model}}.{extension}", extension = ['bed', 'bim', 'fam'])
	shell:
		"""
		module load {params.plink_module}
		plink --bfile {params.geno_prefix} --double-id --cow --threads {params.nt} --keep {input.keep_list} --make-bed --out {params.prefix_out}
		"""

rule gcta_grm:
	input:
		plink = expand("/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{{model}}/{{model}}.{extension}", extension = ['bed', 'bim', 'fam'])
	params:
		gcta_path = config['gcta_path'],
		mpi_module = config['mpi_module'],
		prefix = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/{model}",
		nt = config['gcta_grm_threads']
	output:
		grm_gz = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/{model}.grm.gz",
		id = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/{model}.grm.id"
	shell:
		"""
		export OMPI_MCA_btl_openib_if_include='mlx5_3:1'
		module load {params.mpi_module}
		{params.gcta_path} --bfile {params.prefix} --autosome-num 29 --autosome --make-grm-gz --make-grm-alg 1 --thread-num {params.nt} --out {params.prefix}
		"""

rule mlma:
	input:
		plink = expand("{geno_prefix}.qc.{extension}", geno_prefix = config['geno_prefix'], extension = ['bed', 'bim', 'fam']),
		grm_gz = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/{model}.grm.gz",
		pheno = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/pheno.txt"
	params:
		gcta_path = config['gcta_path'],
		mpi_module = config['mpi_module'],
		in_prefix = config['geno_prefix'] + '.qc',
		threads = config['mlma_threads'],
		grm_prefix = "/storage/hpc/group/UMAG/WORKING/hjdzpd/mizzou_hairshed/data/derived_data/gcta_gwas/{model}/{model}",
		out_prefix = "data/derived_data/gcta_gwas/{model}/{model}"
	output:
		out = "data/derived_data/gcta_gwas/{model}/{model}.mlma"
	shell:
		"""
		export OMPI_MCA_btl_openib_if_include='mlx5_3:1'
		module load {params.mpi_module}
		{params.gcta_path} --mlma --bfile {params.in_prefix} --pheno {input.pheno} --grm-gz {params.grm_prefix}  --thread-num {params.threads} --out {params.out_prefix}
		"""
