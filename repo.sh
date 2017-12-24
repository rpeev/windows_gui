#!/bin/sh

git_status() {
  git status
}

git_pull() {
  git pull
}

git_push() {
  git push
}

git_dirty() {
  git clean -xdn
}

git_clean() {
  git reset --hard HEAD && git clean -df
}

git_pristine() {
  git reset --hard HEAD && git clean -xdf
}

git_add() {
  git add $@
}

git_commit() {
  git commit -m "$1"
}

git_undo() {
  git reset HEAD^
}

git_status
#git_pull
#git_push
#git_dirty
#git_clean
#git_pristine
#git_add 'pathspec1' 'pathspecN'
#git_commit 'message'
#git_undo
