---
name: godot_dev
description: Godot 4.5+ C#/C++/GDExtension rules.
---
# Godot 4.5+
- **Ver**: 4.5+. Use `Callable`, `SceneTreeTween`, `GDExtension`.
- **Files**: `snake_case.tscn/cs`; Nodes: `PascalCase`.
- **Composition**: Small, focused Nodes > Inheritance.

## C# (.NET 8)
- **Signals**: Use C# events for C#->C#. `[Signal]` only for interop.
  `[Signal] delegate void OnHitEventHandler();` -> `EmitSignal(SignalName.OnHit);`
- **Safety**: `IsInstanceValid(node)` before access. `[Export]` > `GetNode<T>()`.

## GDExtension (C++)
- **Mem**: `Ref<T>` for Resources. Scenes manage Node memory.
- **Bind**:
```cpp
void Node::_bind_methods() { ClassDB::bind_method(D_METHOD("m"), &Node::m); }
```
- **Perf**: `Packed*Array`, `Server` APIs, Object Pooling.
