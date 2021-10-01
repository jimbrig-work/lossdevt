Sys.setenv(R_CONFIG_ACTIVE = "production")

config <- config::get(file = "shiny_app/config.yml")

# Deploy to ShinyApps.io
rsconnect::deployApp(
  appDir = "shiny_app",
  account = "jimbrig",
  appName = config$app_name
)

# Build Docker image:
system2(command = "docker build -t ghcr.io/jimbrig/lossdevt:latest -f shiny_app/Dockerfile")

# Deploy to GCP:
