# snakemake -s source_functions/gxe_gwas.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/gxe_gwas.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/gxe_gwas/201214.gxe_gwas.log

import os

configfile: "source_functions/config/gxe_gwas.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/gxe_gwas", exist_ok = True)
for x in expand("log/slurm_out/gxe_gwas/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

os.makedirs("log/psrecord/gxe_gwas", exist_ok = True)
os.makedirs("log/psrecord/gxe_gwas/gemma", exist_ok = True)

rule all:
	input: expand("data/derived_data/gxe_gwas/{var}/{year}/", var = config['var'], year = config['year'])

rule gemma_grm:
	input:
		bed = expand("{geno_prefix}.qc.bed", geno_prefix = config['geno_prefix']),
		bim = expand("{geno_prefix}.qc.bim", geno_prefix = config['geno_prefix']),
		fam = expand("{geno_prefix}.qc.fam", geno_prefix = config['geno_prefix'])
	params:
		gemma_path = config['gemma_path'],
		in_prefix = config['geno_prefix'] + ".qc",
		grm_type = config['grm_type'],
		out_prefix = "data/derived_data/gxe_gwas/gemma_grm.s"
	output:
		grm_s = "data/derived_data/gxe_gwas/gemma_grm.s."
	shell:
		"""
		sed -i 's/-9/pheno/g' {input.fam}
		{params.gemma_path} -bfile {params.in_prefix} -gk 2 -o {params.out_prefix}
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
		manual_fam = "data/derived_data/gxe_gwas/{var}/{year}/manual_fam.fam",
		keep_sort = "data/derived_data/gxe_gwas/{var}/{year}/keep_sort.txt",
		design_matrix = "data/derived_data/gxe_gwas/{var}/{year}/design_matrix.txt",
		gxe = "data/derived_data/gxe_gwas/{var}/{year}/gxe.txt"
	shell:
		"""
		module load {params.r_module}
		Rscript --vanilla {input.script} {params.geno_prefix} {params.year} {params.var}
		"""

rule plink_keep_sort
	input:
		keep_sort = "data/derived_data/gxe_gwas/{var}/{year}/keep_sort.txt",
		plink = expand("{geno_prefix}.qc.{extension}", geno_prefix = config['geno_prefix'], extension = ['bed', 'bim', 'fam'])
	params:
		plink_module = config['plink_module'],
		in_prefix = config['geno_prefix'] + '.qc',
		plink_nt = config['plink_nt'],
		out_prefix = "data/derived_data/gxe_gwas/{var}/{year}/gxe_gwas.{var}.{year}"
	output:
		plink = expand("data/derived_data/gxe_gwas/{{var}}/{{year}}/gxe_gwas.{{var}}.{{year}}.{extension}", prefix = config['geno_prefix'], extension = ['bed', 'bim', 'fam'])
	shell:
		"""
		module load {params.plink_module}
		plink --bfile {params.in_prefix} --double-id --cow --threads {params.plink_nt} --keep {input.keep_sort} --indiv-sort f {input.keep_sort} --make-bed --out {params.prefix_out}
		"""

rule replace_fam:
	input:
		manual_fam = "data/derived_data/gxe_gwas/{var}/{year}/manual_fam.fam",
		plink_fam = "data/derived_data/gxe_gwas/{var}/{year}/gxe_gwas.{var}.{year}.fam"
	output:
	# Keep the file I'm replacing for sanity check purposes bc I'm paranoid
		old_fam = "data/derived_data/gxe_gwas/{var}/{year}/replaced_fam.fam"
	shell:
		"""
		mv {input.plink_fam} {output.old_fam}
		mv {input.manual_fam} {input.plink_fam}
		"""

rule gemma:
	input:
		plink = expand("data/derived_data/gxe_gwas/{{var}}/{{year}}/gxe_gwas.{{var}}.{{year}}.{extension}", prefix = config['geno_prefix'], extension = ['bed', 'bim', 'fam']),
		old_fam = "data/derived_data/gxe_gwas/{var}/{year}/replaced_fam.fam",
		design_matrix = "data/derived_data/gxe_gwas/{var}/{year}/design_matrix.txt",
		gxe = "data/derived_data/gxe_gwas/{var}/{year}/gxe.txt",
		grm_s = "data/derived_data/gxe_gwas/gemma_grm.s."
	params:
		gemma_path = config['gemma_path'],
		plink_prefix = "data/derived_data/gxe_gwas/{var}/{year}/gxe_gwas.{var}.{year}",
		out_prefix = "gxe_gwas.{var}.{year}",
		out_dir = "data/derived_data/gxe_gwas/{var}/{year}/",
		psrecord = "log/psrecord/gxe_gwas/gemma/gxe_gwas.{var}.{year}.psrecord"
	output:
		assoc = "data/derived_data/gxe_gwas/{var}/{year}/gxe_gwas.{var}.{year}.assoc.txt",
	shell:
		"""
		psrecord "{params.gemma_path} -bfile {params.plink_prefix} -k {input.grm_s} -lmm 1 -c {input.design_matrix} -gxe {input.gxe} -outdir {params.out_dir}" --log {params.psrecord} --include-children --interval 5
		"""
