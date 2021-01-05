
configfile: "source_functions/config/bias.yaml"

rule target:
	input:
		targ = expand("data/derived_data/estimate_bias/{model}/iter{iter}/airemlf90.{model}.iter{iter}.log", iter = config['iter'])

rule setup_data:
	input:
		# Data from full AIREML run for specified model
		data = "data/derived_data/aireml_varcomp/{model}/data.txt"
	output:
		start = "data/derived_data/start.rds"
	shell:
		"""
		Rscript --vanilla source_functions/start.R &> log/rule_log/start/start.log
		"""

rule pull_genotypes:
	resources:
		load = 1
	input:
		pull_list = "data/derived_data/estimate_bias/iter{iter}/pull_list.txt",
		master_geno = config['master_geno']
	output:
		reduced_geno = "data/derived_data/estimate_bias/iter{iter}/genotypes.txt"
	shell:
	# https://www.gnu.org/software/gawk/manual/html_node/Printf-Examples.html
		"""
		grep -Fwf {input.pull_list} {input.master_geno} | awk '{{printf "%-20s %s\\n", $1, $2}}' &> {output.reduced_geno}
		"""

rule renumf90:
	resources:
		load = 1
	input:
		input_par = "data/derived_data/estimate_bias/iter{iter}/bias.par",
		reduced_geno = "data/derived_data/estimate_bias/iter{iter}/genotypes.txt",
		datafile = "data/derived_data/estimate_bias/iter{iter}/data.txt",
		pedfile = "data/derived_data/estimate_bias/iter{iter}/ped.txt",
		format_map = "data/derived_data/chrinfo.imputed_hair.txt"
	params:
		dir = "data/derived_data/estimate_bias/iter{iter}",
		renumf90_path = config['renumf90_path']
	output:
		renf90_par = "data/derived_data/estimate_bias/iter{iter}/renf90.par"
	shell:
		"""
		cd {params.dir}
		{params.renumf90_path} bias.par &> renf90.bias.out
		"""

rule airemlf90:
	resources:
		load = 50
	input:
		renf90_par = "data/derived_data/estimate_bias/iter{iter}/renf90.par",
		format_map = "data/derived_data/chrinfo.imputed_hair.txt",
		reduced_geno = "data/derived_data/estimate_bias/iter{iter}/genotypes.txt"
	params:
		dir = "data/derived_data/estimate_bias/iter{iter}",
		aireml_out_name = "aireml.{model}.iter{iter}.out",
		aireml_log = "airemlf90.{model}.iter{iter}.log",
		aireml_path = config['aireml_path']
	output:
		aireml_solutions = "data/derived_data/estimate_bias/iter{iter}/solutions",
		aireml_log = "data/derived_data/estimate_bias/iter{iter}/airemlf90.{model}.iter{iter}.log"
	shell:
		"""
		cd {params.dir}
		{params.aireml_path} renf90.par &> {params.aireml_out_name}
		mv airemlf90.log {params.aireml_log}
		rm genotypes*
		"""
