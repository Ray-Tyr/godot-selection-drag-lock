# Godot Selection Drag Lock

A small Godot 4 editor plugin for 2D scenes. It lets you drag the currently selected `Node2D` nodes in the 2D viewport without accidentally selecting a different node under the mouse.

## What Problem It Solves

When a 2D scene contains many overlapping nodes, it is easy to select one node in the scene tree and then accidentally drag another node in the viewport. This usually happens because the viewport click begins on a different selectable item.

Selection Drag Lock adds a `Lock Drag` toggle to the 2D editor toolbar. When the toggle is enabled, left-dragging in the 2D viewport moves the nodes that are already selected instead of letting the viewport change the selection at drag start.

## Features

- Adds a `Lock Drag` toggle to the 2D editor toolbar.
- Enabled by default when the editor plugin loads.
- Moves the current top-level selected `Node2D` nodes.
- Supports dragging multiple selected `Node2D` nodes together.
- Intercepts left-drag events while enabled so viewport clicks do not reselect another node.
- Creates one Godot undo/redo action per drag.
- Registers an editable editor shortcut.

## Compatibility

- Designed for Godot 4 editor projects.
- Tested in a Godot 4.6 project.
- Intended for 2D scene editing only.
- Only moves `Node2D` nodes. It intentionally does not move `Control` UI nodes or 3D nodes.

## Installation

1. Download or clone this repository.
2. Copy `addons/selection_drag_lock` into your Godot project.
3. Open your project in Godot.
4. Go to `Project > Project Settings > Plugins`.
5. Enable `Selection Drag Lock`.

Your project should then contain:

```text
addons/
  selection_drag_lock/
    plugin.cfg
    plugin.gd
    plugin.gd.uid
```

## Usage

1. Open a 2D scene.
2. Select one or more `Node2D` nodes in the scene tree or viewport.
3. Make sure `Lock Drag` is enabled in the 2D editor toolbar.
4. Drag in the 2D viewport.

While `Lock Drag` is enabled, the selected nodes move even if the mouse starts over another selectable node. Disable the toggle when you want normal viewport selection behavior again.

## Undo And Redo

The plugin records one undo action when a drag finishes. This means a whole drag gesture can be undone with Godot's normal undo command instead of producing many tiny undo steps.

## Default Shortcut

`Alt + Shift + D`

You can change it in:

```text
Editor > Editor Settings > Shortcuts > Selection Drag Lock > Toggle Lock Drag
```

## Behavior Details

- The plugin uses Godot's current editor selection.
- It moves `global_position` for each selected `Node2D`.
- If both a parent and child are selected, Godot's top-level selected node list is used to avoid moving the child twice through inherited parent movement.
- If no `Node2D` node is selected, the plugin lets Godot handle the viewport input normally.
- Turning the toggle off restores normal 2D viewport selection and drag behavior.

## Limitations

- It does not support `Control` nodes. UI anchors, containers, and layout rules can make direct viewport dragging ambiguous.
- It does not support `Node3D` nodes.
- It does not replace Godot's transform tools. It only changes how left-dragging behaves while the lock is enabled.
- It does not persist a per-project setting for the toggle state. The plugin starts enabled when loaded.

## Suggested Workflow

Use this plugin when arranging dense 2D gameplay scenes, tile-adjacent objects, triggers, collision helpers, interactables, VFX markers, or any scene where selecting the correct node is easier in the scene tree than in the viewport.

Keep `Lock Drag` enabled while positioning already-selected nodes. Turn it off when you are actively selecting nodes from the viewport.

## Repository Layout

```text
.
├── addons/
│   └── selection_drag_lock/
│       ├── plugin.cfg
│       ├── plugin.gd
│       └── plugin.gd.uid
├── .gitignore
├── LICENSE
└── README.md
```

## License

MIT
