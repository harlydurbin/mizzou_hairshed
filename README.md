# Code and analyses associated with the Mizzou Hair Shedding Project

## Data import, joining, and cleaning

Run `source_functions/import_joint_clean.R` to generate `data/derived_data/cleaned.rds`. 

* Takes a "blacklist" of farm ID/year combinations to ignore as arguments. I.e., to ignore PVF 2019 data and WAA 2018 data, `Rscript --vanilla source_functions/import_join_clean.R "PVF_2019" "WAA_2018"`
* Imports `source_functions/first_clean.R` to iteratively filter & tidy data on a farm-by-farm basis. 
    + `source_functions/iterative_id_search.R` used to match up animals to Lab IDs using different combinations of Mizzou Hair Shedding Project identifiers and Animal Table columns
    + Thompson Research Farm (UMCT) data wasn't stored in the Animal Table like other farms so it's cleaned in a different way using `data/derived_data/import_join_clean/umct_id_key.csv`
* Arkansas data cleaned in `management/arkansas.Rmd` and imported from `data/derived_data/import_join_clean/ua_clean.Rds`
* Uses `source_functions/impute_age.R` to impute missing ages when ages in other years were recorded
