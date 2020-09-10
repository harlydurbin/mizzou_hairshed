# snakemake -s source_functions/sommer_mod.snakefile -j 8 --rerun-incomplete --latency-wait 60 --config --cluster-config source_functions/cluster/sommer_mod.cluster.json --cluster "sbatch -p {cluster.p} -o {cluster.o} --account {cluster.account} -t {cluster.t} -n {cluster.n} --mem {cluster.mem} --mail-user {cluster.mail-user} --mail-type {cluster.mail-type} --qos {cluster.qos}" -p &> log/snakemake_log/190504.sommer_mod.log

# snakemake -s source_functions/sommer_mod.snakefile -np --unlock &> dryrun.txt

# module load r/r-3.5.2-python-2.7.14-tk
configfile : "source_functions/config/190504.sommer_mod.config.json"

rule target:
	input:
		targ = expand("data/derived_data/sommer/reduce_full/{mod}.{rundate}.resid.csv",
		rundate = config['rundate'],
		mod = config['mod']),
		targ2 = expand("data/derived_data/sommer/cross_val/{mod}_cv{cv}.{rundate}.rds",
		rundate = config['rundate'],
		mod = 'reduced_fct_age',
		cv = config['cv']),
		targ3 = expand("data/derived_data/sommer/reduce_cv/{mod}_cv{cv}.{rundate}.beta.csv",
		rundate = config['rundate'],
		mod = ['reduced_fct_age'],
		cv = config['cv'])



rule sommer_mod:
	input:
		rscript = "source_functions/sommer/{rule}/sommer.{mod}.R",
		pheno = "data/derived_data/pheno.rds",
		grm = "data/raw_data/grm_raw.rds"
	benchmark:
		"benchmarks/sommer/{rule}/{mod}.{rundate}.benchmark"
	log:
		"log/snakemake_log/sommer/{rule}/{mod}.{rundate}.snakelog"
	output:
		rds = "data/derived_data/sommer/{rule}/{mod}.{rundate}.rds"
	params:
		scriptstring = "source_functions/sommer/{rule}/sommer.{mod}.R {rundate}"
	shell:
		"Rscript --vanilla {params.scriptstring}"

rule reduce_full:
	input:
		rds = "data/derived_data/sommer/sommer_mod/{mod}.{rundate}.rds",
		script = "source_functions/reduce_sommer.R"
	benchmark:
		"benchmarks/sommer/{rule}/{mod}.{rundate}.benchmark"
	log:
		"log/snakemake_log/sommer/{rule}/{mod}.{rundate}.snakelog"
	output:
		blup = "data/derived_data/sommer/{rule}/{mod}.{rundate}.blup.csv",
		varcomp = "data/derived_data/sommer/{rule}/{mod}.{rundate}.varcomp.csv",
		beta = "data/derived_data/sommer/{rule}/{mod}.{rundate}.beta.csv",
		aic_bic = "data/derived_data/sommer/{rule}/{mod}.{rundate}.aic_bic.csv",
		resid = "data/derived_data/sommer/{rule}/{mod}.{rundate}.resid.csv"
	params:
		nm = "{mod}.{rundate}",
		which = "{rule}",
		where = "sommer_mod"
	shell:
		"Rscript --vanilla source_functions/reduce_sommer.R {params.nm} {params.which} {params.where}"

# This is "too ambiguous" and won't run but I don't have time to fix it or care

rule cross_val:
	input:
		rscript = "source_functions/sommer/{rule}/cv.{mod}.R",
		pheno = "data/derived_data/pheno_cv.rds",
		grm = "data/raw_data/grm_raw.rds"
	benchmark:
		"benchmarks/sommer/{rule}/{mod}_cv{cv}.{rundate}.benchmark"
	log:
		"log/snakemake_log/sommer/{rule}/{mod}_cv{cv}.{rundate}.snakelog"
	output:
		rds = "data/derived_data/sommer/{rule}/{mod}_cv{cv}.{rundate}.rds"
	params:
		nm = "{mod}_cv{cv}.{rundate}",
		cv = "{cv}",
		scriptstring = "source_functions/sommer/{rule}/cv.{mod}.R"
	shell:
		"Rscript --vanilla {params.scriptstring} {params.nm} {params.cv}"

rule reduce_cv:
	input:
		rds = "data/derived_data/sommer/cross_val/{mod}_cv{cv}.{rundate}.rds",
		script = "source_functions/reduce_sommer.R"
	benchmark:
		"benchmarks/sommer/{rule}/{mod}_cv{cv}.{rundate}.benchmark"
	log:
		"log/snakemake_log/sommer/{rule}/{mod}_cv{cv}.{rundate}.snakelog"
	output:
		blup = "data/derived_data/sommer/{rule}/{mod}_cv{cv}.{rundate}.blup.csv",
		varcomp = "data/derived_data/sommer/{rule}/{mod}_cv{cv}.{rundate}.varcomp.csv",
		beta = "data/derived_data/sommer/{rule}/{mod}_cv{cv}.{rundate}.beta.csv",
		aic_bic = "data/derived_data/sommer/{rule}/{mod}_cv{cv}.{rundate}.aic_bic.csv",
		resid = "data/derived_data/sommer/{rule}/{mod}_cv{cv}.{rundate}.resid.csv"
	params:
		nm = "{mod}_cv{cv}.{rundate}",
		which = "{rule}",
		where = "cross_val"
	shell:
		"Rscript --vanilla source_functions/reduce_sommer.R {params.nm} {params.which} {params.where}"
