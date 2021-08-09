#!/bin/bash
set -e

# runs copyparty (or any other python script really) in a chroot
#
# assumption: these directories, and everything within, are owned by root
sysdirs=(bin lib lib32 lib64 sbin usr)


# error-handler
help() { cat <<'EOF'

usage:
  ./prisonparty.sh <ROOTDIR> <UID> <GID> [VOLDIR [VOLDIR...]] -- copyparty-sfx.py [...]"

example:
  ./prisonparty.sh /var/empty 1000 1000 /mnt/nas/music -- copyparty-sfx.py -v /mnt/nas/music::rwmd"

EOF
exit 1
}


# read arguments
trap help EXIT
jail="$1"; shift
uid="$1"; shift
gid="$1"; shift

vols=()
while true; do
	v="$1"; shift
	[ "$v" = -- ] && break  # end of volumes
	[ "$#" -eq 0 ] && break  # invalid usage
	vols+=("$v")
done
cpp="$1"; shift
cpp="$(realpath "$cpp")"
cppdir="$(dirname "$cpp")"
trap - EXIT


# debug/vis
echo
echo "chroot-dir = $jail"
echo "user:group = $uid:$gid"
echo " copyparty = $cpp"
echo
printf '\033[33m%s\033[0m\n' "copyparty can access these folders and all their subdirectories:"
for v in "${vols[@]}"; do
	printf '\033[36m ├─\033[0m %s \033[36m ── added by (You)\033[0m\n' "$v"
done
printf '\033[36m ├─\033[0m %s \033[36m ── where the copyparty binary is\033[0m\n' "$cppdir"
printf '\033[36m ╰─\033[0m %s \033[36m ── the folder you are currently in\033[0m\n' "$PWD"
vols+=("$cppdir" "$PWD")
echo


# resolve and remove trailing slash
jail="$(realpath "$jail")"
jail="${jail%/}"


# bind-mount system directories and volumes
printf '%s\n' "${sysdirs[@]}" "${vols[@]}" | LC_ALL=C sort |
while IFS= read -r v; do
	[ -e "/$v" ] || {
		# printf '\033[1;31mfolder does not exist:\033[0m %s\n' "$v"
		continue
	}
	mkdir -p "$jail/$v"
	mount | grep -qF " on $jail/$v " ||
		mount --bind /$v "$jail/$v"
done


# create a tmp
mkdir -p "$jail/tmp"
chown -R "$uid:$gid" "$jail/tmp"


# run copyparty
/sbin/chroot --userspec=$uid:$gid "$jail" "$(which python3)" "$cpp" "$@" && rv=0 || rv=$?


# cleanup if not in use
lsof "$jail" | grep -qF "$jail" &&
	echo "chroot is in use, will not cleanup" ||
{
	mount | grep -F " on $jail" |
	awk '{sub(/ type .*/,"");sub(/.* on /,"");print}' |
	LC_ALL=C sort -r  | tr '\n' '\0' | xargs -r0 umount
}
exit $rv
