
class_name FileIO

const BOARD_PATH : String = "res://Data/Boards/"
const CARDS_PATH : String = "res://shared/CardsData.csv"

static func getAllFiles(path : String) -> Array:
	var files : Array = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var fileName = dir.get_next()
		while fileName != "":
			if not dir.current_is_dir():
				files.append(fileName)
			fileName = dir.get_next()
	return files

static func readJson(path : String) -> Dictionary:
	if FileAccess.file_exists(path):
		var file : FileAccess = FileAccess.open(path, FileAccess.READ)
		var text : String = file.get_as_text()
		file.close()
		var data = JSON.parse_string(text)
		if data != null:
			return data
		else:
			print("Error parsing json file at ", path)
	else:
		print("Error finding json file at ", path)
	return {}

static func readCSV(path : String) -> Array:
	if FileAccess.file_exists(path):
		var data : Array = []
		var file : FileAccess = FileAccess.open(path, FileAccess.READ)
		var text : String = file.get_as_text()
		
		for line in text.split("\n"):
			#line = line.replace('\r', '')
			data.append(line.split(','))
		file.close()
		
		return data
	else:
		print("Error finding csv file at ", path)
	
	return []
