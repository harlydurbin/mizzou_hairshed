
library(sommer)

phenotypes <- base::readRDS("phenotypes_multi.RDS")

grm <- base::readRDS("grm.RDS")


#
pre_adjust <- sommer::mmer2(HairScore~1 + DateDeviation + CalvingSeason + Sex + Age + Farm_ID + yr,
                                random = ~g(international_id) + international_id ,
                                rcov = ~units,
                                data = phenotypes,
                                G = list(international_id=grm))
saveRDS(pre_adjust, "180509.pre_adjust_multi.RDS")
