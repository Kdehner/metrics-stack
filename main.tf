provider "docker" {
  host = "ssh://rpi"
}

resource "docker_image" "telegraf" {
  name         = "telegraf"
  keep_locally = "true"
}
resource "docker_image" "influxdb" {
  name         = "influxdb"
  keep_locally = "true"
}
resource "docker_image" "grafana" {
  name         = "grafana/grafana"
  keep_locally = "true"
}

resource "docker_network" "metrics" {
  name = "metrics"
}

resource "docker_container" "telegraf" {
  image    = docker_image.telegraf.latest
  name     = "telegraf"
  hostname = "kevbot-pi"
  env = ["PUID=1000", "PGID=1001", "TZ=America/Denver",
    "HOST_ETC=/hostfs/etc",
    "HOST_PROC=/hostfs/proc",
    "HOST_SYS=/hostfs/sys",
    "HOST_VAR=/hostfs/var",
    "HOST_RUN=/hostfs/run",
  "HOST_MOUNT_PREFIX=/hostfs"]
  networks_advanced {
    name = docker_network.metrics.name
  }
  volumes {
    container_path = "/etc/telegraf/telegraf.conf"
    read_only      = "true"
    host_path      = "/mnt/raid-alpha/config/telegraf/telegraf.conf"
  }
  volumes {
    container_path = "/hostfs"
    read_only      = "true"
    host_path      = "/"
  }
  restart = "unless-stopped"
}

resource "docker_container" "influxdb" {
  image = docker_image.influxdb.latest
  name  = "influxdb"
  env   = ["PUID=1000", "PGID=1001", "TZ=America/Denver"]
  networks_advanced {
    name = docker_network.metrics.name
  }
  volumes {
    container_path = "/var/lib/influxdb"
    volume_name    = docker_volume.influxdb.name
  }
  ports {
    internal = 8086
    external = 9010
  }
  restart = "unless-stopped"
}

resource "docker_container" "grafana" {
  image = docker_image.grafana.latest
  name  = "grafana"
  env   = ["PUID=1000", "PGID=1001", "TZ=America/Denver"]
  networks_advanced {
    name = docker_network.metrics.name
  }
  volumes {
    container_path = "/var/lib/grafana"
    volume_name    = docker_volume.grafana.name
  }
  ports {
    internal = 3000
    external = 9011
  }
  restart = "unless-stopped"
}

resource "docker_volume" "influxdb" {
  name   = "influxdb_config"
  driver = "local"
  driver_opts = {
    type   = "none"
    device = "/mnt/raid-alpha/config/influxdb"
    o      = "bind"
  }
}

resource "docker_volume" "grafana" {
  name   = "grafana_config"
  driver = "local"
  driver_opts = {
    type   = "none"
    device = "/mnt/raid-alpha/config/grafana"
    o      = "bind"
  }
}
