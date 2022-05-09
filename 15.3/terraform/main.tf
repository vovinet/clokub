locals {
  folder_id = "b1ghkkescirrqp73inla" // clokub
}

// Create SA
resource "yandex_iam_service_account" "object-sa" {
  folder_id = local.folder_id
  name      = "object-sa"
}

// Grant permissions
resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = local.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.object-sa.id}"
}

// Create Static Access Keys
resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = yandex_iam_service_account.object-sa.id
  description        = "static access key for object storage"
}

resource "yandex_kms_symmetric_key" "key-a" {
  name              = "example-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // equal to 1 year
}

// Use keys to create bucket
resource "yandex_storage_bucket" "test" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "s3.zubarev.su"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.key-a.id
        sse_algorithm     = "aws:kms"
      }
    }
  }

}

resource "yandex_storage_object" "dead_mouse" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "s3.zubarev.su" # Имя бакета для добавления объекта. Обязательный параметр.
  key    = "index.html" # Имя объекта в бакете. Обязательный параметр.
  source = "./../index.html" # Относительный или абсолютный путь к файлу, загружаемому как объект.
}

