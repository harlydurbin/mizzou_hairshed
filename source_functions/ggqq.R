# Stolen from Troy

ggqq <- function(pvector){
  pvector = pvector[!is.na(pvector) & !is.nan(pvector) & !is.null(pvector) & is.finite(pvector) & pvector<1 & pvector>0]
  pdf = data.frame(observed = -log10(sort(pvector, decreasing = FALSE)), expected = -log10(ppoints(length(pvector))))
  qqplotted = ggplot(pdf, aes(expected, observed)) +
    geom_point() +
    geom_abline(intercept = 0,
                slope = 1,
                colour = "red")+
    labs(x = expression(paste("Expected ", -log10, "(", italic('p'), ")")),
         y = expression(paste("Expected ", -log10, "(", italic('p'), ")")))
  return(qqplotted)
}