function dry() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf "${@}\n" 1>&2
    return 0
  fi

  $@
}
