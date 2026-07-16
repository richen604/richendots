{
  pkgs,
  richenLib,
  ...
}:
# some of the options from https://jvns.ca/blog/2024/02/16/popular-git-config-options/
let
  config = (pkgs.formats.gitIni { }).generate "gitconfig" (
    pkgs.lib.recursiveUpdate {
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
      rebase.autoStash = true;
      # detect data corruption eagerly
      transfers.fsckObjects = true;
      fetch.fsckObjects = true;
      receive.fsckObjects = true;
      # makes git branch sort by most recently used branches instead of alphabetical
      branch.sort = "-committerdate";
      merge.conflictStyle = "zdiff3";
    } richenLib.vars.private.git.config
  );
in
richenLib.lib.wrapPackage {
  package = pkgs.git;
  env.GIT_CONFIG_GLOBAL = config;
  passthru.config.path = config;
}
