# Project Context

## Structure
```
addons/ohmydialog/
├── gdextension/          # Native C++ (llama.cpp, piper)
│   ├── godot-cpp/        # Submodule
│   ├── thirdparty/       # llama.cpp, piper submodules
│   └── src/              # Our C++ code
├── core/                 # Main managers
├── resources/            # Custom Resources
├── editor/               # Visual editor
├── memory/               # Memory system
├── tts/                  # Text-to-Speech
├── localization/         # i18n
└── examples/             # Usage examples
```

## Milestones
| # | Name | Focus |
|---|------|-------|
| M1 | GDExtension Core | llama.cpp integration |
| M2 | Core System | DialogueManager, prompts |
| M3 | Visual Editor | GraphEdit dialogue editor |
| M4 | Persistent Memories | NPC memory system |
| M5 | Localization | TranslationServer integration |
| M6 | Text-to-Speech | Piper TTS integration |
| M7 | C# Bindings | Idiomatic C# wrappers |
| M8 | Examples & Docs | Tutorials, documentation |

## Key Technologies
- **GDExtension + godot-cpp:** Native C++ bindings
- **llama.cpp:** Local LLM inference (GGUF models)
- **Piper TTS:** Offline voice synthesis
- **GraphEdit/GraphNode:** Visual dialogue editor

## Links
- Issues: https://github.com/lobinuxsoft/OhMyDialogSystem/issues
- Milestones: https://github.com/lobinuxsoft/OhMyDialogSystem/milestones
