# This inventory file is populated by Terraform output.
# Ansible connects on port 22 initially; the ssh role switches to ssh_port.
[k3s_servers]
server1 ansible_host=${server_ip} ansible_user=root ansible_port=22
