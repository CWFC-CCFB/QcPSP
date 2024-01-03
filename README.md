[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0) [![R-CMD-check](https://github.com/CWFC-CCFB/QcPSP/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CWFC-CCFB/QcPSP/actions/workflows/R-CMD-check.yaml)

The QcPSP package
=======================

## Introduction

The QcPSP package contains a clean version of Quebec PSP data.

The original data was produced and made freely available online
at https://www.donneesquebec.ca/recherche/dataset/placettes-echantillons-permanentes-1970-a-aujourd-hui by Direction des inventaires forestiers
of Ministère des Ressources naturelles et des Forêts du Québec. The original data is published under a CC-BY 4.0 license. 

## License

This package is licensed under the LGPL-3. 

## How to use it

The package can be installed using the remotes package:

~~~R
library(remotes)
remotes::install_github("CWFC-CCFB/QcPSP")
~~~

To get access to the four tables of the database:

~~~R
QcPSP::restoreQcPSPData()
~~~

This will create four data.frame objects in the global environment:

- QcMeasurementIndex
- QcPlotIndex
- QcTreeIndex
- QcTreeMeasurements

Metadata are available for any of these four data.frame objects as follows: 

~~~R
QcPSP::getMetaData(QcMeasurementIndex)
~~~

Further information on the fields and their values can be found at 

https://diffusion.mffp.gouv.qc.ca/Diffusion/DonneeGratuite/Foret/DONNEES_FOR_ECO_SUD/Placettes_permanentes/1-Documentation/DICTIONNAIRE_PLACETTE.xlsx

The inventory protocol is available at

https://mffp.gouv.qc.ca/documents/forets/inventaire/norme-5e-inventaire-peppdf.pdf

