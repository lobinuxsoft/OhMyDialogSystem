# OhMyDialogSystem

<div align="center">

![Godot 4.5+](https://img.shields.io/badge/Godot-4.5%2B-blue?logo=godot-engine)
![License Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue)
![Version](https://img.shields.io/badge/Version-0.3.0--dev-orange)
![Core](https://img.shields.io/badge/Core-88%25-green)
![Editor](https://img.shields.io/badge/Editor-35%25-yellow)

**AI-powered dialogue system for Godot with local LLM inference, visual editor, and character personalities.**

[Documentation](https://lobinuxsoft.github.io/OhMyDialogSystem/) | [Issues](https://github.com/lobinuxsoft/OhMyDialogSystem/issues) | [Project Board](https://github.com/users/lobinuxsoft/projects/5)

</div>

---

## Why OhMyDialogSystem?

| | |
|---|---|
| **Made for Games** | Not a chatbot wrapper. Designed for immersive NPC dialogues with personality and context. |
| **100% Offline** | No API keys, no cloud costs, no internet required. Your game, your data. |
| **Native Performance** | C++ GDExtension via llama.cpp. Not GDScript string hacks. |
| **Godot-Native** | Resources, signals, inspector plugins. Feels like part of the engine. |
| **Batteries Included** | Download models from Hugging Face with 1 click. Windows & Linux binaries included. |

---

## What's Working Now

- **Local LLM Inference** - Run language models directly in Godot via llama.cpp
  - Async/streaming text generation
  - Chat templates with Jinja2 support
  - Stop sequences & configurable timeouts
  - Sampling parameters (temperature, top-p, top-k, penalties)
  - Windows x64 & Linux x64 binaries included

- **Visual Dialogue Editor** - Node-based graph editor
  - 13 node types: Start, End, AI Response, Static Response, Player Choice, Condition, Event, Jump, SetVariable, and more
  - Hugging Face model browser with 1-click download
  - Custom inspector panels for each node type
  - GGUF metadata parser for auto-configuration

- **Character System** - Define unique NPC personalities
  - `CharacterIdentity` resources with personality traits
  - `WorldContext` for immersive world settings
  - `AIPreset` for model configurations and sampling params

- **Three Dialogue Modes**
  - `FREE`: Pure AI-driven conversations
  - `SCRIPTED`: Traditional branching dialogues
  - `HYBRID`: Mix scripted structure with AI responses

---

## Coming Soon

- [ ] **Persistent Memories** - NPCs remember past conversations with semantic search
- [ ] **Text-to-Speech** - Offline voice synthesis with Piper TTS
- [ ] **Localization** - Multi-language prompt templates with TranslationServer
- [ ] **C# Bindings** - Idiomatic async/await API for C# developers
- [ ] **LoRA Adapters** - Fine-tuned personality models

---

## Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| Godot Engine | 4.5+ | Required for GDExtension 4.3+ |
| LLM Model | GGUF Q4/Q5/Q8 | Recommended: Qwen2.5-0.5B or similar |
| RAM | 8GB+ | 16GB recommended for larger models |
| GPU (optional) | CUDA/Vulkan | For accelerated inference (coming soon) |

---

## Installation

> **Note:** The addon is currently in active development (v0.3.0-dev).
> Check the [Releases](https://github.com/lobinuxsoft/OhMyDialogSystem/releases) page for the latest version.

1. Download the latest release or clone the repository
2. Copy the `addons/ohmydialog/` folder to your project's `addons/` directory
3. Enable the plugin in Project Settings > Plugins
4. Download a GGUF model using the built-in Model Manager (AI menu in editor)

---

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

---

## Documentation

**Full documentation at: [lobinuxsoft.github.io/OhMyDialogSystem](https://lobinuxsoft.github.io/OhMyDialogSystem/)**

| Section | Description |
|---------|-------------|
| [Getting Started](https://lobinuxsoft.github.io/OhMyDialogSystem/Guides/) | Installation, quick start, first dialogue |
| [API Reference](https://lobinuxsoft.github.io/OhMyDialogSystem/API/) | DialogueManager, AIService, Resources |
| [Visual Editor](https://lobinuxsoft.github.io/OhMyDialogSystem/Technical/dialogue-nodes.html) | Node types, graph editing |
| [Architecture](https://lobinuxsoft.github.io/OhMyDialogSystem/Technical/architecture.html) | System design, data flow |

---

## Project Structure

```
addons/ohmydialog/
├── plugin.cfg              # Addon metadata
├── plugin.gd               # Main EditorPlugin
├── gdextension/            # C++ native code (llama.cpp bindings)
├── ai/                     # Model management, GGUF parser, HuggingFace API
├── autoload/               # AIService singleton
├── core/                   # DialogueManager, GraphRunner, NodeExecutors
├── resources/              # Custom Resources (DialogueGraph, CharacterIdentity...)
├── editor/                 # Visual dialogue editor, inspector plugins
├── icons/                  # Editor icons
├── memory/                 # Persistent memory system (coming soon)
├── tts/                    # Text-to-Speech (coming soon)
└── localization/           # Multi-language support (coming soon)
```

---

## Roadmap

| Milestone | Description | Status |
|-----------|-------------|--------|
| M1 | GDExtension Core | 60% (12/20) |
| M2 | Core System | 88% (14/16) |
| M3 | Visual Editor | 35% (7/20) |
| M4 | Persistent Memories | Planned |
| M5 | Localization | Planned |
| M6 | Text-to-Speech | Planned |
| M7 | C# Bindings | Planned |
| M8 | Examples & Docs | 41% (7/17) |
| M9 | LoRA & AI Assistants | Planned |

See the [Project Board](https://github.com/users/lobinuxsoft/projects/5) for detailed progress.

---

## Support the Project

If you find this project useful, consider supporting its development:

| Network | Address |
|---------|---------|
| **USDT (TRC20)** | `TF6AXBP3LKBCcbJkLG6RqyMsrPNs2JCpdQ` |
| **USDT (BEP20)** | `0xd8d2Ed67C567CB3Af437f4638d3531e560575A20` |
| **BTC** | `bc1qkxy898wa6mz04c9hrjekx6p0yht2ukz56e9xxq` |
| **Binance Pay ID** | `78328894` |

---

## Contributing

Contributions are welcome! Please check the [Issues](https://github.com/lobinuxsoft/OhMyDialogSystem/issues) for open tasks.

---

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with locally-inferred passion by [lobinuxsoft](https://github.com/lobinuxsoft)

</div>
