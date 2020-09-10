
library(sommer)

phenotypes <- base::readRDS("phenotypes_uni.RDS")

grm <- base::readRDS("grm.RDS")

pre_adjust <- sommer::mmer2(HairScore2016~1 + DateDeviation2016 + CalvingSeason2016 + Sex + Age2016 + Farm_ID,
                        random = ~g(international_id),
                        rcov = ~units,
                        data = phenotypes,
                        G = list(international_id=grm))

saveRDS(pre_adjust, "pre_adjust_2016.RDS")
