{
  pkgs,
  richenLib,
  ...
}:
# some of the options from https://jvns.ca/blog/2024/02/16/popular-git-config-options/
let
  config = (pkgs.formats.gitIni { }).generate "gitconfig" {
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
      signingkey = "/home/richen/.ssh/id_ed25519_sk";
    };
    rebase.autoStash = true;
    # detect data corruption eagerly
    transfers.fsckObjects = true;
    fetch.fsckObjects = true;
    receive.fsckObjects = true;
    # makes git branch sort by most recently used branches instead of alphabetical
    branch.sort = "-committerdate";
    # signed commits with ssh
    gpg = {
      format = "ssh";
      ssh.allowedSignersFile = "/run/secrets/users/richen/git_allowed_signers";
    };
    commit.gpgSign = true;
    tag.gpgSign = true;
    merge.conflictStyle = "zdiff3";
  };
in
richenLib.lib.wrapPackage {
  package = pkgs.git;
  env.GIT_CONFIG_GLOBAL = config;
  passthru.config.path = config;
}
