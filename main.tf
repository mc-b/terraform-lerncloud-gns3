###
#   Ressourcen
#

resource "null_resource" "gns3" {
  triggers = {
    name = var.module
  }
  depends_on = [
    local_file.user-data,
    local_file.meta-data,
    local_file.template,
    local_file.script
  ]

  provisioner "local-exec" {
    command = "bash -x ${var.module}/script.sh"
  }
}

# Hack weil local-exec nicht funktioniert mit {}
resource "local_file" "script" {
  filename = "${var.module}/script.sh"
  content  = <<EOF
#!/bin/bash
#
cd ${var.module}/
sudo mkisofs -output /opt/gns3/images/QEMU/${var.module}.iso -volid cidata -joliet -rock -input-charset utf-8 {user-data,meta-data}
curl -X POST http://localhost:3080/v2/templates -d @template
EOF
}

# Meta Data

resource "local_file" "meta-data" {
  content  = "instance-id: ${var.module}\nlocal-hostname: ${var.module}"
  filename = "${var.module}/meta-data"
}

# Cloud-init Script

data "template_file" "userdata" {
  template = file(var.userdata)
}

resource "local_file" "user-data" {
  content  = data.template_file.userdata.rendered
  filename = "${var.module}/user-data"
}

# GNS3 curl Data

resource "local_file" "template" {
  content  = <<EOF
{
    "cdrom_image": "${var.module}.iso",
    "compute_id": "local",
    "default_name_format": "{name}",
    "console_type": "telnet",
    "cpus": ${var.cores},
    "hda_disk_image": "jammy-server-cloudimg-amd64.img",
    "name": "${var.module}",
    "qemu_path": "/bin/qemu-system-x86_64",
    "ram": ${var.memory * 1024},
    "template_type": "qemu",
    "usage": "${var.description}"
}
EOF
  filename = "${var.module}/template"
}