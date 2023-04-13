# Rancher Desktop

Kubernetes is built in to Rancher Desktop. Kubernetes is provided by k3s, a lightweight certified distribution. With Rancher Desktop you have the ability to choose your version of Kubernetes and reset Kubernetes or Kubernetes and the whole container runtime with the click of a button.

Rancher Desktop is an electron based application that wraps other tools while itself providing the user experience to create a simple experience. On MacOS and Linux, Rancher Desktop leverages a virtual machine to run containerd or dockerd and Kubernetes. Windows Subsystem for Linux v2 is leveraged for Windows systems. All you need to do is download and run the application.

## Getting Started

In order to create the environment and utilities, Rancher Desktop application
needs to be open and and the configuration accepted. 

```
$ open /Applications/Rancher\ Desktop.app
```

This will open a small window "Welcome to Rancher Desktop" of which a few
options are available. You can either select the specific options and Accept,
or simply accept and run the script below. After, immediately exit Rancher
Desktop from the application's dock.

Enable Kubernetes
Kubernetes version: v1.24.12
containerd
Configure PATH: Manual

```
$ bash rancher-desktop/setup_rancher_desktop.sh 
Starting Rancher Desktop
Status: UI is currently busy, but will eventually be reconfigured to apply requested changes.
Waiting on API..............
Context "rancher-desktop" modified.
```

Get IP address of master node.

```
$ echo "ip route | awk '/^[0-1].*rd0/{print\$7}'" | rdctl shell
192.168.20.23
```

## Configure

The `rancher-desktop/setup_rancher_desktop.sh` script disables the default
installation of Flannel. Due to this, the node does not become ready. In order
to remediate, install Calico as shown below:

```
$ echo "sudo curl --no-progress-meter -L -o /usr/libexec/cni/calico https://github.com/projectcalico/cni-plugin/releases/download/v3.25.1/calico-amd64" | rdctl shell 
$ echo "sudo curl --no-progress-meter -L -o /usr/libexec/cni/calico-ipam https://github.com/projectcalico/cni-plugin/releases/download/v3.25.1/calico-ipam-amd64" | rdctl shell 
$ echo "sudo chmod 755 /usr/libexec/cni/calico" | rdctl shell 
$ echo "sudo chmod 755 /usr/libexec/cni/calico-ipam" | rdctl shell 
$ bash cni/install_calico.sh
...
```

## Shutdown

In order to shutdown the cluster and maintain configuration, execute the
following. When the cluster is restarted, it will restore Kubernetes as
previously configured.

```
$ rdctl shutdown
Shutting down.
```

## Destroy

In order to destroy the Rancher state an environment, execute the following.
But, please be aware the application will need to be opened again to establish
the utilities necessary. These instructions can be found above in Getting
Started.

## References
* [Rancher Desktop](https://rancherdesktop.io)
* [Rancher Desktop Docs](https://docs.rancherdesktop.io)
