# Rancher Desktop

Kubernetes is built in to Rancher Desktop. Kubernetes is provided by k3s, a lightweight certified distribution. With Rancher Desktop you have the ability to choose your version of Kubernetes and reset Kubernetes or Kubernetes and the whole container runtime with the click of a button.

Rancher Desktop is an electron based application that wraps other tools while itself providing the user experience to create a simple experience. On MacOS and Linux, Rancher Desktop leverages a virtual machine to run containerd or dockerd and Kubernetes. Windows Subsystem for Linux v2 is leveraged for Windows systems. All you need to do is download and run the application.

## Getting Started

```
$ rdctl start
...
$ kubectl config set-context rancher-desktop
...
```

Get IP address of container.

```
$ echo "ip route | awk '/^[0-1].*rd0/{print\$7}'" | rdctl shell
192.168.20.23
```

## References
* [Rancher Desktop](https://rancherdesktop.io)
* [Rancher Desktop Docs](https://docs.rancherdesktop.io)
