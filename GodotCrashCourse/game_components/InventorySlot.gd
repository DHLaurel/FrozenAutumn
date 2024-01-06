extends TextureButton

signal slot_pressed(which : TextureButton)

var item_texture

func _on_pressed():
	slot_pressed.emit(self)
