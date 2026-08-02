// always show the current glide mode and focused thing.
type FocusState =
  | "page"
  | "input"
  | "textarea"
  | "select"
  | "editable"
  | "video"
  | "audio"
  | "button"
  | "link"
  | "control"
  | "frame"
  | "urlbar"
  | "commandline"
  | "find"
  | "browser";

type FocusMessages = {
  focus_page: never;
  focus_input: never;
  focus_textarea: never;
  focus_select: never;
  focus_editable: never;
  focus_video: never;
  focus_audio: never;
  focus_button: never;
  focus_link: never;
  focus_control: never;
  focus_frame: never;
};

const state_badge_id = "glide-state-badge";
let current_mode: GlideMode = glide.ctx.mode;
let current_focus: FocusState = "page";
let state_badge = document.getElementById(state_badge_id);

glide.styles.add(css`
  #glide-state-badge {
    position: fixed;
    right: 12px;
    bottom: 12px;
    z-index: 2147483647;
    box-sizing: border-box;
    padding: 3px 7px;
    pointer-events: none;
    user-select: none;
    font-family: var(--glide-status-font-family);
    font-size: var(--glide-status-font-size);
    line-height: 1.2;
    color: var(--glide-status-fg);
    background: var(--glide-status-bg);
    border: var(--glide-status-border);
    border-left: 3px solid var(--glide-current-mode-color, var(--glide-fallback-mode));
    border-radius: var(--glide-status-border-radius);
  }
`, { id: state_badge_id, overwrite: true });

function render_state_badge(): void {
  if (!state_badge) {
    return;
  }

  const text = `${current_mode} · ${current_focus}`.toLowerCase();
  if (state_badge.textContent !== text) {
    state_badge.textContent = text;
  }
  state_badge.setAttribute("data-mode", current_mode);
}

function set_focus(focus: FocusState): void {
  current_focus = focus;
  render_state_badge();
}

function track_browser_focus(): void {
  document.documentElement.addEventListener("focusin", (event: FocusEvent) => {
    const target = event.target;
    if (!(target instanceof Element)) {
      return;
    }

    if (target.tagName.toLowerCase() === "browser") {
      return;
    }
    if (target.id === "urlbar-input" || target.closest("#urlbar")) {
      set_focus("urlbar");
    } else if (target.closest("glide-commandline")) {
      set_focus("commandline");
    } else if (target.closest("findbar")) {
      set_focus("find");
    } else {
      set_focus("browser");
    }
  }, true);
}

function setup_state_badge(): void {
  if (!state_badge) {
    state_badge = DOM.create_element("div", {
      id: state_badge_id,
      attributes: { "aria-live": "polite" },
    });
    document.documentElement.appendChild(state_badge);
  }

  render_state_badge();
  track_browser_focus();
}

if (state_badge) {
  setup_state_badge();
} else {
  // browser document mutations require windowloaded during startup.
  glide.autocmds.create("WindowLoaded", setup_state_badge);
}

glide.autocmds.create("ModeChanged", "*", ({ new_mode }) => {
  current_mode = new_mode;
  render_state_badge();
});

const focus_states = new Set<FocusState>([
  "page",
  "input",
  "textarea",
  "select",
  "editable",
  "video",
  "audio",
  "button",
  "link",
  "control",
  "frame",
]);

const focus_messenger = glide.messengers.create<FocusMessages>(({ name }) => {
  const focus = name.slice("focus_".length) as FocusState;
  if (focus_states.has(focus)) {
    set_focus(focus);
  }
});

function install_focus_tracker(tab_id: number): void {
  focus_messenger.content.execute((messenger) => {
    type TrackerWindow = Window & {
      __glide_focus_tracker?: {
        focusin: (event: FocusEvent) => void;
        focusout: () => void;
      };
    };

    const tracker_window = window as TrackerWindow;
    const previous = tracker_window.__glide_focus_tracker;
    if (previous) {
      document.removeEventListener("focusin", previous.focusin, true);
      document.removeEventListener("focusout", previous.focusout, true);
    }

    function report(target: EventTarget | null): void {
      const element = target instanceof Element ? target : document.activeElement;
      if (!(element instanceof Element) || element === document.body || element === document.documentElement) {
        messenger.send("focus_page");
        return;
      }

      const tag = element.tagName.toLowerCase();
      if (tag === "video") {
        messenger.send("focus_video");
      } else if (tag === "audio") {
        messenger.send("focus_audio");
      } else if (tag === "textarea") {
        messenger.send("focus_textarea");
      } else if (tag === "select") {
        messenger.send("focus_select");
      } else if (tag === "input") {
        messenger.send("focus_input");
      } else if (element.closest("[contenteditable]:not([contenteditable='false'])")) {
        messenger.send("focus_editable");
      } else if (tag === "button" || element.getAttribute("role") === "button") {
        messenger.send("focus_button");
      } else if ((tag === "a" && element.hasAttribute("href")) || element.getAttribute("role") === "link") {
        messenger.send("focus_link");
      } else if (tag === "iframe") {
        messenger.send("focus_frame");
      } else if (element.hasAttribute("tabindex") || element.hasAttribute("role")) {
        messenger.send("focus_control");
      } else {
        messenger.send("focus_page");
      }
    }

    const focusin = (event: FocusEvent) => {
      report(event.composedPath()[0] ?? event.target);
    };
    const focusout = () => queueMicrotask(() => {
      if (document.hasFocus()) {
        report(document.activeElement);
      }
    });

    tracker_window.__glide_focus_tracker = { focusin, focusout };
    document.addEventListener("focusin", focusin, true);
    document.addEventListener("focusout", focusout, true);
    report(document.activeElement);
  }, { tab_id });
}

async function install_active_focus_tracker(): Promise<void> {
  const tab = await glide.tabs.active();
  if (tab.id !== undefined) {
    install_focus_tracker(tab.id);
  }
}

glide.autocmds.create("ConfigLoaded", () => {
  void install_active_focus_tracker();
});

glide.autocmds.create("UrlEnter", /.*/, ({ tab_id }) => {
  install_focus_tracker(tab_id);
});
