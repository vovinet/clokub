resource "yandex_storage_bucket" "vovinet-15-2-bucket" {
  bucket = "vovinet-15-2-bucket"
}

resource "yandex_storage_object" "optimize" {
  bucket = "vovinet-15-2-bucket" # Имя бакета для добавления объекта. Обязательный параметр.
  key    = "optimize.jpg" # Имя объекта в бакете. Обязательный параметр.
  source = "optimize.jpg" # Относительный или абсолютный путь к файлу, загружаемому как объект.
}

resource "yandex_iam_service_account" "ig-sa" {
  name        = "ig-sa"
  description = "service account to manage IG"
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  folder_id = "b1ghkkescirrqp73inla"
  role      = "editor"
  members   = [
    "serviceAccount:${yandex_iam_service_account.ig-sa.id}",
  ]
}

resource "yandex_compute_instance_group" "ig-1" {
  name               = "fixed-ig-with-balancer"
  service_account_id = "${yandex_iam_service_account.ig-sa.id}"

  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 1
      cores  = 2
      core_fraction = 20
    }

    scheduling_policy {
      preemptible = "true"
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = "fd827b91d99psvq5fjit"
      }
    }
    
    network_interface {
      network_id = "${yandex_vpc_network.net-15.id}"
      subnet_ids = ["${yandex_vpc_subnet.public.id}"]
    }

    metadata = {
      ssh-keys = "kisa:${file("~/.ssh/id_rsa.pub")}"
      user-data = "runcmd:\n  - echo '<html><title>Some image</title><body><img src='https://storage.yandexcloud.net/vovinet-15-2-bucket/optimize.jpg' alt='Optimization in progress...' </body></html>' > /var/www/html/index.html\n  - echo 'pong' > /var/www/html/ping.html"
    }
  }
  scale_policy {
    fixed_scale {
      size = 3
    }
  }

  allocation_policy {
    zones = ["ru-central1-a"]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  load_balancer {
    target_group_name        = "lb-target-group"
    target_group_description = "load balancer target group"
  }

  #application_load_balancer {
  #  target_group_name        = "alb-target-group"
  #  target_group_description = "application load balancer target group"
  #}

  health_check {
    interval  = 10
    timeout   = 5
    
    tcp_options {
      port = 80
    }
  }

}

resource "yandex_lb_network_load_balancer" "lb1" {
  name = "my-network-load-balancer"

  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = "${yandex_compute_instance_group.ig-1.load_balancer[0].target_group_id}"

    healthcheck {
      name = "http" 
      
      http_options {
        port = 80
        path = "/ping.html"
      }
    }
  }
}

resource "yandex_vpc_network" "net-15" {
  name = "Network for VPC"
}

# resource "yandex_vpc_route_table" "rt-private" {
#   network_id = "${yandex_vpc_network.net-15.id}"

#   static_route {
#     destination_prefix = "0.0.0.0/0"
#     next_hop_address   = "192.168.10.254"
#   }
# }

resource "yandex_vpc_subnet" "public" {
  name           = "public"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.net-15.id}"
}

resource "yandex_vpc_subnet" "private" {
  name           = "private"
  v4_cidr_blocks = ["192.168.20.0/24"]
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.net-15.id}"
#  route_table_id = "${yandex_vpc_route_table.rt-private.id}"
}

resource "yandex_compute_instance" "public-nat-instance" {
  name        = "public-nat-instance"
  hostname    = "public-nat-instance"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 20
  }

  scheduling_policy {
      preemptible = "true"
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.public.id}"
    ip_address = "192.168.10.254"
    nat = "true"
  }

  metadata = {
    ssh-keys = "kisa:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_compute_instance" "public-ubuntu" {
  name        = "public-ubuntu"
  hostname    = "public-ubuntu"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 1
    core_fraction = 20
  }

  scheduling_policy {
      preemptible = "true"
  }

  boot_disk {
    initialize_params {
      image_id = "fd879gb88170to70d38a"
    }
  }

  network_interface {
    subnet_id = "${yandex_vpc_subnet.public.id}"
    nat = "true"
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# resource "yandex_lb_target_group" "lb-target-group" {
#   name        = "lb-target-group"
# }

# resource "yandex_alb_target_group" "alb-target-group" {
#   name        = "alb-target-group"
# }
