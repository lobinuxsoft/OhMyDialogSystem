class_name HuggingFaceAPI
extends RefCounted
## Client for searching and fetching GGUF models from HuggingFace Hub.
##
## Allows browsing available models, filtering by size, and getting download URLs.

signal search_completed(results: Array[Dictionary])
signal search_failed(error: String)
signal model_details_completed(model_id: String, files: Array[Dictionary])
signal model_details_failed(model_id: String, error: String)

const API_BASE = "https://huggingface.co/api"
const DOWNLOAD_BASE = "https://huggingface.co"

## Maximum file size in bytes (4GB default)
var max_file_size_bytes: int = 4 * 1024 * 1024 * 1024

## Preferred quantizations (in order of preference)
var preferred_quantizations: Array[String] = ["Q8_0", "Q4_K_M", "Q4_0", "Q5_K_M", "Q6_K"]

var _http_search: HTTPRequest
var _http_details: HTTPRequest
var _pending_model_id: String = ""


## Search for GGUF models on HuggingFace
## Returns results via search_completed signal
func search_models(query: String = "gguf", limit: int = 50, sort: String = "downloads") -> void:
	if _http_search != null and _http_search.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		push_warning("HuggingFaceAPI: Search already in progress")
		return

	# Build search URL
	var search_term = query if not query.is_empty() else "gguf"
	if not "gguf" in search_term.to_lower():
		search_term += " gguf"

	var url = "%s/models?search=%s&filter=text-generation&sort=%s&direction=-1&limit=%d" % [
		API_BASE,
		search_term.uri_encode(),
		sort,
		limit
	]

	_do_request(_get_or_create_search_http(), url, "_on_search_completed")


## Get detailed info about a model including file sizes
## Returns results via model_details_completed signal
func get_model_files(model_id: String) -> void:
	if _http_details != null and _http_details.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		push_warning("HuggingFaceAPI: Details request already in progress")
		return

	_pending_model_id = model_id
	var url = "%s/models/%s/tree/main" % [API_BASE, model_id]
	_do_request(_get_or_create_details_http(), url, "_on_details_completed")


## Parse search results and filter for valid GGUF repos
func parse_search_results(json_array: Array) -> Array[Dictionary]:
	var results: Array[Dictionary] = []

	for item in json_array:
		if item is Dictionary:
			var model_id = item.get("id", "") as String
			if model_id.is_empty():
				continue

			# Check if it's likely a GGUF repo
			var tags = item.get("tags", []) as Array
			var is_gguf = "gguf" in tags or "GGUF" in model_id.to_upper()

			if not is_gguf:
				continue

			results.append({
				"id": model_id,
				"author": model_id.split("/")[0] if "/" in model_id else "",
				"name": model_id.split("/")[1] if "/" in model_id else model_id,
				"downloads": item.get("downloads", 0),
				"likes": item.get("likes", 0),
				"tags": tags,
				"pipeline_tag": item.get("pipeline_tag", ""),
				"created_at": item.get("createdAt", "")
			})

	return results


## Parse file tree and extract GGUF files with sizes
func parse_model_files(json_array: Array) -> Array[Dictionary]:
	var files: Array[Dictionary] = []

	for item in json_array:
		if item is Dictionary:
			var path = item.get("path", "") as String
			if not path.ends_with(".gguf"):
				continue

			# Get size - prefer LFS size (actual file size) over pointer size
			var size: int = 0
			var lfs = item.get("lfs")
			if lfs is Dictionary and lfs.has("size"):
				# LFS files: use actual file size from lfs.size
				size = int(lfs.get("size", 0))
			else:
				# Non-LFS files: use direct size
				size = int(item.get("size", 0))

			# Skip files that are too large
			if size > max_file_size_bytes:
				continue

			var quant = _extract_quantization(path)

			files.append({
				"filename": path,
				"size_bytes": size,
				"size_mb": size / (1024.0 * 1024.0),
				"quantization": quant,
				"is_preferred": quant in preferred_quantizations
			})

	# Sort by preference (preferred quants first, then by size)
	files.sort_custom(func(a, b):
		var a_pref = preferred_quantizations.find(a["quantization"])
		var b_pref = preferred_quantizations.find(b["quantization"])
		if a_pref == -1: a_pref = 999
		if b_pref == -1: b_pref = 999
		if a_pref != b_pref:
			return a_pref < b_pref
		return a["size_bytes"] < b["size_bytes"]
	)

	return files


## Build download URL for a specific file
func get_download_url(model_id: String, filename: String) -> String:
	return "%s/%s/resolve/main/%s" % [DOWNLOAD_BASE, model_id, filename]


## Create a ModelConfig from HuggingFace model info
func create_model_config(model_id: String, file_info: Dictionary) -> ModelConfig:
	var config = ModelConfig.new()

	var name_parts = model_id.split("/")
	var model_name = name_parts[1] if name_parts.size() > 1 else model_id

	config.id = "%s-%s" % [model_name.to_lower().replace(" ", "-"), file_info.get("quantization", "q4").to_lower()]
	config.display_name = "%s (%s)" % [model_name.replace("-GGUF", "").replace("-gguf", ""), file_info.get("quantization", "")]
	config.description = "Downloaded from HuggingFace: %s" % model_id
	config.size_mb = file_info.get("size_mb", 0.0)
	config.download_url = get_download_url(model_id, file_info.get("filename", ""))
	config.is_custom = true

	# Set reasonable defaults based on size
	var size_mb = config.size_mb
	if size_mb < 500:
		config.n_ctx = 2048
		config.default_max_tokens = 128
	elif size_mb < 1500:
		config.n_ctx = 4096
		config.default_max_tokens = 256
	else:
		config.n_ctx = 8192
		config.default_max_tokens = 256

	return config


## Extract quantization type from filename
func _extract_quantization(filename: String) -> String:
	var upper = filename.to_upper()

	# Common quantization patterns
	var patterns = [
		"Q8_0", "Q6_K", "Q5_K_M", "Q5_K_S", "Q5_0",
		"Q4_K_M", "Q4_K_S", "Q4_K_L", "Q4_0", "Q4_1",
		"Q3_K_M", "Q3_K_S", "Q3_K_L", "Q2_K", "Q2_K_L",
		"IQ4_NL", "IQ4_XS", "IQ3_XXS", "IQ2_XXS", "IQ1_S", "IQ1_M",
		"F16", "F32", "BF16"
	]

	for pattern in patterns:
		if pattern in upper:
			return pattern

	return "UNKNOWN"


func _get_or_create_search_http() -> HTTPRequest:
	if _http_search == null:
		_http_search = HTTPRequest.new()
		_http_search.use_threads = true
		Engine.get_main_loop().root.add_child(_http_search)
	return _http_search


func _get_or_create_details_http() -> HTTPRequest:
	if _http_details == null:
		_http_details = HTTPRequest.new()
		_http_details.use_threads = true
		Engine.get_main_loop().root.add_child(_http_details)
	return _http_details


func _do_request(http: HTTPRequest, url: String, callback: String) -> void:
	# Disconnect previous signals
	if http.request_completed.is_connected(Callable(self, "_on_search_completed")):
		http.request_completed.disconnect(Callable(self, "_on_search_completed"))
	if http.request_completed.is_connected(Callable(self, "_on_details_completed")):
		http.request_completed.disconnect(Callable(self, "_on_details_completed"))

	http.request_completed.connect(Callable(self, callback), CONNECT_ONE_SHOT)

	var headers = ["User-Agent: OhMyDialogSystem/1.0", "Accept: application/json"]
	var err = http.request(url, headers)

	if err != OK:
		if callback == "_on_search_completed":
			search_failed.emit("Failed to start request: %s" % error_string(err))
		else:
			model_details_failed.emit(_pending_model_id, "Failed to start request: %s" % error_string(err))


func _on_search_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		search_failed.emit("Request failed: %s" % _get_result_error(result))
		return

	if response_code != 200:
		search_failed.emit("HTTP error: %d" % response_code)
		return

	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())

	if parse_result != OK:
		search_failed.emit("Failed to parse JSON response")
		return

	var data = json.get_data()
	if data is Array:
		var results = parse_search_results(data)
		search_completed.emit(results)
	else:
		search_failed.emit("Unexpected response format")


func _on_details_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var model_id = _pending_model_id
	_pending_model_id = ""

	if result != HTTPRequest.RESULT_SUCCESS:
		model_details_failed.emit(model_id, "Request failed: %s" % _get_result_error(result))
		return

	if response_code != 200:
		model_details_failed.emit(model_id, "HTTP error: %d" % response_code)
		return

	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())

	if parse_result != OK:
		model_details_failed.emit(model_id, "Failed to parse JSON response")
		return

	var data = json.get_data()
	if data is Array:
		var files = parse_model_files(data)
		model_details_completed.emit(model_id, files)
	else:
		model_details_failed.emit(model_id, "Unexpected response format")


func _get_result_error(result: int) -> String:
	match result:
		HTTPRequest.RESULT_CANT_CONNECT: return "Cannot connect"
		HTTPRequest.RESULT_CANT_RESOLVE: return "Cannot resolve hostname"
		HTTPRequest.RESULT_CONNECTION_ERROR: return "Connection error"
		HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR: return "TLS handshake failed"
		HTTPRequest.RESULT_NO_RESPONSE: return "No response"
		HTTPRequest.RESULT_REQUEST_FAILED: return "Request failed"
		HTTPRequest.RESULT_TIMEOUT: return "Timeout"
		_: return "Unknown error (%d)" % result


## Cleanup
func cleanup() -> void:
	if _http_search != null and is_instance_valid(_http_search):
		_http_search.queue_free()
		_http_search = null
	if _http_details != null and is_instance_valid(_http_details):
		_http_details.queue_free()
		_http_details = null
