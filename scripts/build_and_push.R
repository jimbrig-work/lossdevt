library(polished)
library(yaml)
library(whisker)
library(usethis)
library(purrr)

source("scripts/build-helpers.R")

# create new "build" folder
fs::dir_delete("build")
fs::dir_create("build")
copy_dirs <- c(
  "shiny_app/R",
  "shiny_app/data",
  "shiny_app/www"
)
copy_files <- c(
  "shiny_app/deps.yaml",
  "shiny_app/.dockerignore",
  "shiny_app/config.yml",
  fs::dir_ls("shiny_app", type = "file", glob = "*.R")
)

purrr::walk(copy_dirs, ~ fs::dir_copy(.x, paste0("build/", basename(.x)), overwrite = TRUE))
purrr::walk(copy_files, fs::file_copy, "build/", overwrite = TRUE)

# shiny::runApp(appDir = "build")

# gather R package dependencies -------------------------------------------
optional_pkgs <- c("googledrive", "dbx", "urltools", "rprojroot", "usethis")
deps <- polished:::get_package_deps("shiny_app")
deps <- deps[!(names(deps) %in% c(optional_pkgs, "remotes"))]
yaml::write_yaml(deps, "shiny_app/deps.yml")

# command strings ---------------------------------------------------------
cran_install_cmd <- get_cran_deps(deps) %>% cran_packages_cmd()
gh_install_cmd <- get_gh_deps(deps) %>% gh_packages_cmd()
sysreqs_cmd <- get_sysreqs_pak(names(deps)) %>% sysreqs_cmd()

# create Dockerfile from template -----------------------------------------
use_template("config/Dockerfile_template",
             "shiny_app/Dockerfile",
             data = list(
               sysreqs = sysreqs_cmd,
               cran_installs = cran_install_cmd,
               gh_installs = gh_install_cmd
             ))

# create .dockerignore ----------------------------------------------------
# write("shiny_app/.dockerignore", ".dockerignore")
# write("shiny_app/Dockerfile", ".dockerignore", append = TRUE)
# write("shiny_app/logs/*", ".dockerignore", append = TRUE)
# write("shiny_app/deps.yaml", ".dockerignore", append = TRUE)
# write("shiny_app/README.md", ".dockerignore", append = TRUE)
# write("shiny_app/R/get_config.R", ".dockerignore", append = TRUE)

# start docker, build local test image and run
shell.exec("C:/Program Files/Docker/Docker/Docker Desktop.exe")
rstudioapi::terminalExecute("docker build -t lossdevt .")
rstudioapi::terminalExecute("docker run --env SHINY_LOG_STDERR=1 --rm -p 8080:8080 lossdevt")
browseURL("localhost:8080")

### EXAMPLE CONTAINER PUSHES TO VARIOUS REGISTRIES ###

### DOCKERHUB ###
system("docker tag lossdevt jimbrig2011/lossdevt:latest")
system("docker push jimbrig2011/lossdevt:alpha")

### GITHUB ###
system("$env:GITHUB_PAT | docker login ghcr.io -u jimbrig --password-stdin")\
system("docker tag lossdevt ghcr.io/jimbrig/lossdevt:latest")
system("docker push ghcr.io/jimbrig/lossdevt:latest")

### AZURE ###
system("$env:ACR_PW | docker login acrreserve.azurecr.io --username acrreserve --password-stdin")\
system("docker tag lossdevt acrreserve.azurecr.io/lossdevt:latest")
system("docker push acrreserve.azurecr.io/lossdevt:latest")

### GCP ###

rstudioapi::terminalExecute("gcloud auth configure-docker")
rstudioapi::terminalExecute("docker build --build-arg R_CONFIG_ACTIVE=production -t lossdevt .")
rstudioapi::terminalExecute("docker tag lossdevt gcr.io/$PROJECT_ID/lossdevt")
rstudioapi::terminalExecute("docker push gcr.io/$PROJECT_ID/lossdevt")

# deploy to cloud run
system("gcloud run deploy loss_development_app --memory=8192Mi --platform=managed --cpu=4 --image=gcr.io/$PROJECT_ID/lossdevt --max-instances='default' --min-instances=0 --port=8080 --no-traffic --allow-unauthenticated --region=asia-east1")
