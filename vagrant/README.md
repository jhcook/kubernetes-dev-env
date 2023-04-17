# Vagrant

Vagrant is designed for everyone as the simplest and fastest way to create a
virtualized environment.

We use Vagrant to mimic remote hosts for real-world modeling using a
Vagrantfile that delivers four nodes: one master and three workers. 

## Prerequisites

* vagrant

## Getting Started

Edit the `vagrant/localenv.sh` variables to create the nodes as to your
preference. Ensure `env.sh` RUNTIME=vagrant.

Create the Vagrant nodes, create an RKE2 cluster, and syncronise kubeconfig.

```
$ bash vagrant/setup_vagrant.sh
...
$ bash vagrant/setup_rke2.sh
...
$ bash vagrant/sync_kubeconfig.sh
...
```

## Operations

Bring up the Vagrant boxes. Given Vagrant tracks the state in '.vagrant' you
need to change to this directory and create the hosts.

```
$ cd vagrant
vagrant $
```

This will make four nodes -- master, node1, node2, and node3 -- available on
the cooresponding addresses: 192.168.123.210,192.168.123.211, 192.168.123.212,
and 192.168.123.213.

```
vagrant $ vagrant up
...
```

You may now access the hosts using vagrant ssh, and conveniently alias `ssh` to
use `vagrant ssh`.

```
vagrant $ alias ssh="vagrant ssh"
```

In each script, you will need to source a file which defines the alias and use
expand_aliases.

```
vagrant $ grep aliases setup_rke2.sh
shopt -s expand_aliases
vagrant $ grep alias localenv.sh 
alias ssh="vagrant ssh"
```

## Node Configuration

In order to use SSH to programmatically access the hosts, one will need to
suppress motd and lastlog on ssh connections.

```
$ echo "sudo sed -i '/^session    optional     pam_motd\.so/s/^/#/' /etc/pam.d/sshd" | vagrant ssh master
...
$ echo "sudo sed -i 's/^#PrintLastLog yes$/PrintLastLog no/' /etc/ssh/sshd_config" | vagrant ssh master
$ echo "sudo systemctl restart sshd" | vagrant ssh master
```

```
$ echo "curl -sfL https://get.rke2.io | sudo -E sh -" | vagrant ssh master
...
[INFO]  finding release for channel stable
[INFO]  using v1.24.12+rke2r1 as release
[INFO]  downloading checksums at https://github.com/rancher/rke2/releases/download/v1.24.12+rke2r1/sha256sum-amd64.txt
[INFO]  downloading tarball at https://github.com/rancher/rke2/releases/download/v1.24.12+rke2r1/rke2.linux-amd64.tar.gz
[INFO]  verifying tarball
[INFO]  unpacking tarball file to /usr/local
$ echo "systemctl enable --now rke2-server.service" | vagrant ssh master
...
```

Get the token and add each host.

```
vagrant $ TOKEN="$(echo "sudo cat /var/lib/rancher/rke2/server/node-token" | vagrant ssh master)"
```




