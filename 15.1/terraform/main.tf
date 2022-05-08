resource "yandex_vpc_network" "net-15-1" {
  name = "Network for 15.1"
}

resource "yandex_vpc_route_table" "rt-private" {
  network_id = "${yandex_vpc_network.net-15-1.id}"

  static_route {
    destination_prefix = "0.0.0.0/0"
    next_hop_address   = "192.168.10.254"
  }
}

resource "yandex_vpc_subnet" "public" {
  name           = "public"
  v4_cidr_blocks = ["192.168.10.0/24"]
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.net-15-1.id}"
}

resource "yandex_vpc_subnet" "private" {
  name           = "private"
  v4_cidr_blocks = ["192.168.20.0/24"]
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.net-15-1.id}"
  route_table_id = "${yandex_vpc_route_table.rt-private.id}"
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

resource "yandex_compute_instance" "private-ubuntu" {
  name        = "private-ubuntu"
  hostname    = "private-ubuntu"
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
    subnet_id = "${yandex_vpc_subnet.private.id}"
    nat = "false"
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
} 