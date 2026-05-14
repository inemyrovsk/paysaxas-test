[nat]
nat1 ansible_host=${nat_ip} ansible_user=root ansible_port=22022

[k3s_servers]
server1 ansible_host=${server_ip} ansible_user=root ansible_port=22022

[k3s_servers:vars]
lb_public_ip=${cp_lb_ip}
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o ProxyCommand="ssh -p 22022 -i ~/.ssh/paysaxas -o StrictHostKeyChecking=no -W %h:%p root@${nat_ip}"
