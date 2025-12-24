# OhMyDialogSystem

<div align="center">

![Godot 4.5+](https://img.shields.io/badge/Godot-4.5%2B-blue?logo=godot-engine)
![License MIT](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-In%20Development-orange)

**AI-powered dialogue system for Godot with local LLM inference, persistent memories, and text-to-speech.**

[Documentation](https://lobinuxsoft.github.io/OhMyDialogSystem/) · [Issues](https://github.com/lobinuxsoft/OhMyDialogSystem/issues) · [Project Board](https://github.com/users/lobinuxsoft/projects/5)

</div>

---

## Features

- **Local LLM Inference** - Run language models directly in Godot via llama.cpp (GDExtension)
- **Visual Dialogue Editor** - Create branching dialogues with a node-based editor
- **Character Identities** - Define unique personalities, backgrounds, and speech styles
- **Persistent Memories** - NPCs remember past conversations with semantic search
- **Text-to-Speech** - Offline voice synthesis with Piper TTS
- **Localization** - Multi-language support integrated with Godot's TranslationServer
- **C# Bindings** - Idiomatic C# API with async/await support

## Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| Godot Engine | 4.5+ | Required for GDExtension 4.3+ |
| LLM Model | GGUF Q4/Q5/Q8 | Recommended: Mistral 7B or similar |
| RAM | 8GB+ | 16GB recommended for larger models |
| GPU (optional) | CUDA/Vulkan | For accelerated inference |

## Installation

> **Note:** The addon is currently in development. Installation instructions will be available once the first release is published.

```
Coming soon...
```

## Quick Start

```gdscript
# Load the model
var llama = LlamaInterface.new()
llama.load_model("user://models/mistral-7b-q4.gguf")

# Configure DialogueManager
var dm = DialogueManager.new()
dm.set_llama_interface(llama)
dm.set_character(preload("res://npcs/merchant.tres"))

# Start conversation
dm.npc_response_completed.connect(_on_npc_response)
dm.send_player_message("Hello, what do you have for sale?")
```

## Documentation

Full documentation is available at: **[lobinuxsoft.github.io/OhMyDialogSystem](https://lobinuxsoft.github.io/OhMyDialogSystem/)**

- [Quick Start Guide](https://lobinuxsoft.github.io/OhMyDialogSystem/Guides/)
- [API Reference](https://lobinuxsoft.github.io/OhMyDialogSystem/API/)
- [Technical Documentation](https://lobinuxsoft.github.io/OhMyDialogSystem/Technical/)

## Project Structure

```
addons/ohmydialog/
├── plugin.cfg          # Addon metadata
├── plugin.gd           # Main EditorPlugin
├── gdextension/        # C++ native code (llama.cpp, Piper)
├── core/               # GDScript managers
├── resources/          # Custom Resources
├── editor/             # Visual dialogue editor
├── memory/             # Persistent memory system
├── tts/                # Text-to-Speech
├── localization/       # Multi-language support
└── examples/           # Usage examples
```

## Roadmap

| Milestone | Description | Status |
|-----------|-------------|--------|
| M1 | GDExtension Core | 🔄 In Progress |
| M2 | Core System | ⏳ Pending |
| M3 | Visual Editor | ⏳ Pending |
| M4 | Persistent Memories | ⏳ Pending |
| M5 | Localization | ⏳ Pending |
| M6 | Text-to-Speech | ⏳ Pending |
| M7 | C# Bindings | ⏳ Pending |
| M8 | Examples & Docs | ⏳ Pending |

See the [Project Board](https://github.com/users/lobinuxsoft/projects/5) for detailed progress.

## Contributing

Contributions are welcome! Please check the [Issues](https://github.com/lobinuxsoft/OhMyDialogSystem/issues) for open tasks.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with 🧠 by [lobinuxsoft](https://github.com/lobinuxsoft)

</div>
