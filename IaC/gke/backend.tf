# Adjust the backend for your needs

terraform {
  backend "remote" {
    organization = "muskeg"

    workspaces {
      name = "short-url"
    }
  }
}
