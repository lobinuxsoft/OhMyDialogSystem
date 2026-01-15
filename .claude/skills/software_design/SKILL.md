---
name: software_design
description: SOLID/Patterns for Godot.
---
# Architecture
- **Comp > Inherit**: `Entity` + `Mover` + `Health` components. No deep trees.

## SOLID
- **SRP**: Input/Logic/View split. `PlayerInput` -> `PlayerController` -> `PlayerAnim`.
- **OCP/DIP**: Depend on Interfaces/Base classes. Use `strategy` usage for weapons/items.

## Patterns
- **Observer**: Signals/Events. `Model` --signal--> `View`. `View` never calls `Model`.
- **Command**: Encapsulate Input/Actions for Rebinding/Undo.
- **State**: Node-based FSM. `State` node with `Enter/Exit/Process`.
