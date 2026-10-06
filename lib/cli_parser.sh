#!/bin/bash

parse_args() {
  local cli_dir="$1"
  shift

  if [ $# -eq 0 ]; then
    show_help
    exit 0
  fi

  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    man|--man)
      show_man "$cli_dir"
      exit 0
      ;;
    --init|init)
      init_cli "$cli_dir"
      exit 0
      ;;
    -d|--delete|remove)
      remove_module "$2" "$cli_dir"
      exit 0
      ;;
    create)
      create_project "$2" "$cli_dir"
      exit 0
      ;;
    -m|--module)
      if [ "$3" = "-d" ] || [ "$3" = "--delete" ]; then
        remove_module "$2" "$cli_dir"
      elif [ "$2" = "-d" ] || [ "$2" = "--delete" ]; then
        remove_module "$3" "$cli_dir"
      else
        if [ "$2" = "--standalone" ] || [ "$2" = "-s" ] || [ "$3" = "--standalone" ] || [ "$3" = "-s" ]; then
          echo -e "\033[1;31m[ERROR] L'option '-s' / '--standalone' a ete supprimee. Le developpement isole n'est plus supporte.\033[0m"
          echo -e "\033[1;33mUtilisez directement : ./nx -m <nom_du_module>\033[0m"
          exit 1
        fi
        create_module "$2" "$cli_dir"
      fi
      exit 0
      ;;
    -i|--import)
      if [ "$3" = "-d" ] || [ "$3" = "--delete" ]; then
        remove_module "$2" "$cli_dir"
      else
        import_module "$2" "$3" "$cli_dir" "$4"
      fi
      exit 0
      ;;
    -u|--update)
      update_module "$2"
      exit 0
      ;;
    -p|--push|push)
      push_module "$2" "$3" "$4"
      exit 0
      ;;
    -l|--list)
      list_modules
      exit 0
      ;;
    *)
      echo -e "\033[1;31m[ERROR] Unknown command or option '$1'.\033[0m"
      show_help
      exit 1
      ;;
  esac
}
