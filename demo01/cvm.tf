terraform {
  required_providers {
    tencentcloud = {
      source = "tencentcloudstack/tencentcloud"
    }
  }
}

# Configure the TencentCloud Provider
provider "tencentcloud" {
  region     = "ap-guangzhou"
}

# Get availability zones
data "tencentcloud_availability_zones" "default" {}

# Get availability images
data "tencentcloud_images" "default" {
  image_type = ["PUBLIC_IMAGE"]
  os_name    = "centos"
}

# Get availability instance types
data "tencentcloud_instance_types" "default" {
  cpu_core_count = 2
}

# Create a web server
resource "tencentcloud_instance" "docker_host" {
  instance_name              = "docker host"
  availability_zone          = data.tencentcloud_availability_zones.default.zones.0.name
  image_id                   = data.tencentcloud_images.default.images.0.image_id
  instance_type              = data.tencentcloud_instance_types.default.instance_types.0.instance_type
  system_disk_type           = "CLOUD_PREMIUM"
  system_disk_size           = 50
  allocate_public_ip         = true
  internet_max_bandwidth_out = 20
  security_groups            = [tencentcloud_security_group.default.id]
  count                      = 1
  password                   = "Cwj123456"

  
}

# Create security group
resource "tencentcloud_security_group" "default" {
  name        = "docker host web accessibility"
  description = "make it accessible for both production and stage ports"
}

# Create security group rule allow web request
resource "tencentcloud_security_group_rule" "docker_host" {
  security_group_id = tencentcloud_security_group.default.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "tcp"
  port_range        = "80,8080"
  policy            = "accept"
}

# Create security group rule allow ssh request
resource "tencentcloud_security_group_rule" "ssh" {
  security_group_id = tencentcloud_security_group.default.id
  type              = "ingress"
  cidr_ip           = "0.0.0.0/0"
  ip_protocol       = "tcp"
  port_range        = "22"
  policy            = "accept"
}


 resource "null_resource" "docker_install" {

  depends_on = [tencentcloud_instance.docker_host]

  connection {
    type = "ssh"
    user = "root"
    password = "Cwj123456"
    host = tencentcloud_instance.docker_host[0].public_ip
  }
  
  provisioner "remote-exec" {
    inline = [
      "yum install -y docker-ce",
    ]
  }

}