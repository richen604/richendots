// keep the picker focused and easy to move through.
const command_mode = glide.modes.get("command");
if (command_mode) {
  command_mode.switch_mode_on_focus = false;
}

glide.autocmds.create("ModeChanged", "command:*", () => {
  setTimeout(() => {
    if (glide.commandline.is_active()) {
      void glide.excmds.execute("mode_change command");
    }
  }, 0);
});

glide.keymaps.set("command", "<C-j>", "commandline_focus_next");
glide.keymaps.set("command", "<C-k>", "commandline_focus_back");
