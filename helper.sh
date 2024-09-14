#!/bin/sh

__fast__detect_container_manager()
{
  container_manager="${CONTAINER_MANAGER:-autodetect}"
  declare -a container_managers=(
    "podman"
    "docker"
  )
  if [ "${container_manager}" = "autodetect" ]; then
    for c in "${container_managers[@]}"
    do
      if command -v "${c}" > /dev/null; then
        container_manager="${c}"
        break
      fi
    done
    if [ "${container_manager}" = "autodetect" ]; then
      echo "Cannot find any valid container managers"
      exit 1
    fi
  else
    ! command -v "${container_manager}" > /dev/null && echo "${container_manager} is not executable" && exit 1
  fi
  echo "${container_manager}"
}

__fast__gen_run_command()
{
  container_manager="${1}"
  image="${2}"
  echo "eval \"\${container_run_command} \${image} \$@\""
}

__fast__gen_has_image_command()
{
  container_manager="${1}"
  image="${2}"
  echo "[[ \$(${container_manager} images --format {{.Names}}) =~ ${image} ]]"
}

__fast__gen_pull_image_command()
{
  container_manager="${1}"
  image="${2}"
  echo "$(__fast__gen_has_image_command ${container_manager} \"${image}\") || ${container_manager} pull \${image}"
}

__fast__gen_template()
{
  name="${1}"
  if [ ! "${name}" ]; then
    echo "name must be provided."
    exit 1;
  fi
  if [ -f "${name}" ]; then
    echo "${name} has been already existed."
    exit 1
  fi
  shift
  image="${1}"
  if [ ! "${image}" ]; then
    echo "image must be provided."
    exit 1;
  fi
  shift
  container_manager="$(__fast__detect_container_manager)"
  cat <<EOF > "${name}"
#!/bin/sh

container_manager="${container_manager}"
container_run_command="\${container_manager} run -ti --rm -v \`pwd\`:/var/app -w /var/app"
image="${image}"

cmd="\${1}"
shift
case "\${cmd}" in
  pull) $(__fast__gen_pull_image_command ${container_manager} ${image});;
  run) $(__fast__gen_run_command "${container_manager}" "${image}");;
esac
EOF
  chmod +x "${name}"
}
