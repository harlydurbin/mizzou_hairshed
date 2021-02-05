# snakemake -s source_functions/genewalk.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/genewalk.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/genewalk/210205.genewalk.log

import os

configfile: "source_functions/config/genewalk.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/genewalk", exist_ok = True)
for x in expand("log/slurm_out/genewalk/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

rule all:
	input:
		expand("data/derived_data/genewalk/{dataset}/genewalk_results.csv", dataset = config['dataset'])

rule genewalk:
	input:
		ortholog = "data/derived_data/genewalk/{dataset}/ortholog.{dataset}.txt"
	params:
		dataset = "{dataset}",
		nproc = config['nproc'],
		fdr = config['fdr'],
		log = "data/derived_data/genewalk/{dataset}/genewalk.{dataset}.log"
	output:
		result = "data/derived_data/genewalk/{dataset}/genewalk_results.csv"
	shell:
		"genewalk --project {params.dataset} --genes {input.ortholog} --id_type ensembl_id --base_folder data/derived_data/genewalk --alpha_fdr {params.fdr} --nproc {params.nproc} &> {params.log}"
