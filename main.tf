data "yandex_compute_image" "ubuntu2404" {
  family = "ubuntu-2404-lts-oslogin"
}
resource "yandex_vpc_network" "default" {
  name = var.project
}
resource "yandex_vpc_network" "iscsi" {
  name = "${var.project}-iscsi"
}
resource "yandex_vpc_gateway" "default" {
  name = var.project
  shared_egress_gateway {}
}
resource "yandex_vpc_route_table" "default" {
  name       = var.project
  network_id = yandex_vpc_network.default.id
  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.default.id
  }
}
resource "yandex_vpc_subnet" "default" {
  name           = "${yandex_vpc_network.default.name}-${var.zone}"
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.130.0.0/24"]
  route_table_id = yandex_vpc_route_table.default.id
}
resource "yandex_vpc_subnet" "iscsi" {
  count          = 2
  name           = format(
    "%s%02d-%s", "${yandex_vpc_network.iscsi.name}", count.index+1, var.zone
  )
  network_id     = yandex_vpc_network.iscsi.id
  v4_cidr_blocks = [cidrsubnet("10.0.0.0/8", 16, 256*(131+count.index))]
}
resource "yandex_compute_disk" "iscsi" {
  count = local.yandex_compute_instance_iscsi_count
  size  = 20
  type  = "network-hdd"
}
resource "yandex_compute_instance" "iscsi" {
  count       = local.yandex_compute_instance_iscsi_count
  name        = format("%s-%02d", "${var.project}-iscsi", count.index + 1)
  hostname    = format("%s-%02d", "${var.project}-iscsi", count.index + 1)
  platform_id = "standard-v3"
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
  scheduling_policy { preemptible = true }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu2404.id
      size     = 20
      type     = "network-hdd"
    }
  }
  secondary_disk {
    disk_id     = yandex_compute_disk.iscsi[count.index].id
    auto_delete = true
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = false
  }
  dynamic "network_interface" {
    for_each = yandex_vpc_subnet.iscsi
    content {
      subnet_id = network_interface.value.id
      nat       = false
    }
  }
  metadata = local.yandex_compute_instance_metadata
}
resource "yandex_compute_instance" "gfs" {
  count       = 3
  name        = format("%s-%02d", "${var.project}", count.index + 1)
  hostname    = format("%s-%02d", "${var.project}", count.index + 1)
  platform_id = "standard-v3"
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
  scheduling_policy { preemptible = true }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu2404.id
      size     = 20
      type     = "network-hdd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = false
  }
  dynamic "network_interface" {
    for_each = yandex_vpc_subnet.iscsi
    content {
      subnet_id = network_interface.value.id
      nat       = false
    }
  }
  metadata = local.yandex_compute_instance_metadata
}
resource "yandex_compute_instance" "jumphost" {
  name        = "${var.project}-jumphost"
  hostname    = "${var.project}-jumphost"
  platform_id = "standard-v3"
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
  scheduling_policy { preemptible = true }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu2404.id
      size     = 20
      type     = "network-hdd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }
  metadata = local.yandex_compute_instance_metadata
}
resource "local_file" "inventory" {
  filename = "${path.root}/inventory.yml"
  content = templatefile("${path.module}/inventory.tftpl", {
    ssh_username = var.ssh_username,
    ssh_key_file = var.ssh_key_file,
    groups = [
      {
        name  = "iscsi"
        hosts = yandex_compute_instance.iscsi
        ipvars = ["ip_address_iscsi1", "ip_address_iscsi2"]
        jumphost = yandex_compute_instance.jumphost
      },
      {
        name     = "gfs",
        hosts    = yandex_compute_instance.gfs
        ipvars = ["ip_address_iscsi1", "ip_address_iscsi2"]
        jumphost = yandex_compute_instance.jumphost
      }
    ],
  })
}
