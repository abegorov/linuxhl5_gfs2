terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.138"
    }
  }
  required_version = "~> 1.10"
}
