@tool
class_name WikiInspectorTheme
extends RefCounted
## Shared wiki-style theme for all custom inspector plugins.
##
## Neural network aesthetic with consistent colors and styling
## across all OhMyDialog inspector panels.

# === BACKGROUNDS ===
const BG_PRIMARY := Color("#0a0d12")
const BG_SECONDARY := Color("#0f1419")
const BG_TERTIARY := Color("#161d26")
const BG_CARD := Color("#121921")

# === TEXT ===
const TEXT_PRIMARY := Color("#e6edf3")
const TEXT_SECONDARY := Color("#8b949e")
const TEXT_MUTED := Color("#484f58")

# === AI ACCENT COLORS ===
const AI_CYAN := Color("#00d4ff")
const AI_CYAN_DIM := Color("#0099cc")
const AI_PURPLE := Color("#a855f7")
const AI_PURPLE_DIM := Color("#7c3aed")
const AI_GREEN := Color("#10b981")
const AI_GREEN_DIM := Color("#059669")
const AI_PINK := Color("#ec4899")
const AI_ORANGE := Color("#f97316")
const AI_YELLOW := Color("#eab308")
const AI_RED := Color("#ef4444")

# === BORDERS ===
const BORDER := Color("#21262d")
const BORDER_GLOW := Color("#00d4ff33")

# === SECTION ICONS ===
const ICON_DIAMOND := "◆"
const ICON_DIAMOND_EMPTY := "◇"
const ICON_DIAMOND_DOT := "◈"
const ICON_CIRCLE_DOT := "◉"
const ICON_CIRCLE_TARGET := "◎"
const ICON_CIRCLE_HALF_LEFT := "◐"
const ICON_CIRCLE_HALF_RIGHT := "◑"
const ICON_CIRCLE_HALF_BOTTOM := "◒"
const ICON_STAR := "★"
const ICON_GEAR := "⚙"
const ICON_BOLT := "⚡"
const ICON_BRAIN := "🧠"


## Creates a header style with the specified accent color.
static func create_header_style(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_CARD
	style.border_color = accent_color
	style.set_border_width_all(1)
	style.border_width_left = 3
	style.border_width_top = 2
	style.set_corner_radius_all(4)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.set_content_margin_all(12)
	return style


## Creates a section header style with optional hover state.
static func create_section_header_style(is_hovered: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base_color := BG_TERTIARY
	style.bg_color = base_color if not is_hovered else base_color.lightened(0.08)
	style.border_color = BORDER
	style.set_border_width_all(0)
	style.border_width_bottom = 1
	style.set_corner_radius_all(0)
	style.set_content_margin_all(0)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


## Creates a content panel style for section contents.
static func create_content_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_SECONDARY
	style.set_content_margin_all(0)
	style.content_margin_left = 20
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


## Creates a preview panel style with accent border.
static func create_preview_style(accent_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_PRIMARY
	style.set_border_width_all(1)
	style.border_color = accent_color
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	return style


## Creates the main header with title and token display.
static func create_main_header(title: String, accent_color: Color) -> Dictionary:
	var header_panel := PanelContainer.new()
	header_panel.add_theme_stylebox_override("panel", create_header_style(accent_color))

	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 6)

	# Title with icon
	var title_hbox := HBoxContainer.new()
	title_hbox.add_theme_constant_override("separation", 10)

	var icon_label := Label.new()
	icon_label.text = ICON_DIAMOND
	icon_label.add_theme_font_size_override("font_size", 16)
	icon_label.add_theme_color_override("font_color", accent_color)
	title_hbox.add_child(icon_label)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 13)
	title_label.add_theme_color_override("font_color", accent_color)
	# Bold via LabelSettings
	var settings := LabelSettings.new()
	settings.font_size = 13
	settings.font_color = accent_color
	settings.outline_size = 0
	title_label.label_settings = settings
	title_hbox.add_child(title_label)

	header_vbox.add_child(title_hbox)

	# Token label placeholder
	var token_label := RichTextLabel.new()
	token_label.bbcode_enabled = true
	token_label.fit_content = true
	token_label.scroll_active = false
	header_vbox.add_child(token_label)

	header_panel.add_child(header_vbox)

	return {
		"panel": header_panel,
		"token_label": token_label,
		"title_label": title_label,
		"icon_label": icon_label
	}


## Formats token usage display with color-coded status.
static func format_token_display(tokens: int, model_ctx: int, model_name: String) -> String:
	var usage_percent := (tokens * 100.0) / model_ctx
	var text := "[b]~%d tokens[/b] " % tokens

	if tokens > model_ctx * 0.5:
		text += "[color=#ef4444](%.0f%% - WARNING)[/color]" % usage_percent
	elif tokens > model_ctx * 0.3:
		text += "[color=#f97316](%.0f%% - caution)[/color]" % usage_percent
	else:
		text += "[color=#10b981](%.0f%% OK)[/color]" % usage_percent

	text += "\n[color=#484f58]Model: %s (%d ctx)[/color]" % [model_name, model_ctx]

	return text
