provider "docker" {
  host = "http://127.0.0.1:2375"

}

resource "docker_network" "private_network" {
  name = "tick"
}


resource "docker_container" "influxdb" {
  name    = "influxdb"
  image   = "influxdb:latest"
  restart = "always"
  networks_advanced {
    name = "${docker_network.private_network.id}"
  }
  ports {
    internal = 8086
    external = 8086
  }

}

resource "docker_container" "chronograf" {
  name    = "chronograf"
  image   = "chronograf:latest"
  restart = "always"
  networks_advanced {
    name = "${docker_network.private_network.id}"
  }
  ports {
    internal = 8888
    external = 8888
  }
  command    = ["chronograf", "--influxdb-url=http://influxdb:8086", "--kapacitor-url=http://kapacitor:9092"]
  depends_on = [docker_container.influxdb]
}

resource "docker_container" "kapacitor" {
  name    = "kapacitor"
  image   = "kapacitor:latest"
  restart = "always"
  networks_advanced {
    name = "${docker_network.private_network.id}"
  }
  ports {
    internal = 9092
    external = 9092
  }

}

resource "docker_container" "telegraf" {
  name    = "telegraf"
  image   = "telegraf:latest"
  restart = "always"
  networks_advanced {
    name = "${docker_network.private_network.id}"
  }
  upload {
    content = "${file(local.config)}"
    file    = "/etc/telegraf/telegraf.conf"

  }
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

}
####
#### This has to be your absolute path ####
####
locals {
  config = "tf-tick-stack/config/telegraf.conf"
}


