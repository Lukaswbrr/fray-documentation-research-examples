extends Node

# Wait, i get it!
# The pseudo interface checks a interface of a object (in this example, IHitbox) and it sees if the
# script (test_pseudo_interface) has the methods and signals!
# Where is this supposed to be use, though?

const pseudo = preload("res://addons/fray/lib/helpers/pseudo_interface.gd")

const _interfaces = {
	"IHitbox" : {
		"methods" : ["activate", "deactivate", "set_source"],
		"signals" : ["hitbox_entered", "hitbox_exited"],
	},
}

func _ready() -> void:
	#print(pseudo.implements(self, "IHitbox"))
	pseudo.assert_implements(self, "IHitbox")

func activate():
	pass
