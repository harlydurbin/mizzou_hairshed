# Code and analyses associated with the Mizzou Hair Shedding Project

## Data import, joining, and cleaning

Run `source_functions/import_joint_clean.R` to generate `data/derived_data/cleaned.rds`. 

* Takes a "blacklist" of farm ID/year combinations to ignore as arguments. I.e., to ignore PVF 2019 data and WAA 2018 data, `Rscript --vanilla source_functions/import_join_clean.R "PVF_2019" "WAA_2018"`
* Imports `source_functions/first_clean.R` to iteratively filter & tidy data on a farm-by-farm basis. 
    + `source_functions/iterative_id_search.R` used to match up animals to Lab IDs using different combinations of Mizzou Hair Shedding Project identifiers and Animal Table columns
    + Thompson Research Farm (UMCT) data wasn't stored in the Animal Table like other farms so it's cleaned in a different way using `data/derived_data/import_join_clean/umct_id_key.csv`
* Arkansas data cleaned in `management/arkansas.Rmd` and imported from `data/derived_data/import_join_clean/ua_clean.Rds`
* Uses `source_functions/impute_age.R` to impute missing ages when ages in other years were recorded
    + When DOB available, "age class" is (n*365d)-90d to ((n+1)*365d)-90d, where n is the age classification and d is days. This means that animals that aren't actually one year of age can still be classified as yearlings and so on. 
    + Scores on animals less than 275 days (i.e., 365-90) old removed
* All records from animals with differing sexes across multiple years removed
