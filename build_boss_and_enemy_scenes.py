import os

scenes = {
	"scenes/entities/BossArachnid.tscn": """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/entities/boss_controller.gd" id="1_scr"]
[ext_resource type="Texture2D" path="res://assets/sprites/spr_boss_arachnid.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_arachnid"]
size = Vector2(80, 80)

[node name="BossArachnid" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 5
script = ExtResource("1_scr")
boss_type = "arachnid"
boss_name = "ARACHNID-SOVEREIGN"
max_hp = 1100
base_speed = 52.0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 4

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_arachnid")

[node name="AnimTimer" type="Timer" parent="."]
wait_time = 0.16
autostart = true
""",

	"scenes/entities/BossNexus.tscn": """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/entities/boss_controller.gd" id="1_scr"]
[ext_resource type="Texture2D" path="res://assets/sprites/spr_boss_nexus.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="CircleShape2D_nexus"]
radius = 42.0

[node name="BossNexus" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 5
script = ExtResource("1_scr")
boss_type = "nexus"
boss_name = "NEXUS-PRIME A.I."
max_hp = 1500
base_speed = 60.0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 4

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_nexus")

[node name="AnimTimer" type="Timer" parent="."]
wait_time = 0.15
autostart = true
""",

	"scenes/entities/BossDreadnought.tscn": """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/entities/boss_controller.gd" id="1_scr"]
[ext_resource type="Texture2D" path="res://assets/sprites/spr_boss_dreadnought.png" id="2_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_dread"]
size = Vector2(90, 86)

[node name="BossDreadnought" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 5
script = ExtResource("1_scr")
boss_type = "dreadnought"
boss_name = "DREADNOUGHT-GOLIATH"
max_hp = 2100
base_speed = 40.0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 4

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
position = Vector2(0, 4)
shape = SubResource("RectangleShape2D_dread")

[node name="AnimTimer" type="Timer" parent="."]
wait_time = 0.18
autostart = true
""",

	"scenes/entities/BossChrono.tscn": """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/entities/boss_controller.gd" id="1_scr"]
[ext_resource type="Texture2D" path="res://assets/sprites/spr_boss_chrono.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="CircleShape2D_chrono"]
radius = 48.0

[node name="BossChrono" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 5
script = ExtResource("1_scr")
boss_type = "chrono"
boss_name = "CHRONO-HARBINGER OMEGA"
max_hp = 3000
base_speed = 70.0

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 4

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_chrono")

[node name="AnimTimer" type="Timer" parent="."]
wait_time = 0.12
autostart = true
""",

	"scenes/entities/EnemyKamikaze.tscn": """[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/entities/enemy_base.gd" id="1_scr"]
[ext_resource type="Texture2D" path="res://assets/sprites/spr_enemy_kamikaze.png" id="2_tex"]

[sub_resource type="CircleShape2D" id="CircleShape2D_kamikaze"]
radius = 12.0

[node name="EnemyKamikaze" type="CharacterBody2D"]
collision_layer = 4
collision_mask = 5
script = ExtResource("1_scr")
enemy_type = "kamikaze"
max_hp = 16
base_speed = 195.0
contact_damage = 2
exp_reward = 10

[node name="Sprite2D" type="Sprite2D" parent="."]
texture = ExtResource("2_tex")
hframes = 4

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("CircleShape2D_kamikaze")

[node name="AnimTimer" type="Timer" parent="."]
wait_time = 0.08
autostart = true
"""
}

base_dir = "C:/Users/WA/Documents/OROS_MicroGame"
for rel_path, content in scenes.items():
	full_path = os.path.join(base_dir, rel_path)
	with open(full_path, "w", encoding="utf-8") as f:
		f.write(content.strip())
	print(f"Created {rel_path}")
