#!/bin/sh

container_manager="podman"
container_run_command="${container_manager} run -ti --rm -v `pwd`:/var/app -w /var/app"
image="docker.io/ruby"

cmd="${1}"
shift
case "${cmd}" in
  pull) [[ $(podman images --format {{.Names}}) =~ "docker.io/ruby" ]] || podman pull ${image};;
  run) eval "${container_run_command} ${image} ruby $@";;
esac
