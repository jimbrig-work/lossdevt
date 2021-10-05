# Loss Development Shiny App

*Note: View the [CHANGLOG.md](CHANGELOG.md) for details on the project's development progress.* 

## Deployment

[![Build Docker Image](https://github.com/jimbrig-work/lossdevt/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/jimbrig-work/lossdevt/actions/workflows/docker-publish.yml)

[![Deployment - Azure Web App](https://github.com/jimbrig-work/lossdevt/actions/workflows/main_lossdevt.yml/badge.svg)](https://github.com/jimbrig-work/lossdevt/actions/workflows/main_lossdevt.yml)

- [x] Deploy locally using `Docker`
- [x] Azure Web App Deployment Configuration/Profile
- [x] Deploy automatically via GitHub Actions

View a live version of the application hosted at various domains/cloud services:

- Azure Web App: https://lossdevt.azurewebsites.net
- ShinyApps.io: https://jimbrig.shinyapps.io/lossdevt

- GCP Cloud Run: **WIP**
- AWS: **WIP**

### Source Code

- GitHub: https://github.com/jimbrig-work/lossdevt | https://github.com/jimbrig/loss_development_app
- AzureDevOps: https://dev.azure.com/actuarial-services/Reserving%20Modernization/_git/lossdevt

## Overview

R Shiny Web Application for simple loss reserving techniques and workflows. 

### Azure Details

- Resource Group: `AS-RESERVE`
- Container Registry: `acrreserve`
- Docker image: `appreservingacceleration`
- App Service Plan: `asp-as-reserve-app-reserving-acceleration`
- Web App: `reserving-acceleration`
- Deploy script: `az acr build --registry acrreserve --image appreservingacceleration .`

### Local Deployment with Docker

> Note: For best practices and quicker build times, I recommend using WSL and its Docker Integration with *Linux Containers* to build and run any docker images/containers. 

Configure docker for deploying to container registry:

```powershell
$azrpw = "<password>"
$acrpw | docker login acrreserve.azurecr.io --username acrreserve --password-stdin
```

Should see returned `Login succeeded` statement.

#### Build

```powershell
Rscript scripts/build.R
docker build -t lossdevt .
```

#### Test

```powershell
docker run --env SHINY_LOG_STDERR=1 --rm -p 8080:8080 lossdevt
start http://localhost:8080
```

#### Deploy

```powerhsell
docker tag lossdevt acrreserve.azurecr.io/lossdevt:latest
docker push acrreserve.azurecr.io/lossdevt:latest

# check its in registry:
az acr repository list -n shinyimages
```

Next, need to deploy the image on Azure and create the webapp:

```powershell
az webapp create -g AS_RESERVE -p asp-as-reserve-app-reserving-acceleration -n lossdevt -i acrreserve.azurecr.io/lossdevt:latest
```

## Roadmap

A simple shiny web app with the following features:

1. Loss development triangles:
  - Types:
    - Paid
    - Reported
    - Case Reserves
    - Reported Claim Counts
  - Age-to-Age Factors Triangle
  - Averages
2. Actual vs. Expected
3. Ultimate Selections

## Installation

- Clone repo and run `shiny::runApp("shiny_app")` or,
- Pull docker image and run locally on port 8080:

```bash
docker run -p 8080:8080 -it ghcr.io/jimbrig/lossdevt:latest
```


***

### File and Folder Structure

Use `deploy.R` script to deploy the app

Only files and folders that need to be deployed with the Shiny app go in the "shiny_app/" folder.

##### Project root level folders:

  - "data_prep/" - for data preparation.  Most projects need data to be prepped from some raw format to a format ready for the app.  This folder is most heavily used in the early days of the project as we are exploring the data and cleaning up initial data issues.
      - "provided/" - raw data provided by the client goes here.  This data is not tracked on GitHub
      - "prepped/" - cleaned versions of the data in "provided" goes here.  This data is also not tracked on GitHub.
  - "docs/" - additional documentation goes here
  - "analysis/" - additional analysis e.g. EDA goes here.  Also if you are training models that may or may not end up in your Shiny app, do that here.
  - You can make other folders as is appropriate for your project

##### "shiny_app/" level folders:

  - "www/" - contains all front end assets (i.e. css, js, and images)
  - "data/" - contains any flat files that need to be deployed with the app
  - "R/" - contains all R functions and modules.  Files containing modules should end with '_module.R'
