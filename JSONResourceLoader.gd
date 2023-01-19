extends Node

var data_base_path = 'res://Data/'

func load_json(json_path: String):
	var path = data_base_path + json_path;
	if !FileAccess.file_exists(path):
		printerr(path+ ' : dont exist');
	var file = FileAccess.open(path, FileAccess.READ);
	var json_parse = JSON.parse_string(file.get_as_text());
	if json_parse == null:
		printerr(json_parse.error_string);
		printerr(json_parse.error_line);
	return json_parse;
