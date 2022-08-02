# sidecar

## Introduction
The code herein is used to create sidecar and init containers for various use
cases. 

The `bootstrap.sh` script is used to create a local Docker registry
for use with Minikube where these and other container images can be created
and managed locally. It requires `limactl` available with Minikube running.

The `builder.sh` script is used to iterate through the images in the registry
and build those missing. The directories in this folder should be named after
the image name for successful automatic build.

## Warning

This code supports macOS. Support for other platforms is encouraged by PR. As
such, by default, macOS users will need to disable AirPlay Receiver in System
Preferences > Sharing since it collides with tcp:5000 which is used by default.

If you experience issues with `bootstrap.sh` such as
`proxy: unknown scheme: http`, unset proxy environment variables.

```
$ unset $(compgen -e | awk 'tolower($1)~/proxy/{printf"%s ",$1}')
```