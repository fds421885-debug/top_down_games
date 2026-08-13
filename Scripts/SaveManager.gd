extends Node

const SAVE_PATH = "user://player_save.data"

var player_data = {
	"player_name": "",
	"saved_wave": 1,
	"google_id": ""
}

func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(player_data)
		file.store_string(json_string)
		print("تم حفظ بيانات اللاعب محلياً بنجاح.")

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			var error = json.parse(file.get_as_text())
			if error == OK:
				player_data = json.get_data()
				print("تم تحميل بيانات اللاعب محلياً.")
