# This inventory file is populated by Terraform output.
# The K3s server has no public IP; SSH via NAT gateway as jump host.
# Ansible connects on port 22 initially; the ssh role switches to ssh_port.
[nat]
nat1 ansible_host=${nat_ip} ansible_user=root ansible_port=22

[k3s_servers]
server1 ansible_host=${server_ip} ansible_user=root ansible_port=22 ansible_ssh_common_args='-o ProxyJump=root@${nat_ip}'
