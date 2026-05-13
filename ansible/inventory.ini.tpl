[nat]
nat1 ansible_host=${nat_ip} ansible_user=root

[k3s_servers]
server1 ansible_host=${server_ip} ansible_user=root

[k3s_servers:vars]
lb_public_ip=${lb_ip}
ansible_ssh_common_args=-o StrictHostKeyChecking=no -o ProxyCommand="ssh -i ~/.ssh/paysaxas -o StrictHostKeyChecking=no -W %h:%p root@${nat_ip}"
