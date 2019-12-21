# Basic configuration withour variables

# Define authentification configuration
provider "vsphere" {
  # If you use a domain set your login like this "MyDomain\\MyUser"
  user           = "tfuser@vsphere.local"
  password       = "tfdemo"
  vsphere_server = "192.168.21.90"

  # if you have a self-signed cert
  allow_unverified_ssl = true
}

#### RETRIEVE DATA INFORMATION ON VCENTER ####

data "vsphere_datacenter" "dc" {
  name = "铭光"
}

data "vsphere_resource_pool" "pool" {
  # If you haven't resource pool, put "Resources" after cluster name
  name          = "Terraform-zone01"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_host" "host" {
  name          = "192.168.21.95"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve datastore information on vsphere
data "vsphere_datastore" "datastore" {
  name          = "192.168.21.95-disk003"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve network information on vsphere
data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

# Retrieve template information on vsphere
data "vsphere_virtual_machine" "template" {
  name          = "C7BaseOS"
  datacenter_id = data.vsphere_datacenter.dc.id
}

#### VM CREATION ####

# Set vm parameters
resource "vsphere_virtual_machine" "vm-one" {
  name             = "vm-one"
  num_cpus         = 2
  memory           = 4096
  datastore_id     = data.vsphere_datastore.datastore.id
  host_system_id   = data.vsphere_host.host.id
  resource_pool_id = data.vsphere_resource_pool.pool.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type

  # Set network parameters
  network_interface {
    network_id = data.vsphere_network.network.id
  }

  # Use a predefined vmware template has main disk
  disk {
    #  name = "vm-one.vmdk"
    label            = "vm-one.vmdk"
    size             = "100"
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    customize {
      linux_options {
        host_name = "vm-one"
        domain    = "vm.local"
      }

      network_interface {
        ipv4_address    = "192.168.23.19"
        ipv4_netmask    = 20
        dns_server_list = ["192.168.21.1", "8.8.4.4"]
      }

      ipv4_gateway = "192.168.21.1"
    }
  }

  # provisioner "local-exec" {
  #   command = "echo 'StrictHostKeyChecking no' >> ~/.ssh/config"
  # }

  # provisioner "local-exec" {
  #   command = "echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config"
  # }

  # Execute script on remote vm after this creation
  # Execute script on remote vm after this creation
  #  provisioner "remote-exec" {
  #    script = "scripts/example-script.sh"
  #    connection {
  #      type     = "ssh"
  #      user     = "root"
  #      password = "secret"
  #      host     = "192.168.23.17"
  #    }
  #  }
}


resource "null_resource" "vm" {
  #  triggers {
  #    public_ip = "192.168.23.19"
  #  }

  depends_on = [vsphere_virtual_machine.vm-one]

  connection {
    type     = "ssh"
    host     = "192.168.23.19"
    user     = "root"
    password = "redhat"
    port     = "22"
    agent    = false
  }

  provisioner "file" {
    source      = "scripts/terraform"
    destination = "/usr/local/bin"
  }
  provisioner "file" {
    source      = "scripts/.ssh"
    destination = "/root/"
  }
  provisioner "file" {
    source      = "scripts/example-script.sh"
    destination = "/tmp/example-script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/example-script.sh",
      "sh -c /tmp/example-script.sh",
      "echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config",
      "echo 'UserKnownHostsFile /dev/nul' >> /etc/ssh/ssh_config ",
    ]
  }
}














