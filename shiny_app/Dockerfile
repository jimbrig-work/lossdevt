FROM rocker/r-ver:latest AS sysreqs

ENV CRAN_REPO https://packagemanager.rstudio.com/cran/__linux__/focal/latest
ENV GITHUB_PAT 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

RUN R -e "install.packages('remotes', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"

# System Requirements
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  make \
  pandoc \
  libcurl4-openssl-dev \
  libssl-dev \
  libicu-dev \
  git \
 && rm -rf /var/lib/apt/lists/*

FROM sysreqs AS rpackages

RUN R -e "install.packages('remotes', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"

# CRAN R packages
RUN R -e "remotes::install_version('shiny', version = '1.7.0', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('shinydashboard', version = '0.7.1', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('shinyWidgets', version = '0.6.2', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('shinyjs', version = '2.0.0', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('shinycssloaders', version = '1.0.0', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('purrr', version = '0.3.4', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('lubridate', version = '1.7.10', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('tibble', version = '3.1.4', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('dplyr', version = '1.0.7', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('tidyr', version = '1.1.4', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('DT', version = '0.19', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('config', version = '0.3.1', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('qs', version = '0.25.1', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('polished', version = '0.4.0', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('fs', version = '1.5.0', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('rlang', version = '0.4.11', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"
RUN R -e "remotes::install_version('htmltools', version = '0.5.2', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))"


# GitHub R packages
RUN R -e "remotes::install_github('ractuary/devtri', ref = '5b2ff605b61bbd444d6eeca19ed7d0a4298abccf', upgrade='never')"
RUN R -e "remotes::install_github('merlinoa/summaryrow', ref = '027d02143ef465467f99e887b7c4f024a2445d7f', upgrade='never')"


FROM rpackages AS shinyapp

COPY . /srv/shiny-server/shiny_app

EXPOSE 8080

CMD ["Rscript","-e","shiny::runApp(appDir='/srv/shiny-server/shiny_app',port=8080,launch.browser=FALSE,host='0.0.0.0')"]
