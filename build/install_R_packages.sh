#! /bin/bash

Rscript -e "BiocManager::install('copynumber')"
Rscript -e "install.packages('sequenza', repos='https://www.stats.bris.ac.uk/R/', dependencies=TRUE, clean = TRUE)"
Rscript -e "devtools::install_github('mskcc/facets', build_vignettes = FALSE)"
