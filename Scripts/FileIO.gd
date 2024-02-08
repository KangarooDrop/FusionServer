
class_name FileIO

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
