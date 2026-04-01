extends Control
class_name MaterialClass

var cur_data = {}
func _ready() -> void:
	GlobalDiggingProcess.block_hp_updated.connect(_on_block_hp_updated)
	GlobalDiggingProcess.block_destroyed.connect(_on_block_destroyed)
	SetPartilces()
	GlobalBtn.AddBtnPress(self)
	GlobalBtn.BtnPress.connect(OnTap)

func OnTap(node_control:Control):
	if node_control != self:
		return
	if $tap_timer.is_stopped():
		GlobalDiggingProcess.ApplyTapDamage(cur_data.uid)
		$tap_timer.start()
	


func _on_block_hp_updated(_lane_index: int, block_uid: String, hp: float, max_hp: float, _hp_percent: float) -> void:
	if block_uid != cur_data.uid:
		return
	SetAsMining(true)
	$BG/VList/ProgressBar.max_value = max_hp
	if hp == max_hp:
		$BG/VList/ProgressBar.value = hp
	else:
		var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property($BG/VList/ProgressBar,"value",hp,0.2)
		TakeDmgAnimation()


func TakeDmgAnimation():
	var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property($BG,"position:x",-2,0.1)
	t.tween_property($BG,"position:x",2,0.1)
	t.tween_property($BG,"position:x",0,0.1)
	$Particles/DirtParticles.restart()
	$Particles/DirtParticles.emitting = true

func _on_block_destroyed(_lane_index: int, block_uid: String) -> void:
	if block_uid != cur_data.uid:
		return
	GlobalSignals.ShowCurrencyAnimation.emit(global_position+(size/2.0),cur_data.reward_type,2)
	SetAsMining(false)
	AnimateColapseAndFree()
	
func AnimateColapseAndFree():
	$BG/VList/ProgressBar.visible = false
	var t = create_tween()
	t.tween_property(self,"custom_minimum_size:y",0,0.2)
	t.finished.connect(func(): queue_free())
	
func InitData(data):
	SetAsMining(false)
	cur_data = data.duplicate()
	$BG/VList/name.text = cur_data.name
	$BG/VList/ProgressBar.max_value = cur_data.max_hp
	$BG/VList/ProgressBar.value = cur_data.hp
	$BG.self_modulate = GlobalColor.GetBlockColorFromKey(cur_data.color)
	$Particles.modulate = $BG.self_modulate*1.1
	$BG/VList/name.self_modulate = GlobalColor.GetReadableTextColor($BG.self_modulate)
	var cur_block = GlobalDiggingProcess.GetLaneCurrentBlock(cur_data.lane_index)
	if cur_block != {}:
		if GlobalDiggingProcess.IsLaneDigging(cur_data.lane_index):
			_on_block_hp_updated(cur_block.lane_index,cur_block.uid,cur_block.hp,cur_block.max_hp,0)

func SetAsMining(is_mining):
	if is_mining:
		$BG/VList/ProgressBar.visible = true
		$BG/VList/StatusMining.visible = true
	else:
		$BG/VList/ProgressBar.visible = false
		$BG/VList/StatusMining.visible = false

func SetPartilces():
	$Particles.visible = true
	$Particles/DirtParticles.emitting = false
	$Particles/DirtParticles.one_shot = true
	
