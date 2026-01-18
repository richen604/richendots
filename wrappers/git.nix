{
  inputs,
  pkgs,
  ...
}:
# some of the options from https://jvns.ca/blog/2024/02/16/popular-git-config-options/
(inputs.wrappers.wrapperModules.git.apply {
  pkgs = pkgs;
  settings = {
    core = {
      editor = "nvim";
      visual = "nvim";
      # todo: git: impl git-delta
      # https://github.com/dandavison/delta
      # pager = "delta";

      # todo: git: impl global gitignore, use pkgs.writeTextFile
      # excludesfile = "";
    };
    init.defaultBranch = "main";
    pull.rebase = true;
    push.autoSetupRemote = true;
    user = {
      name = "richen604";
      email = "56615615+richen604@users.noreply.github.com";
    };
    rebase.autoStash = true;
    # redirect github https to ssh
    "url \"git@github.com:\"".insteadOf = "https://github.com";
    # detect data corruption eagerly
    transfers.fsckObjects = true;
    fetch.fsckObjects = true;
    receive.fsckObjects = true;
    # makes git branch sort by most recently used branches instead of alphabetical
    branch.sort = "-committerdate";
    # signed commits with ssh
    gpg.format = "ssh";
    merge.conflictStyle = "zdiff3";
  };
}).wrapper
