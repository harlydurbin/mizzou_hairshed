# snakemake -s source_functions/grm_inbreeding.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/grm_inbreeding.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/grm_inbreeding/201020.grm_inbreeding.log

import os

configfile: "source_functions/config/grm_inbreeding.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/grm_inbreeding", exist_ok = True)
for x in expand("log/slurm_out/grm_inbreeding/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

rule all:
	input: expand("data/derived_data/grm_inbreeding/mizzou_hairshed.grm.{extension}", extension = ['gz', 'id'])

rule gcta_grm:
	input:
		plink = expand("{geno_prefix}.qc.{extension}", geno_prefix = config['geno_prefix'], extension = ['bed', 'bim', 'fam'])
	params:
		gcta_path = config['gcta_path'],
		mpi_module = config['mpi_module'],
		in_prefix = config['geno_prefix'] + '.qc',
		threads = config['gcta_grm_threads'],
		out_prefix = "data/derived_data/grm_inbreeding/mizzou_hairshed"
	output:
		grm_gz = "data/derived_data/grm_inbreeding/mizzou_hairshed.grm.gz",
		id = "data/derived_data/grm_inbreeding/mizzou_hairshed.grm.id"
	shell:
		"""
		export OMPI_MCA_btl_openib_if_include='mlx5_3:1'
		module load {params.mpi_module}
		{params.gcta_path} --bfile {params.in_prefix} --autosome-num 29 --autosome --make-grm-gz --make-grm-alg 1 --thread-num {params.threads} --out {params.out_prefix}
		"""

rule pull_diagonal:
	input:
		grm_gz = "data/derived_data/grm_inbreeding/mizzou_hairshed.grm.gz"
	output:
		diagonal = "data/derived_data/grm_inbreeding/mizzou_hairshed.diagonal.txt"
	shell:
		"""
		gzip -cd {input.grm_gz}| awk '{{if($1 == $2) print}}' > {output.diagonal}
		"""
