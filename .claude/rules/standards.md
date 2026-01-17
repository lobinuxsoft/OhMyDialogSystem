# Standards

## Naming
| Lang | Class | Func/Var | Priv |
|------|-------|----------|------|
| C++  | Pascal| snake    | m_   |
| GD   | Pascal| snake    | _    |
| C#   | Pascal| camel    | _camel|

## Critical
- `core/`, `ai/` MUST NOT init `editor/` classes. Use `OS.has_feature("editor")`.
- For Godot/C++ details: `/godot_dev`. For architecture: `/software_design`.
