
library(sommer)

phenotypes <- base::readRDS("phenotypes_uni.RDS")

grm <- base::readRDS("grm.RDS")

pre_adjust <- sommer::mmer2(HairScore2017~1 + DateDeviation2017 + CalvingSeason2017 + Sex + Age2017 + Farm_ID,
                        random = ~g(international_id),
                        rcov = ~units,
                        data = phenotypes,
                        G = list(international_id=grm))

saveRDS(pre_adjust, "pre_adjust_2017.RDS")
