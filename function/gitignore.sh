# gitignore: Generate .gitignore file from gitignore.io API. {{{
# See: https://www.gitignore.io/docs
gitignore() {
    curl -L -s "https://www.gitignore.io/api/$*"
}
# }}}
