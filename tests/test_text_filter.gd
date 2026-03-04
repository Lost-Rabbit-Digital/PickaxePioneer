extends GutTest

# Unit tests for TextFilter.
# TextFilter is a RefCounted class that censors words loaded from a word list
# file, replacing each matched character with ❤.

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Build a TextFilter whose word list is loaded from a temporary in-memory
## word list rather than a real file, so tests do not depend on disk I/O.
func _make_filter(words: Array[String]) -> TextFilter:
	var tf := TextFilter.new()
	# Directly populate internals by calling _add_word, which is a
	# private helper we can access from GDScript.
	for w in words:
		tf._add_word(w)
	return tf

# ---------------------------------------------------------------------------
# filter() — basic replacement
# ---------------------------------------------------------------------------

func test_single_word_replaced() -> void:
	var tf := _make_filter(["dang"])
	assert_eq(tf.filter("dang"), "❤❤❤❤")

func test_replacement_length_matches_word_length() -> void:
	var tf := _make_filter(["hi"])
	# "hi" is 2 chars → 2 hearts
	assert_eq(tf.filter("hi"), "❤❤")

func test_clean_text_unchanged() -> void:
	var tf := _make_filter(["dang"])
	assert_eq(tf.filter("nice haul"), "nice haul")

func test_word_mid_sentence() -> void:
	var tf := _make_filter(["dang"])
	assert_eq(tf.filter("oh dang it"), "oh ❤❤❤❤ it")

func test_multiple_words_in_list() -> void:
	var tf := _make_filter(["foo", "bar"])
	assert_eq(tf.filter("foo and bar"), "❤❤❤ and ❤❤❤")

func test_multiple_occurrences_replaced() -> void:
	var tf := _make_filter(["bad"])
	assert_eq(tf.filter("bad bad bad"), "❤❤❤ ❤❤❤ ❤❤❤")

# ---------------------------------------------------------------------------
# Case insensitivity
# ---------------------------------------------------------------------------

func test_uppercase_input_matched() -> void:
	var tf := _make_filter(["dang"])
	assert_eq(tf.filter("DANG"), "❤❤❤❤")

func test_mixed_case_input_matched() -> void:
	var tf := _make_filter(["dang"])
	assert_eq(tf.filter("DaNg"), "❤❤❤❤")

func test_uppercase_word_in_list_matched() -> void:
	var tf := _make_filter(["DANG"])
	assert_eq(tf.filter("dang"), "❤❤❤❤")

# ---------------------------------------------------------------------------
# Whole-word matching
# ---------------------------------------------------------------------------

func test_substring_not_matched() -> void:
	# "class" should NOT be filtered when the word list only contains "ass"
	var tf := _make_filter(["ass"])
	assert_eq(tf.filter("class"), "class")

func test_word_at_start_of_string() -> void:
	var tf := _make_filter(["bad"])
	assert_eq(tf.filter("bad day"), "❤❤❤ day")

func test_word_at_end_of_string() -> void:
	var tf := _make_filter(["bad"])
	assert_eq(tf.filter("so bad"), "so ❤❤❤")

func test_word_with_punctuation_boundary() -> void:
	var tf := _make_filter(["dang"])
	assert_eq(tf.filter("dang!"), "❤❤❤❤!")

# ---------------------------------------------------------------------------
# Empty / edge cases
# ---------------------------------------------------------------------------

func test_empty_word_list_returns_unchanged() -> void:
	var tf := TextFilter.new()
	assert_eq(tf.filter("whatever"), "whatever")

func test_is_empty_true_when_no_words_loaded() -> void:
	var tf := TextFilter.new()
	assert_true(tf.is_empty())

func test_is_empty_false_after_word_added() -> void:
	var tf := _make_filter(["bad"])
	assert_false(tf.is_empty())

func test_empty_string_input() -> void:
	var tf := _make_filter(["bad"])
	assert_eq(tf.filter(""), "")

# ---------------------------------------------------------------------------
# load_from_file() — missing file
# ---------------------------------------------------------------------------

func test_load_missing_file_returns_false() -> void:
	var tf := TextFilter.new()
	var ok := tf.load_from_file("res://nonexistent_chat_filter.txt")
	assert_false(ok)

func test_load_missing_file_leaves_filter_empty() -> void:
	var tf := TextFilter.new()
	tf.load_from_file("res://nonexistent_chat_filter.txt")
	assert_true(tf.is_empty())
