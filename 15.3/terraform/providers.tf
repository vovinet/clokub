terraform {
  required_providers {
    yandex = {
      source = "terraform-registry.storage.yandexcloud.net/yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  cloud_id  = "b1gbqms8a42gt67jug40"
  folder_id = "b1ghkkescirrqp73inla"
  zone      = "ru-central1-a"
}
