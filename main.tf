terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu+sshcmd://optiplex/system"
}

variable "ssh_public_key" {
  type = string
}

# Volume from HTTP URL upload
resource "libvirt_volume" "ubuntu_base" {
  name = "ubuntu-22.04.qcow2"
  pool = "images"
  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
    }
  }
  # capacity is automatically computed from Content-Length when available
}

# Basic volume
resource "libvirt_volume" "disk_tf_example" {
  name     = "disk_tf_example.qcow2"
  pool     = "images"
  capacity = 10737418240 # 10 GB

  backing_store = {
    path = libvirt_volume.ubuntu_base.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_cloudinit_disk" "init" {
  name = "vm-init"
  # user_data = file("user-data.yml")
  user_data = templatefile("user-data.yml", {
    ssh_public_key = var.ssh_public_key
  })
  meta_data = yamlencode({
    instance-id    = "tf-vm-01"
    local-hostname = "webserver"
  })
}

resource "libvirt_volume" "cloudinit" {
  name = "vm-cloudinit"
  pool = "images"
  # format = "raw"

  create = {
    content = {
      url = libvirt_cloudinit_disk.init.path
    }
  }
}

# Basic VM configuration
resource "libvirt_domain" "vm_tf_example" {
  name        = "vm_tf_example"
  memory      = 1024
  memory_unit = "MiB"
  vcpu        = 2
  type        = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      {
        volume_id = libvirt_volume.disk_tf_example.id
      },
      {
        volume_id = libvirt_volume.cloudinit.id
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "br0"
          }
        }
      }
    ]
  }
}
