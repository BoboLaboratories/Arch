#!/bin/sh

get_partition() {
  blkid | grep -i "PARTLABEL=\"$1\"" | cut -d':' -f1
}

input_password() {
  stty -echo

  printf '%s' "$2"
  read -r password

  stty echo
  printf "\n"
  printf '%s' "$password" > "/install/$1-password"
}