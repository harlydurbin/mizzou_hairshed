# snakemake -s source_functions/blupf90_geno_format.snakefile -j 400 --rerun-incomplete --latency-wait 30 --config --cluster-config source_functions/cluster_config/blupf90_geno_format.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -c {cluster.c} --mem {cluster.mem} --account {cluster.account} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type}" -p &> log/snakemake_log/blupf90_geno_format/200930.blupf90_geno_format.log

import os

configfile: "source_functions/config/blupf90_geno_format.config.yaml"

# Make log directories if they don't exist
os.makedirs("log/slurm_out/blupf90_geno_format", exist_ok = True)
for x in expand("log/slurm_out/blupf90_geno_format/{rules}", rules = config['rules']):
	os.makedirs(x, exist_ok = True)

rule format_all:
	input: config['geno_prefix'] + '.fwf.txt', config['geno_prefix'] + '.chrinfo.txt', config['geno_prefix'] + '.chr_pos.txt'

# Convert PLINK bed/bim/bam to PLINK .raw additive file
rule recode_a:
	input:
		plink = expand("{prefix}.{extension}", prefix = config['geno_prefix'], extension = ['bed', 'bim', 'fam'])
	params:
		plink_module = config['plink_module'],
		nt = config['plink_nt'],
		prefix = config['geno_prefix']
	output:
		recoded = expand("{prefix}.raw", prefix = config['geno_prefix'])
	shell:
		"""
		module load {params.plink_module}
		plink --bfile {params.prefix} --double-id --cow --threads {params.nt} --recode A --out {params.prefix}
		"""

# Match up genotype dump international_id to full_ped full_reg
rule match_id:
	input:
		fam = config['geno_prefix'] + ".fam",
		script = "source_functions/pull_full_reg.R",
		cleaned = "data/derived_data/import_join_clean/cleaned.rds",
		full_ped = "data/derived_data/3gen/full_ped.rds",
		sample_table = config['sample_table']
	params:
		r_module = config['r_module'],
		geno_prefix = config['geno_prefix']
	output:
		full_reg = config['geno_prefix'] + ".full_reg.txt"
	shell:
		"""
		module load {params.r_module}
		Rscript --vanilla {input.script} {params.geno_prefix}
		"""

rule format_genotypes:
	input:
		recoded = config['geno_prefix'] + ".raw"
	output:
		temp = config['geno_prefix'] + '.temp.txt'
	# cut -d " " -f 7- removed first 6 columns
	# 1d removes header line
	# s/ //g removes spaces such that each row is an 850K long string
	shell:
		"""
		cut -d " " -f 7- {input.recoded} | sed '1d; s/ //g' > {output.temp}
		"""

# I'm lazy and cant figure out how to pipe to awk -v
rule append_id:
	input:
		temp = config['geno_prefix'] + '.temp.txt',
		full_reg = config['geno_prefix'] + ".full_reg.txt"
	output:
		formatted = config['geno_prefix'] + '.format.txt'
	# paste IDs
	shell:
		"""
		awk -v f2={input.temp} ' {{ c = $1; getline < f2; print c, $1; }} ' {input.full_reg} > {output.formatted}
		"""

# Some blupf90 programs want a map file as chr:pos
# Some blupf90 programs want a map file as "snp_name chr pos"
# Creates both
rule mapfile:
	input:
		bim = config['geno_prefix'] + '.bim',
		script = "source_functions/blupf90_map.R"
	params:
		geno_prefix = config['geno_prefix'],
		r_module = config['r_module']
	output:
		chrinfo = config['geno_prefix'] + '.chrinfo.txt',
		chr_pos = config['geno_prefix'] + '.chr_pos.txt'
	shell:
		"""
		module load {params.r_module}
		Rscript --vanilla {input.script} {params.geno_prefix}
		"""

rule fwf:
	input:
		formatted = config['geno_prefix'] + '.format.txt',
		conflicts = "data/derived_data/seekparentf90/remove_genotype.txt"
	output:
		fwf = config['geno_prefix'] + '.fwf.txt',
		removed = config['geno_prefix'] + '.removed.txt',
	# awk command creats fixed width file
	# grep command removes genotypes for ids in conflict file
	shell:
		"""
		awk '{{printf "%-20s %s\\n", $1, $2}}' {input.formatted} &> {output.fwf}
		grep -Fxv -f {output.fwf} {input.conflicts} > {output.removed}
		"""
