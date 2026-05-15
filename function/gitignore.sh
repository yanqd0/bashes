# gitignore: Generate .gitignore file from gitignore.io API. {{{
# See: https://www.gitignore.io/docs
function gitignore {
    curl -L -s "https://www.gitignore.io/api/$*"
}
# }}}
