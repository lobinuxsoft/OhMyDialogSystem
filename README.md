# OhMyDialogSystem

<div align="center">

![Godot 4.5+](https://img.shields.io/badge/Godot-4.5%2B-blue?logo=godot-engine)
![License Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue)
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
# Get reference to DialogueManager node
@onready var dialogue_manager: DialogueManager = $DialogueManager

func _ready() -> void:
    # Connect to dialogue signals
    dialogue_manager.npc_response_completed.connect(_on_npc_response)
    dialogue_manager.player_choices_available.connect(_on_choices)
    dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)

func start_conversation() -> void:
    # Load and start a dialogue graph (model loads automatically from StartNode)
    var graph: DialogueGraph = preload("res://dialogues/merchant.tres")
    dialogue_manager.start_dialogue(graph)

func _on_npc_response(text: String) -> void:
    dialogue_ui.show_npc_text(text)

func _on_choices(choices: Array[Dictionary]) -> void:
    dialogue_ui.show_choices(choices)
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
| M1 | GDExtension Core | 🔄 In Progress (11/18) |
| M2 | Core System | ✅ Complete |
| M3 | Visual Editor | 🔄 In Progress (5/17) |
| M4 | Persistent Memories | ⏳ Pending |
| M5 | Localization | ⏳ Pending |
| M6 | Text-to-Speech | ⏳ Pending |
| M7 | C# Bindings | ⏳ Pending |
| M8 | Examples & Docs | 🔄 In Progress (6/16) |
| M9 | LoRA & AI Assistants | ⏳ Pending |

See the [Project Board](https://github.com/users/lobinuxsoft/projects/5) for detailed progress.

## Support the Project

If you find this project useful, consider supporting its development:

| Network | Address |
|---------|---------|
| **USDT (TRC20)** | `TF6AXBP3LKBCcbJkLG6RqyMsrPNs2JCpdQ` |
| **USDT (BEP20)** | `0xd8d2Ed67C567CB3Af437f4638d3531e560575A20` |
| **BTC** | `bc1qkxy898wa6mz04c9hrjekx6p0yht2ukz56e9xxq` |
| **Binance Pay ID** | `78328894` |

## Contributing

Contributions are welcome! Please check the [Issues](https://github.com/lobinuxsoft/OhMyDialogSystem/issues) for open tasks.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with 🧠 by [lobinuxsoft](https://github.com/lobinuxsoft)

</div>
