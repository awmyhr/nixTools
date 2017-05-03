/usr/bin/docker run --rm -it \
                    --user=$(id -un) \
                    --volume="${HOME}:/home/$(id -un):rw" \
                    --workdir=/home/$(id -un)/${PWD#${HOME}} \
                    --volume="/etc/group:/etc/group:ro" \
                    --volume="/etc/passwd:/etc/passwd:ro" \
                    ansible-alpine
