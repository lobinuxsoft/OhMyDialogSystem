# GGUF Models Directory

Place your .gguf model files here. Models in this directory:
- Work in the Godot editor
- Are included in exported builds

## Downloading Models

Use the test scene to download models automatically:
1. Open `addons/ohmydialog/examples/llama_test_scene.tscn`
2. Select a model from the dropdown
3. Click "Download"

## Recommended Models

| Model | Size | Use Case |
|-------|------|----------|
| SmolLM-135M | ~145MB | Testing, prototyping |
| Qwen2.5-0.5B-Instruct | ~530MB | Production (recommended) |
| TinyLlama-1.1B-Chat | ~670MB | Higher quality |

## Note

The `.gguf` files are git-ignored to avoid bloating the repository.
Each developer needs to download models locally.
