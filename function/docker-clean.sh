# docker-clean: Clean docker containers, images and volumes. {{{
function docker-clean {
    docker rm $(docker ps -aq) 2> /dev/null
    docker rmi $(docker images -qf "dangling=true") 2> /dev/null
    # docker volume prune -f 2> /dev/null
}
# }}}
