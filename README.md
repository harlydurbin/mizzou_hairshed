# Code and analyses associated with the Mizzou Hair Shedding Project

## Data import, joining, and cleaning

Run `source_functions/import_joint_clean.R` to generate `data/derived_data/cleaned.rds`. 

* Takes a "blacklist" of farm ID/year combinations to ignore as arguments. I.e., to ignore PVF 2019 data and WAA 2018 data, `Rscript --vanilla source_functions/import_join_clean.R "PVF_2019" "WAA_2018"`
* Imports `source_functions/first_clean.R` to iteratively filter & tidy data on a farm-by-farm basis. 
    + `source_functions/iterative_id_search.R` used to match up animals to Lab IDs using different combinations of Mizzou Hair Shedding Project identifiers and Animal Table columns
    + When an animal matches up to more than one lab ID, keeps the most recent one (unless the most recent Lab ID comes from the summer 2020 ASA/RAAA genotype share)
    + Thompson Research Farm (UMCT) data wasn't stored in the Animal Table like other farms so it's cleaned in a different way using `data/derived_data/import_join_clean/umct_id_key.csv`
* Arkansas data cleaned in `management/arkansas.Rmd` and imported from `data/derived_data/import_join_clean/ua_clean.Rds`
* Uses `source_functions/impute_age.R` to impute missing ages when ages in other years were recorded
    + When DOB available, "age class" is (n*365d)-90d to ((n+1)*365d)-90d, where n is the age classification and d is days. This means that animals that aren't actually one year of age can still be classified as yearlings and so on. 
    + Scores on animals less than 275 days (i.e., 365-90) old removed
* Miscellaneous data cleaning:
    + All records from animals with differing sexes across multiple years removed
    + All punctuation and spaces removed from animal IDs
    + "AMGV" prefix added to all American Gelbvieh Association registration numbers to match Animal Table
    + Coat colors codes, calving season codes, toxic fescue grazing status codes, and breed codes standardized
    
Final cleaned data stored in `data/derived_data/import_join_clean/cleaned.rds`
    
### `cleaned` column descriptions

* `year`: Data recording year ranging from 2012-2020
* `farm_id`: 3-digit identifier used in UMAG Tissue Table for farm or ranch where scores was collected
* `breed_code`: 2-4 digit identifier used in UMAG Animal Table, reported by breeder. One of:

| `breed_code` | Breed                         | Breed association                            |
|--------------|-------------------------------|----------------------------------------------|
| AN           | Angus                         | American Angus Association                   |
| ANR          | Red Angus                     | Red Angus Association of America             |
| BG           | Brangus, including UltraBlack | International Brangus Breeders Association   |
| CHA          | Charolais                     | American International Charolais Association |
| CHIA         | Chianina                      | American Chianina Association                |
| CROS         | Mixed/crossbred cattle        | Non-registered crossbred cattle              |
| GEL          | Gelbvieh, including Balancers | American Gelbvieh Association                |
| HFD          | Hereford                      | American Hereford Association                |
| MAAN         | Maine-Anjou                   | American Maine-Anjou Association             |
| SH           | Shorthorn                     | American Shorthorn Association               |
| SIM          | Simmental, including SimAngus | American Simmental Association               |
| SIMB         | Simbrah                       | American Simmental Association               |

* `registration_number`: Registration number associated with `breed_code`, can be `NA`
* `animal_id`: Unique identification for the animal, which must remain the same across years. Ear tag, tattoo, freeze brand, or other herd ID used when collecting the hair score. No limit on length
* `sex`: M or F
* `color`: Breeder-reported coat color. One of:

| `color`          |
|------------------|
| BLACK            |
| BLACK ROAN       |
| BLACK WHITE FACE |
| BRINDLE          |
| BROWN            |
| GREY             |
| RED              |
| RED ROAN         |
| RED WHITE FACE   |
| WHITE            |
| YELLOW           |

* `Lab_ID`: Identifier used to match animal to UMAG Animal Table
* `date_score_recorded`: Breeder-reported date when hair shedding score was collected, formatted as YYYY-MM-DD. This in NOT the date DNA sample was collected.
* `hair_score`: Integer between 1-5
* `age`: Integer between 1-21
* `calving_season`: Breeder-reported season when last calf was born. One of `SPRING` or `FALL` for females, `NA` for bulls. June 30 is the cut-off for spring and fall calving.
* `toxic_fescue`: Was the animal grazed on toxic fescue during the spring of the recording year? One of `TRUE` or `FALSE`
* `comment`: Breeder-reported comments about the animal, including additional information about breed makeup. Comments could include descriptions such as muddy, long rear hooves, lost tail switch, black hided cattle with brown backs, etc. Producers can also note any feed supplements the animals were given.
* `barcode`: Barcode of blood card, hair card, or TSU submitted for genotyping through the project
* `sold`: Has the animal been sold, died, or left the herd? Retroactively updated for previous years once breeder indicates scores will no longer be collected on the animal
* `dob`: Date of birth, formatted as YYYY-MM-DD


