#!/usr/bin/env python3

import argparse
import json
import re
from pathlib import Path


DEFINE_MARKER = "/* Automatically generated layer name defines */"
KEYMAP_MARKER = "/* Automatically generated keymap */"
CUSTOM_MARKER = "/* Custom Defined Behaviors */"
KVM_MARKER = "/* Richendots TESmart KVM macros */"

KVM_MACROS = f"""{KVM_MARKER}
/ {{
    macros {{
        kvm_pc1: kvm_pc1 {{
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            wait-ms = <100>;
            tap-ms = <40>;
            bindings = <&macro_tap &kp INSERT>,
                       <&macro_tap &kp INSERT>,
                       <&macro_tap &kp N1>;
        }};
        kvm_pc2: kvm_pc2 {{
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            wait-ms = <100>;
            tap-ms = <40>;
            bindings = <&macro_tap &kp INSERT>,
                       <&macro_tap &kp INSERT>,
                       <&macro_tap &kp N2>;
        }};
        kvm_monitor1: kvm_monitor1 {{
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            wait-ms = <100>;
            tap-ms = <40>;
            bindings = <&macro_tap &kp INSERT>,
                       <&macro_tap &kp INSERT>,
                       <&macro_tap &kp LEFT>;
        }};
        kvm_monitor2: kvm_monitor2 {{
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            wait-ms = <100>;
            tap-ms = <40>;
            bindings = <&macro_tap &kp INSERT>,
                       <&macro_tap &kp INSERT>,
                       <&macro_tap &kp DOWN>;
        }};
        kvm_monitor3: kvm_monitor3 {{
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            wait-ms = <100>;
            tap-ms = <40>;
            bindings = <&macro_tap &kp INSERT>,
                       <&macro_tap &kp INSERT>,
                       <&macro_tap &kp RIGHT>;
        }};
        kvm_keyboard_mouse: kvm_keyboard_mouse {{
            compatible = "zmk,behavior-macro";
            #binding-cells = <0>;
            wait-ms = <100>;
            tap-ms = <40>;
            bindings = <&macro_tap &kp RALT>,
                       <&macro_tap &kp RALT>;
        }};
    }};
}};
"""

KVM_BASE_BINDINGS = {
    1: "&kvm_pc1",
    2: "&kvm_pc2",
    5: "&kvm_monitor1",
    6: "&kvm_monitor2",
    7: "&kvm_monitor3",
    8: "&kvm_keyboard_mouse",
}

KVM_BASE_COLORS = {
    1: "GRN",
    2: "BLU",
    5: "ORN",
    6: "ORN",
    7: "ORN",
    8: "MAJ",
}


def layer_blocks(text: str) -> list[tuple[str, int, int]]:
    keymap_start = text.index(KEYMAP_MARKER)
    starts = list(
        re.finditer(r"^        layer_([A-Za-z0-9_]+) \{$", text[keymap_start:], re.MULTILINE)
    )
    blocks = []

    for match in starts:
        start = keymap_start + match.start()
        cursor = keymap_start + match.end()
        depth = 1
        while depth:
            if cursor >= len(text):
                raise ValueError(f"unterminated layer block: {match.group(1)}")
            if text[cursor] == "{":
                depth += 1
            elif text[cursor] == "}":
                depth -= 1
            cursor += 1
        if not text[cursor:].startswith(";"):
            raise ValueError(f"layer block has no closing semicolon: {match.group(1)}")
        blocks.append((match.group(1), start, cursor + 1))

    if not blocks:
        raise ValueError("no generated layer blocks found")
    return blocks


def layer_definitions(text: str) -> tuple[int, int, list[tuple[str, int]]]:
    marker_start = text.index(DEFINE_MARKER)
    start = text.index("\n", marker_start) + 1
    end = text.index("\n\n", start)
    definitions = [
        (match.group(1), int(match.group(2)))
        for match in re.finditer(
            r"^#define LAYER_([A-Za-z0-9_]+) ([0-9]+)$",
            text[start:end],
            re.MULTILINE,
        )
    ]
    if not definitions:
        raise ValueError("no generated layer definitions found")
    return start, end, definitions


def add_kvm_macros(text: str) -> str:
    if KVM_MARKER in text:
        return text
    keymap_start = text.index(KEYMAP_MARKER)
    return text[:keymap_start] + KVM_MACROS + "\n" + text[keymap_start:]


def add_kvm_bindings(text: str, primary_layer: str) -> str:
    block = next(
        (entry for entry in layer_blocks(text) if entry[0] == primary_layer),
        None,
    )
    if block is None:
        raise ValueError(f"cannot add KVM bindings to missing layer: {primary_layer}")

    _, start, end = block
    layer = text[start:end]
    bindings = re.search(
        r"bindings = <\n(?P<rows>.*?)\n\s+>;",
        layer,
        re.MULTILINE | re.DOTALL,
    )
    if bindings is None:
        raise ValueError(f"layer has no bindings block: {primary_layer}")

    rows = bindings.group("rows").splitlines()
    nonempty_rows = [index for index, row in enumerate(rows) if row.strip()]
    if len(nonempty_rows) != 6:
        raise ValueError(f"layer does not have six physical rows: {primary_layer}")

    first_index = nonempty_rows[0]
    first_row = rows[first_index]
    row_bindings = re.split(r"\s{2,}", first_row.strip())
    if len(row_bindings) != 10:
        raise ValueError("base top row does not have ten bindings")

    for index, desired in KVM_BASE_BINDINGS.items():
        if row_bindings[index] not in {"&none", desired}:
            raise ValueError(
                f"refusing to replace occupied KVM key {index}: {row_bindings[index]}"
            )
        row_bindings[index] = desired

    indentation = first_row[: len(first_row) - len(first_row.lstrip())]
    rows[first_index] = indentation + "  ".join(row_bindings)
    replacement = "\n".join(rows)
    layer = layer[: bindings.start("rows")] + replacement + layer[bindings.end("rows") :]
    return text[:start] + layer + text[end:]


def add_kvm_colors(text: str) -> str:
    start = text.index("      BaseLayer {")
    end = text.index("      };", start) + len("      };")
    block = text[start:end]
    bindings = re.search(
        r"bindings = <\n(?P<rows>.*?)\n\s+>;",
        block,
        re.MULTILINE | re.DOTALL,
    )
    if bindings is None:
        raise ValueError("base RGB layer has no bindings block")

    rows = bindings.group("rows").splitlines()
    nonempty_rows = [index for index, row in enumerate(rows) if row.strip()]
    if len(nonempty_rows) != 6:
        raise ValueError("base RGB layer does not have six physical rows")

    first_index = nonempty_rows[0]
    first_row = rows[first_index]
    colors = re.split(r"\s+", first_row.strip())
    if len(colors) != 10:
        raise ValueError("base RGB top row does not have ten colors")

    for index, desired in KVM_BASE_COLORS.items():
        if colors[index] not in {"___", desired}:
            raise ValueError(
                f"refusing to replace occupied KVM color {index}: {colors[index]}"
            )
        colors[index] = desired

    indentation = first_row[: len(first_row) - len(first_row.lstrip())]
    rows[first_index] = indentation + " ".join(colors)
    replacement = "\n".join(rows)
    block = block[: bindings.start("rows")] + replacement + block[bindings.end("rows") :]
    return text[:start] + block + text[end:]


def customize(text: str, primary_layer: str, operating_system: str) -> str:
    custom_start = text.index(CUSTOM_MARKER)
    keymap_start = text.index(KEYMAP_MARKER, custom_start)
    os_matches = re.findall(
        r"^#define OPERATING_SYSTEM '([LMW])'",
        text[custom_start:keymap_start],
        re.MULTILINE,
    )
    if not os_matches or os_matches[0] != operating_system:
        actual = os_matches[0] if os_matches else "missing"
        raise ValueError(
            f"Custom Defined Behaviors selects operating system {actual}, "
            f"not {operating_system}"
        )

    define_start, define_end, definitions = layer_definitions(text)
    blocks = layer_blocks(text)
    block_names = [name for name, _, _ in blocks]
    expected_definitions = [(name, number) for number, name in enumerate(block_names)]
    if definitions != expected_definitions:
        raise ValueError("generated layer names, numbers, and blocks do not match")
    if primary_layer not in block_names:
        raise ValueError(f"requested primary layer does not exist: {primary_layer}")

    target_index = block_names.index(primary_layer)
    if target_index != 0:
        _, first_start, first_end = blocks[0]
        _, target_start, target_end = blocks[target_index]
        first_block = text[first_start:first_end]
        target_block = text[target_start:target_end]
        text = (
            text[:first_start]
            + target_block
            + text[first_end:target_start]
            + first_block
            + text[target_end:]
        )

    reordered_names = block_names.copy()
    reordered_names[0], reordered_names[target_index] = (
        reordered_names[target_index],
        reordered_names[0],
    )
    regenerated = "\n".join(
        f"#define LAYER_{name} {number}" for number, name in enumerate(reordered_names)
    )
    text = text[:define_start] + regenerated + text[define_end:]
    text = add_kvm_macros(text)
    text = add_kvm_bindings(text, primary_layer)
    text = add_kvm_colors(text)

    final_definitions = layer_definitions(text)[2]
    final_blocks = layer_blocks(text)
    expected = [(name, number) for number, name in enumerate(reordered_names)]
    if final_definitions != expected or [name for name, _, _ in final_blocks] != reordered_names:
        raise ValueError("layer transformation failed validation")
    return text


def render_summary(text: str) -> str:
    # this is the physical order emitted by the glove80 layout editor.
    positions = [
        [
            "lh c6r1",
            "lh c5r1",
            "lh c4r1",
            "lh c3r1",
            "lh c2r1",
            "rh c2r1",
            "rh c3r1",
            "rh c4r1",
            "rh c5r1",
            "rh c6r1",
        ],
        [
            *[f"lh c{column}r2" for column in range(6, 0, -1)],
            *[f"rh c{column}r2" for column in range(1, 7)],
        ],
        [
            *[f"lh c{column}r3" for column in range(6, 0, -1)],
            *[f"rh c{column}r3" for column in range(1, 7)],
        ],
        [
            *[f"lh c{column}r4" for column in range(6, 0, -1)],
            *[f"rh c{column}r4" for column in range(1, 7)],
        ],
        [
            *[f"lh c{column}r5" for column in range(6, 0, -1)],
            "lh t1",
            "lh t2",
            "lh t3",
            "rh t3",
            "rh t2",
            "rh t1",
            *[f"rh c{column}r5" for column in range(1, 7)],
        ],
        [
            *[f"lh c{column}r6" for column in range(6, 1, -1)],
            "lh t4",
            "lh t5",
            "lh t6",
            "rh t6",
            "rh t5",
            "rh t4",
            *[f"rh c{column}r6" for column in range(2, 7)],
        ],
    ]
    definitions = layer_definitions(text)[2]
    blocks = layer_blocks(text)
    if [name for name, _ in definitions] != [name for name, _, _ in blocks]:
        raise ValueError("cannot summarize mismatched layer definitions and blocks")

    lines = [
        "# glove80 key mappings",
        "",
        "this file is generated from the locked keymap after local customization.",
        "do not edit it by hand. it provides a quick, searchable view",
        "of every physical key binding. empty and transparent bindings are omitted.",
        "",
        "zmk behaviors are kept as written to distinguish taps, holds,",
        "layer access, mouse actions, rgb controls, and custom behaviors.",
        "",
    ]

    for (name, number), (_, start, end) in zip(definitions, blocks, strict=True):
        block = text[start:end]
        bindings = re.search(
            r"^\s+bindings = <\n(?P<rows>.*?)^\s+>;",
            block,
            re.MULTILINE | re.DOTALL,
        )
        if bindings is None:
            raise ValueError(f"layer has no bindings block: {name}")
        rows = [row.strip() for row in bindings.group("rows").splitlines() if row.strip()]
        if len(rows) != 6:
            raise ValueError(f"layer does not have six physical rows: {name}")

        mapped_bindings = []
        for row_positions, row in zip(positions, rows, strict=True):
            row_bindings = re.split(r"\s{2,}", row)
            if len(row_bindings) != len(row_positions):
                raise ValueError(
                    f"expected {len(row_positions)} bindings, found {len(row_bindings)} "
                    f"in layer {name}"
                )
            mapped_bindings.extend(zip(row_positions, row_bindings, strict=True))

        lines.extend([f"## layer {number}: {name}", "", "| position | binding |", "| --- | --- |"])
        visible_bindings = [
            (position, binding)
            for position, binding in mapped_bindings
            if binding not in {"&none", "&trans"}
        ]
        if visible_bindings:
            for position, binding in visible_bindings:
                escaped_binding = binding.replace("|", "\\|")
                lines.append(f"| `{position}` | `{escaped_binding}` |")
        else:
            lines.append("| - | no explicit bindings |")
        lines.append("")

    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--summary", action="store_true")
    parser.add_argument("preferences", type=Path)
    parser.add_argument("keymap", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    preferences = json.loads(args.preferences.read_text())
    if set(preferences) != {"primaryLayer", "operatingSystem"}:
        raise ValueError("preferences must contain only primaryLayer and operatingSystem")
    result = customize(
        args.keymap.read_text(),
        preferences["primaryLayer"],
        preferences["operatingSystem"],
    )
    args.output.write_text(render_summary(result) if args.summary else result)


if __name__ == "__main__":
    main()
