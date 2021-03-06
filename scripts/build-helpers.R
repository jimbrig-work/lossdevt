# automagic::make_deps_file("shiny_app")

use_template <- function(template_path, out_path, data = list()) {
  contents <- strsplit(whisker::whisker.render(usethis:::read_utf8(template_path), data), "\n")[[1]]
  usethis:::write_over(out_path, contents)
  file.edit(out_path)
}

get_cran_deps <- function(deps) {
  deps[sapply(deps, function(el) identical(el$Repository, "CRAN"))]
}

get_gh_deps <- function(deps) {
  deps[sapply(deps, function(el) !is.null(el$GithubRepo))]
}

cran_packages_cmd <- function(cran_deps) {
  cran_deps_string <- unlist(lapply(cran_deps, cran_install_string))
  paste0(
    "# CRAN R packages \n",
    paste(cran_deps_string, collapse = " \n"),
    "\n"
  )
}

gh_packages_cmd <- function(gh_deps) {
  github_deps_string <- unlist(lapply(gh_deps, github_install_string))
  paste0(
    "# GitHub R packages \n",
    paste(github_deps_string, collapse = " \n"),
    "\n"
  )
}

cran_install_string <- function(dep) {
  paste0("RUN R -e \"remotes::install_version('", dep$Package, "', version = '",
         dep$Version,
         "', upgrade = 'never', repos = c('CRAN' = Sys.getenv('CRAN_REPO')))\"")
}

github_install_string <- function(dep) {
  paste0("RUN R -e \"remotes::install_github('", dep$GithubUsername, "/",
         dep$Package, "', ref = '", dep$GithubSHA1, "', upgrade='never')\"")
}

r_command_string <- function(command) {
  paste0("RUN R -e \"", command, "\"")
}

get_sysreqs_pak <- function(packages) {

  purrr::map(
    packages,
    pak::pkg_system_requirements, os = "ubuntu", os_release = "20.04") %>%
    purrr::set_names(packages) %>%
    purrr::flatten_chr() %>%
    unique() %>%
    stringr::str_replace_all(., "apt-get install -y ", "")

}

sysreqs_cmd <- function(sysreqs) {

  paste(paste0("RUN ", apt_get_install(sysreqs), collapse = " \\ \n"))

}

#' Retrieve a list of system dependencies for the given packages
#'
#' @param packages
#' @param source
#' @param package_deps
#'
#' @return A character vector of required packages
#'
#' @export
#'
#' @examples \dontrun{
#' get_sysreqs("tidyverse", source = "rspm")
#' get_sysreqs(c("plumber", "rmarkdown"))
#' }
#'
#' @importFrom httr GET status_code has_content content
#' @importFrom jsonlite fromJSON
#' @importFrom pkgsearch cran_packages
#' @importFrom remotes package_deps
get_sysreqs <- function(packages,
                        source = c("rspm", "rhub"),
                        package_deps = TRUE) {

  source <- match.arg(source)

  if (length(packages) == 0) {
    return(c())
  }


  if (package_deps) packages <- sort(unique(c(packages, unlist(remotes::package_deps(packages)$package))))

  package_details <- pkgsearch::cran_packages(packages)

  packages <- package_details$Package

  request <- switch(source,
                    "rspm" = rspm_request(packages),
                    "rhub" = rhub_request(packages))

  response <- httr::GET(request)

  status_code <- httr::status_code(response)

  if (status_code != 200) {
    error_message <- paste("Status code", status_code)
    if (httr::has_content(response)) {
      error_message <- paste0(error_message, ": ", httr::content(response, "text"))
    }
    stop(error_message)
  }

  content <- jsonlite::fromJSON(httr::content(response, "text"))

  if (source == "rhub") return(content)

  required_packages <- content$requirements$requirements$packages

  unique(Reduce(c, required_packages))
}

#' Generate an installation command for the system dependencies of the given packages
#'
#' @inherit get_sysreqs_json details
#'
#' @inheritParams get_sysreqs
#'
#' @return A character vector of required packages
#' @export
#'
#' @examples \dontrun{
#' apt_get_install("tidyverse", distribution = "centos")
#' apt_get_install(
#'   c("plumber", "rmarkdown"),
#'   distribution = "ubuntu",
#'   release = "20.04"
#' )
#' }
apt_get_install <- function(sysreqs = NULL,
                            packages = NULL,
                            source = c("rspm", "rhub"),
                            package_deps = TRUE) {

  if (is.null(sysreqs)) sysreqs <- get_sysreqs(packages)

  paste0(
    "apt-get update -qq && apt-get -y --no-install-recommends install \\ \n",
    paste(
      paste0("  ", sysreqs),
      collapse = " \\ \n"
    ),
    " \\ \n && rm -rf /var/lib/apt/lists/*"
  )

}

rspm_request <- function(packages) {
  paste0(
    "http://packagemanager.rstudio.com/__api__/repos/1/sysreqs?all=false",
    paste0("&pkgname=", packages, collapse = ""),
    "&distribution=ubuntu"
  )
}

rhub_request <- function(packages) {
  sprintf("https://sysreqs.r-hub.io/pkg/%s/linux-x86_64-debian-gcc",
          paste(packages, collapse = ","))
}