---
tags:
  - project/richendots
---

# richendots tasks

## how to read this file

Forgejo is authoritative after an item becomes a PRD issue.

- Top-level linked milestone sections are ordered by intended project direction.
- Plain bullets under a milestone are local pre-PRD tasks.
- `### review`, `### ready`, and `### blocked` are Forgejo snapshot lanes.
- `## backlog` is separate local inventory and not assigned to a milestone.

---

## unscheduled

### review

## backlog

- perf: make Firefox optional or switch default browser to Chromium
  - Notes:
    - Firefox costs about `+0.7s` eval on the measured server.
    - `pkgs.ungoogled-chromium` measured near noise-level by comparison.
    - Current Firefox references include `profiles/common-gui.nix`, zsh browser env, Mango keybinds, and MIME defaults.
  - Agent tasks:
    - Inspect `profiles/common-gui.nix`, `wrappers/firefox/default.nix`, `wrappers/zsh/default.nix`, `wrappers/zsh/module.nix`, and `wrappers/mango/_base-config.nix`.
    - Decide whether Firefox should move to an optional profile or Chromium should become the default browser.
    - Update browser package selection, `BROWSER`, MIME defaults, and desktop keybinds consistently.
    - Benchmark Fern eval before and after with `nix eval .#nixosConfigurations.fern.config.system.build.toplevel.drvPath --raw --no-eval-cache`.

- perf: split GUI wrapper packages by need
  - Notes:
    - GUI wrappers cost about `+0.9s`, mostly from Firefox.
    - Non-Firefox wrappers did not show a strong individual eval cost.
  - Agent tasks:
    - Inspect wrapper use in `profiles/common-gui.nix`.
    - Keep always-needed wrappers in `common-gui`.
    - Move optional wrappers to a focused profile only if they are not required on every GUI host.
    - Validate Fern and Oak still evaluate and expose intended commands.

- perf: split common CLI extras from mandatory base packages
  - Notes:
    - Common CLI package bucket costs about `+0.4s`.
    - This is spread across utilities, with `eza` as the clearest single item.
  - Agent tasks:
    - Inspect `profiles/common.nix` package groups.
    - Create or identify a smaller mandatory CLI base and a fuller CLI extras group.
    - Keep host/user workflow behavior unchanged unless a package is intentionally made optional.
    - Benchmark the profile split against current Fern eval.

- perf: decide whether `eza` is worth always-on eval cost
  - Notes:
    - `pkgs.eza` alone measured about `+0.2s`.
    - zsh aliases currently assume `eza`.
  - Agent tasks:
    - Inspect `profiles/common.nix` and `wrappers/zsh/default.nix`.
    - Either keep `eza` intentionally or replace aliases with coreutils-compatible fallbacks.
    - If removing `eza` from common packages, ensure shell aliases remain valid.
    - Benchmark Fern eval before and after.

- perf: split GUI non-wrapper packages into focused subprofiles
  - Notes:
    - GUI non-wrapper packages cost about `+0.55s` total, spread across KDE/Qt, GTK, apps, and utilities.
    - No single app besides Firefox showed a large individual cost.
  - Agent tasks:
    - Inspect `profiles/common-gui.nix` package groups.
    - Propose subprofiles such as KDE/Dolphin integration, media apps, hardware tools, and extra GUI apps.
    - Move only clearly optional packages out of `common-gui`.
    - Validate Fern and Oak eval and expected GUI package availability.

- perf: evaluate whether PipeWire/audio should stay in common GUI
  - Notes:
    - PipeWire/audio service stack costs about `+0.4s`.
    - This is likely inherent service/module cost and should usually stay on desktop/laptop hosts.
  - Agent tasks:
    - Inspect `profiles/common-gui.nix` audio packages and services.
    - Decide whether audio belongs in all GUI profiles or a separate audio-enabled profile.
    - Avoid changing runtime audio behavior unless the split is explicit and host-safe.
    - Benchmark eval and document tradeoff.

- perf: make OBS CUDA support optional
  - Notes:
    - OBS module costs about `+0.2s`.
    - CUDA OBS also affects build-plan weight.
  - Agent tasks:
    - Inspect `programs.obs-studio` in `profiles/common-gui.nix`.
    - Move OBS or CUDA-enabled OBS into an optional feature/profile if it is not needed on every GUI host.
    - Preserve virtual camera support where OBS remains enabled.
    - Benchmark eval and dry-run build plan before and after.

- perf: make Flatpak optional if only needed for Spotify
  - Notes:
    - Portal plus Flatpak measured about `+0.18s`.
    - Portal is likely needed for Wayland desktop behavior; Flatpak may be optional if only supporting Spotify.
  - Agent tasks:
    - Inspect `services.flatpak`, `xdg.portal`, and `profiles/scripts/spotify-spicetified.nix`.
    - Keep portal enabled unless a replacement is proven safe.
    - Move Flatpak and Spotify Flatpak script behind an optional profile if appropriate.
    - Validate portal eval and Spotify workflow assumptions.

- perf: keep desktop session services explicit and measured
  - Notes:
    - greetd, graphical-desktop, and XWayland measured about `+0.16s`.
    - These are expected desktop costs, not obvious waste.
  - Agent tasks:
    - Inspect `profiles/common-gui.nix` and `profiles/desktop.nix` session wiring.
    - Confirm which hosts require greetd, graphical desktop support, and XWayland.
    - Only split these services if a no-session or lite-GUI profile is actually useful.
    - Benchmark eval if any session split is made.

## [desktop reliability](https://git.cedar.richen.sh/richen/richendots/milestones/10)

- fix: media playing should prevent idle
  - Notes:
    - Media playback should reliably inhibit idle behavior.
    - Existing swayidle and idle-inhibit wiring should be inspected before changing behavior.
  - Agent tasks:
    - Inspect current swayidle wrappers and profile wiring.
    - Verify whether `wayland-pipewire-idle-inhibit` is installed, active, and sufficient.
    - Apply the smallest config, wrapper, or service change that makes media playback inhibit idle.
    - Validate affected desktop and laptop profiles.

- fix: dolphin doesnt grab default programs, shows 0 programs
  - Notes:
    - Dolphin currently fails to discover default programs and reports zero programs.
    - First attempted fix is `XDG_MENU_PREFIX=nixos- kbuildsycoca6 --noincremental`.
    - If that fails, Dolphin may need a wrapper or KService/XDG environment wiring.
  - Agent tasks:
    - Inspect current Dolphin and XDG desktop integration in the GUI profile.
    - Test or encode the `XDG_MENU_PREFIX=nixos- kbuildsycoca6 --noincremental` path where appropriate.
    - Add a wrapper or environment fix only if the simple cache rebuild path is insufficient.
    - Validate Dolphin sees default applications after the change.

- systemd services for all autostart apps
  - Notes:
    - Autostart should be declarative and reliable across sessions.
    - Current exec-once style startup should be reviewed before replacing it broadly.
  - Agent tasks:
    - Inventory current autostart apps and where they are launched.
    - Identify which apps should become systemd user services.
    - Add focused service definitions without changing unrelated session behavior.
    - Validate services start in the intended profiles.

- feat: screenshot should freeze screen
  - Notes:
    - Screenshot UX should freeze the screen while selecting or capturing.
    - Keep the change focused on screenshot behavior, not a broad screenshot workflow rewrite.
  - Agent tasks:
    - Inspect current screenshot tooling and keybindings.
    - Identify a freeze-capable capture path compatible with the current desktop stack.
    - Wire the freeze behavior into the existing screenshot command.
    - Validate capture output and interaction behavior.

- fix: keepass does not start on boot, windowrule to open it center on fern and oak
  - Notes:
    - KeepassXC should start reliably on boot/session start.
    - Fern and Oak should get centered window placement where host-specific rules apply.
  - Agent tasks:
    - Inspect current KeepassXC wrapper, autostart, and Mango/window-rule configuration.
    - Fix startup through the preferred autostart or systemd path.
    - Add host-appropriate window placement rules for Fern and Oak.
    - Validate KeepassXC starts and opens in the expected position.

- fern: fix: plymouth aligned weird
  - Notes:
    - Fern has host-specific Plymouth alignment issues.
    - Keep the fix isolated to Fern unless shared config is clearly wrong.
  - Agent tasks:
    - Inspect Fern host display and boot visual configuration.
    - Identify whether Plymouth alignment is controlled by resolution, theme, or host settings.
    - Apply the smallest host-specific correction.
    - Document any manual reboot check that cannot be automated.

- fern: monitor alignment is slightly off for left and right
  - Notes:
    - Fern monitor layout is slightly misaligned for left and right displays.
    - This should remain host-specific unless a shared monitor abstraction exists.
  - Agent tasks:
    - Inspect Fern monitor layout configuration.
    - Correct left/right monitor coordinates or scaling values.
    - Validate the resulting layout with the intended display arrangement.
    - Avoid changing Oak or Cedar display behavior unless shared config requires it.

- feat: use new chooser for xdg-desktop-portal
  - Notes:
    - Portal chooser behavior should use the newer preferred chooser implementation.
    - Current portal packages include WLR and GTK components.
  - Agent tasks:
    - Inspect current xdg-desktop-portal packages and configuration.
    - Identify the new chooser package/config needed for the desktop stack.
    - Add the chooser with minimal portal churn.
    - Validate portal chooser behavior from a representative app if possible.

- wrap:
  - Notes:
    - Desktop utility wrappers should follow the repo's existing wrapper patterns.
    - Keep app-specific behavior minimal until each app needs a deeper pass.
  - Apps:
    - mpv
    - wlogout
    - yazi
  - Agent tasks:
    - Inspect existing wrapper conventions in `wrappers/`.
    - Add wrappers for mpv, wlogout, and yazi where they share the same pattern.
    - Wire wrappers into the appropriate profiles.
    - Validate each wrapped binary resolves from the expected user environment.

- keepassxc: not sure if config actually works
  - Notes:
    - The current KeepassXC wrapper/config may not be applying as intended.
    - Browser integration may require manual configuration outside the generated ini.
  - Agent tasks:
    - Inspect `wrappers/keepassxc` module and generated config path.
    - Compare configured settings against the runtime KeepassXC config file location.
    - Fix config generation or wrapper placement if settings are not applied.
    - Document any required manual browser-integration step.
## [workstation workflow](https://git.cedar.richen.sh/richen/richendots/milestones/11)

- fix: git doesnt set the default user, is my git wrapper working?
  - Notes:
    - Current suspicion is wrapper or profile integration rather than Git itself.
    - The intended user identity appears to live in `wrappers/git.nix`.
  - Agent tasks:
    - Inspect the Git wrapper and profile package selection.
    - Verify which `git` binary is used in an interactive shell.
    - Confirm `user.name` and `user.email` are applied through the intended path.
    - Fix wrapper or config wiring if needed.

- fix: nvim plugins currently don't load declaratively and wrapped, install to .config
  - Notes:
    - Neovim plugins should load declaratively through the wrapped setup.
    - Installing to `.config` may be needed if wrapper/runtime paths are not enough.
  - Agent tasks:
    - Inspect the current Neovim wrapper and plugin loading path.
    - Determine whether plugins should be exposed through runtime path or generated config files.
    - Implement the smallest declarative loading fix.
    - Validate Neovim starts with expected plugins available.

- feat: dec llm workflows using opencode and roo
  - Notes:
    - LLM workflow setup should be declarative enough to reproduce across machines.
    - Keep opencode and roo integration separate from broad tmux/project launcher work unless the overlap is trivial.
  - Agent tasks:
    - Inventory existing opencode and roo configuration expectations.
    - Add declarative package/config entrypoints where practical.
    - Handle secrets through the repo's preferred secret mechanism if needed.
    - Document the command path for starting each workflow.

- feat: wrap tmux
  - Notes:
    - Desired plugin set includes vim-tmux-navigator, tmux-yank, tmux-continuum, and tmux-thumbs.
    - Desired behavior includes resurrect-style sessions, panes, tabs, and good AstroNvim keybind support.
    - Tmuxinator integration may be follow-up if it makes the first pass too large.
  - References:
    - <https://www.reddit.com/r/AstroNvim/comments/10x45rm/wow_tmux_navigation_works_outofthebox/>
    - christoomey/vim-tmux-navigator
    - tmux-plugins/tmux-yank
    - tmux-plugins/tmux-continuum
    - <https://github.com/fcsonline/tmux-thumbs?tab=readme-ov-file>
  - Agent tasks:
    - Add a tmux wrapper following existing wrapper conventions.
    - Configure core plugins and keybindings.
    - Add session/pane/tab persistence if it stays compact.
    - Validate tmux and AstroNvim navigation work together.

- some sort of project loader for tmux/nvim
  - Notes:
    - Desired loader combines tmuxinator with fzf or gum and a mutable project list.
    - Project list needs to be host-dependent, because Fern may use a different set of projects.
    - If tmux is wrapped, the loader may need to resolve the current Nix store path for tmuxinator.
  - Ideas:
    - Merge mutable and Nix-owned tmuxinator YAML with jq or equivalent.
    - Auto-open opencode and opencode-web tabs for project sessions.
    - Include a bare terminal tab template.
    - Run opencode web with `OPENCODE_SERVER_PASSWORD=secret opencode web --mdns --mdns-domain oc-myproject.local`.
    - Store the opencode web secret with sops.
    - Decide how Godot projects should launch.
  - Agent tasks:
    - Design the smallest host-aware project list format.
    - Prototype a launcher path using tmuxinator, fzf, gum, or the simplest existing tool.
    - Keep mutable user project data separate from generated Nix config.
    - Document how to add a new project template.

- research: way to display cheat sheets for astronvim, nvim, tmux, glove80
  - Notes:
    - This should start as research unless an obvious implementation path already exists.
    - Cheat sheets should be quick to access during real workflow use.
  - Agent tasks:
    - Compare lightweight display options such as terminal menus, launcher menus, or editor commands.
    - Identify source format for AstroNvim, Neovim, tmux, and Glove80 shortcuts.
    - Recommend one implementation path.
    - Implement only if the scope stays small and clear.

- style: theme astronvim to grove theme
  - Notes:
    - AstroNvim should visually match the Grove theme direction.
    - This can proceed before global Grove tokens if hard-coded values are acceptable temporarily.
  - Agent tasks:
    - Inspect current AstroNvim theme configuration.
    - Add Grove theme colors or theme selection.
    - Verify editor UI, syntax, and plugin surfaces remain readable.
    - Keep reusable palette extraction as a separate platform task if needed.

- grove zed theme that doesn't look like garbage
  - Notes:
    - Zed should get a Grove-inspired theme that is usable, not just mechanically ported.
    - Prefer readability over strict palette purity.
  - Agent tasks:
    - Inspect current Zed config location and theme support.
    - Create or adjust a Grove Zed theme.
    - Validate editor, panel, and syntax contrast.
    - Keep secrets out of committed Zed settings.

- zed settings with hjem
  - Notes:
    - Zed settings should be managed with hjem where practical.
    - Server-related secrets may complicate full declarative management.
  - Agent tasks:
    - Inspect current hjem usage and Zed settings needs.
    - Separate safe settings from secret-bearing settings.
    - Add hjem-managed Zed settings for non-secret config.
    - Document any intentionally unmanaged secret settings.

- finish theming obsidian
  - Notes:
    - Obsidian should match the broader Grove visual direction.
    - Avoid coupling this to plugin management unless needed.
  - Agent tasks:
    - Inspect existing Obsidian theme/config state.
    - Apply missing theme assets or settings.
    - Validate common note views remain readable.
    - Record any manual Obsidian setting that cannot be managed declaratively.

- obsidian - declarative plugins?
  - Notes:
    - Determine whether Obsidian plugins can be managed declaratively in this repo.
    - This may be research-first if plugin state is mutable or sync-owned.
  - Agent tasks:
    - Inspect current Obsidian config and plugin storage.
    - Research Nix/home-manager/hjem-compatible plugin management options from local context if present.
    - Recommend whether declarative plugin management is worth doing.
    - Implement only if it stays reliable and low-risk.

- feat: port richenfox config to glide
  - Notes:
    - Richenfox configuration should move to Glide if that is the chosen browser config path.
    - Coordinate with Firefox privacy and private-wrapper work.
  - Agent tasks:
    - Inspect existing richenfox and Firefox wrapper configuration.
    - Identify the Glide-compatible config shape.
    - Port settings without changing unrelated browser behavior.
    - Validate generated browser config where possible.

- firefox: wrapper should be private
  - Notes:
    - Firefox wrapper may contain private preferences or account-specific behavior.
    - Public repo should only retain generic reusable pieces.
  - Agent tasks:
    - Inspect current Firefox wrapper for private assumptions.
    - Identify what belongs in richendots-private versus this repo.
    - Move or split config boundaries without breaking public profiles.
    - Document the expected private overlay behavior.

- firefox: migrate password manager fully, migrate from sync
  - Notes:
    - Browser password state should move away from Firefox Sync.
    - This may require human verification before final cutover.
  - Agent tasks:
    - Inspect current browser and KeepassXC integration assumptions.
    - Identify config needed for the preferred password manager workflow.
    - Add declarative integration where safe.
    - Document manual migration and verification steps.

- firefox: <https://codeberg.org/librewolf/settings/src/branch/master/librewolf.cfg>
  - Notes:
    - Librewolf-style settings should be easier to view by importing a separate cfg file.
    - Remove options for RFP, WebGL, and `startup.homepage_*` where unwanted.
  - Agent tasks:
    - Create or identify a separate readable browser cfg import path.
    - Port relevant Librewolf settings selectively.
    - Remove unwanted RFP, WebGL, and homepage settings.
    - Validate final preferences are applied by the wrapper/config.

- keybinds menu with vicinae?
  - Notes:
    - Vicinae may be a good surface for showing keybinds.
    - This should stay separate from cheat-sheet research if it becomes app-specific.
  - Agent tasks:
    - Inspect current Vicinae wrapper capabilities.
    - Determine whether a keybinds menu fits Vicinae extension/script support.
    - Add a small menu if the integration is straightforward.
    - Document how keybind entries are maintained.

- vicinae: add extensions support for vicinae wrapper
  - Notes:
    - The Vicinae wrapper should support extensions declaratively.
    - Keep extension mechanism reusable for later menus/scripts.
  - Agent tasks:
    - Inspect current Vicinae wrapper module.
    - Add extension package/config support.
    - Wire extensions into the user environment.
    - Validate Vicinae sees configured extensions.

- some qol scripts / menus for vicinae
  - Notes:
    - Vicinae can host small quality-of-life scripts and menus.
    - Avoid adding a large script framework before extension support is clear.
  - Agent tasks:
    - Identify the first small set of useful scripts or menus.
    - Add scripts using the existing or newly added Vicinae wrapper support.
    - Keep host-specific behavior explicit.
    - Document how to add more scripts later.

## [platform evolution](https://git.cedar.richen.sh/richen/richendots/milestones/12)

- feat: nixos-anywhere support + dev-shell
  - Notes:
    - Bootstrap/install workflows should be reproducible from the repo.
    - Dev shell should support the common repo commands needed by humans and agents.
  - Agent tasks:
    - Add or revise the dev shell for repo workflows.
    - Add nixos-anywhere support for intended hosts.
    - Document expected bootstrap commands.
    - Validate with normal Nix checks where available.

- feat: richendots-private should inherit richendots inputs
  - Notes:
    - Private repo should follow this repo's inputs instead of duplicating pins where possible.
    - Preserve private host behavior while reducing input drift.
  - Agent tasks:
    - Inspect public flake input structure and private input expectations from available references.
    - Design a clean follow/inheritance path for shared inputs.
    - Update public-side integration points if needed.
    - Document required private repo changes if they cannot be made here.

- feat: firmware for glove80 <https://git.sr.ht/~x10an14/glove80-layout/tree/main/item/flake.nix>
  - Notes:
    - Glove80 firmware should have a reproducible build or update path.
    - Decide whether this belongs in host configuration, user workflow, or both.
  - Agent tasks:
    - Inspect the referenced firmware flake approach.
    - Add an integration point appropriate for this repo.
    - Document build/update commands.
    - Avoid forcing firmware tooling into hosts that do not need it.

- feat: limine secure boot
  - Notes:
    - Secure boot support is host provisioning work and may depend on disk/bootloader choices.
    - Keep manual enrollment requirements explicit.
  - Agent tasks:
    - Inspect current bootloader and host boot configuration.
    - Add Limine secure boot support or a staged configuration path.
    - Document manual key/enrollment steps.
    - Validate configuration evaluation where possible.

- feat: disko configurations + luks
  - Notes:
    - Disko and LUKS should support reproducible secure host provisioning.
    - Coordinate with nixos-anywhere and secure boot work where dependencies are real.
  - Agent tasks:
    - Inspect host hardware configuration and current disk assumptions.
    - Add focused disko/LUKS configs for intended hosts or templates.
    - Document destructive install steps clearly.
    - Validate Nix evaluation without running destructive disk operations.

- clean up flake.nix
  - Notes:
    - Flake cleanup should reduce friction without hiding current structure.
    - Avoid broad architecture rewrites in the first cleanup pass.
  - Agent tasks:
    - Inspect current `flake.nix` structure and repeated patterns.
    - Apply small readability and organization improvements.
    - Preserve existing outputs and host behavior.
    - Validate flake evaluation after cleanup.

- global color palette, grove.css to nix
  - Notes:
    - Grove palette should become reusable Nix-facing design tokens.
    - Editor/app theming can consume this later where practical.
  - Agent tasks:
    - Identify current Grove CSS or palette source.
    - Convert palette values into a reusable Nix representation.
    - Expose values to consumers without forcing all themes to migrate at once.
    - Document token names and intended usage.

- refactor to use [nosh](https://codeberg.org/poacher/nosh/src/branch/main)
  - Notes:
    - Desired direction is feature-based modules alongside profiles, such as `profiles/common/feature.nix`.
    - Modules should become more modular.
    - Private repo should also have a nosh integration path.
  - Agent tasks:
    - Evaluate how nosh maps to the current profile/module structure.
    - Identify a small first refactor target instead of migrating everything at once.
    - Add or document private repo integration expectations.
    - Validate that existing hosts still evaluate.

- npins & a post flake world?
  - Notes:
    - This is research-first until the benefit over flakes is clear.
    - Any recommendation should account for private repo inputs and nixpull workflows.
  - Agent tasks:
    - Compare current flake-based workflow against npins or non-flake alternatives.
    - Identify concrete pain points this would solve.
    - Recommend whether to keep flakes, supplement them, or plan a migration.
    - Avoid implementation before the recommendation is accepted.

## references

- yubikey <https://wiki.nixos.org/wiki/Yubikey>
- hardening, disko, luks, etc <https://tsawyer87.github.io/posts/hardening_nixos/>
