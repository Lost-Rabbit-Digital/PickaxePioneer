class_name TextFilter
extends RefCounted

## Loads a plain-text word list (one word per line) and censors matched words
## in chat messages by replacing each character with a ❤ symbol.
##
## Usage:
##   var filter := TextFilter.new()
##   filter.load_from_file("res://assets/chat_filter.txt")
##   var clean := filter.filter("hello world")
##
## Word list format:
##   - One word per line, UTF-8 encoded.
##   - Lines beginning with # are treated as comments and ignored.
##   - Blank lines are ignored.
##   - Matching is case-insensitive and whole-word (word boundaries respected).

var _patterns: Array[RegEx] = []
var _replacements: Array[String] = []

## Load the word list from *path* (e.g. "res://assets/chat_filter.txt").
## Returns true on success.  Clears any previously loaded list first.
func load_from_file(path: String) -> bool:
	_patterns.clear()
	_replacements.clear()

	if not FileAccess.file_exists(path):
		push_warning("TextFilter: word list not found: %s" % path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("TextFilter: cannot open word list: %s" % path)
		return false

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		# Skip blank lines and comment lines.
		if line.is_empty() or line.begins_with("#"):
			continue
		_add_word(line)

	return true

## Filter *text*, replacing each filtered word with ❤ repeated for every
## character in that word.  Returns the sanitised string.
func filter(text: String) -> String:
	var result := text
	for i: int in _patterns.size():
		result = _patterns[i].sub(result, _replacements[i], true)
	return result

## Returns true if the word list is empty (no file loaded or file was empty).
func is_empty() -> bool:
	return _patterns.is_empty()

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _add_word(word: String) -> void:
	var lower := word.to_lower()
	var rx := RegEx.new()
	# (?i) — case-insensitive; \b — whole-word boundaries so "class" does not
	# catch "classic".
	var err := rx.compile("(?i)\\b" + _regex_escape(lower) + "\\b")
	if err != OK:
		push_warning("TextFilter: failed to compile pattern for word '%s'" % lower)
		return
	_patterns.append(rx)
	# One ❤ per character so the censored slot has the same width as the original.
	_replacements.append("❤".repeat(lower.length()))

## Escape special regex metacharacters inside a literal word.
func _regex_escape(word: String) -> String:
	const SPECIAL: String = "\\^$.|?*+()[]{}"
	var out: String = ""
	for c: String in word:
		if SPECIAL.contains(c):
			out += "\\" + c
		else:
			out += c
	return out
