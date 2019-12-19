resource "null_resource" "vm" {
 
  connection {
    type     = "ssh"
    host     = "192.168.23.19"
    user     = "root"
    password = "redhat"
    port     = "22"
    agent    = false
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
