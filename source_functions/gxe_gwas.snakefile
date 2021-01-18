# snakemake -s source_functions/gxe_gwas.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/gxe_gwas.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/gxe_gwas/210113.gxe_gwas.log

import os

configfile: "source_functions/config/gxe_gwas.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/gxe_gwas", exist_ok = True)
for x in expand("log/slurm_out/gxe_gwas/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

os.makedirs("log/psrecord/gxe_gwas", exist_ok = True)
os.makedirs("log/psrecord/gxe_gwas/gemma", exist_ok = True)

rule all:
	input: expand("data/derived_data/gxe_gwas/{var}/{year}/result.assoc.txt", var = config['var'], year = config['year'])

rule gemma_grm:
	input:
		bed = expand("{geno_prefix}.qc.bed", geno_prefix = config['geno_prefix']),
		bim = expand("{geno_prefix}.qc.bim", geno_prefix = config['geno_prefix']),
		fam = expand("{geno_prefix}.qc.fam", geno_prefix = config['geno_prefix'])
	params:
		gemma_path = config['gemma_path'],
		in_prefix = config['geno_prefix'] + ".qc",
		out_prefix = "gemma_grm",
		out_dir = "data/derived_data/gxe_gwas"
	output:
		grm = "data/derived_data/gxe_gwas/gemma_grm.sXX.txt"
	shell:
		"""
		sed -i 's/-9/pheno/g' {input.fam}
		{params.gemma_path} -bfile {params.in_prefix} -gk 2 -o {params.out_prefix} -outdir {params.out_dir}
		"""

rule setup_data:
	input:
		script = "source_functions/setup.gxe_gwas.R",
		cleaned = "data/derived_data/import_join_clean/cleaned.rds",
		full_ped = "data/derived_data/3gen/full_ped.rds",
		weather_data = "data/derived_data/environmental_data/weather.rds",
		coord_key = "data/derived_data/environmental_data/coord_key.csv",
		full_fam = config['geno_prefix'] + ".qc.fam"
	params:
		r_module = config['r_module'],
		geno_prefix = config['geno_prefix'],
		year = "{year}",
		var = "{var}"
	output:
		manual_fam = "data/derived_data/gxe_gwas/{var}/{year}/gxe_gwas.{var}.{year}.fam",
		design_matrix = "data/derived_data/gxe_gwas/{var}/{year}/design_matrix.txt",
		gxe = "data/derived_data/gxe_gwas/{var}/{year}/gxe.txt"
	shell:
		"""
		module load {params.r_module}
		Rscript --vanilla {input.script} {params.geno_prefix} {params.year} {params.var}
		"""

rule copy_plink:
	input:
		bed = expand("{geno_prefix}.qc.bed", geno_prefix = config['geno_prefix']),
		bim = expand("{geno_prefix}.qc.bim", geno_prefix = config['geno_prefix'])
	params:
		plink_module = config['plink_module'],
		in_prefix = config['geno_prefix'] + '.qc',
		plink_nt = config['plink_nt'],
		out_prefix = "data/derived_data/gxe_gwas/{var}/{year}/gxe_gwas.{var}.{year}"
	output:
		bed = "data/derived_data/gxe_gwas/{var}/{year}/gxe_gwas.{var}.{year}.bed",
		bim = "data/derived_data/gxe_gwas/{var}/{year}/gxe_gwas.{var}.{year}.bim"
	shell:
		"""
		cp {input.bed} {output.bed}
		cp {input.bim} {output.bim}
		"""

rule gemma:
	input:
		plink = expand("data/derived_data/gxe_gwas/{{var}}/{{year}}/gxe_gwas.{{var}}.{{year}}.{extension}", prefix = config['geno_prefix'], extension = ['bed', 'bim', 'fam']),
		design_matrix = "data/derived_data/gxe_gwas/{var}/{year}/design_matrix.txt",
		gxe = "data/derived_data/gxe_gwas/{var}/{year}/gxe.txt",
		grm = "data/derived_data/gxe_gwas/gemma_grm.sXX.txt"
	params:
		gemma_path = config['gemma_path'],
		plink_prefix = "data/derived_data/gxe_gwas/{var}/{year}/gxe_gwas.{var}.{year}",
		out_prefix = "gxe_gwas.{var}.{year}",
		out_dir = "data/derived_data/gxe_gwas/{var}/{year}",
		psrecord = "log/psrecord/gxe_gwas/gemma/gxe_gwas.{var}.{year}.psrecord"
	output:
		assoc = "data/derived_data/gxe_gwas/{var}/{year}/result.assoc.txt"
	shell:
		"""
		psrecord "{params.gemma_path} -bfile {params.plink_prefix} -k {input.grm} -lmm 1 -c {input.design_matrix} -gxe {input.gxe} -outdir {params.out_dir}" --log {params.psrecord} --include-children --interval 5
		"""
