extends VBoxContainer

const UM_DIA_UNIX = 86400 ## 60 segs * 60 mins * 24 hrs = 86400 segs


var scroll_timer := 0.0
var scroll_timerout := 0.3
var which_scroll_is_active := "" ## Qual dos scrolls esta ativos: 'Anos', 'Meses ou 'Dias'

var _ano_ativo :int ## Ano em foco/selecionado no calendário
var _mes_ativo :int ## Mês em foco/selecionado no calendário -> 0 Jan, 1 Fev, ... , 11 Dez
var _dia_ativo :int ## Dia em foco/selecionado no calendário

var _hA :int ## Tamanho da Linha dos Anos -> 12 x tamanho dos Meses (12 x 5 x 133 px)
var _hM :int ## Tamanho da Linha dos Meses -> 5 x tamanho dos Dias (5 x 133 px)
var _hD :int ## Tamanho da Linha dos Dias -> em teste padrao 133 px



func _ready():
	set_process(false)
	__preencher_calendario_inicialmente()
	await get_tree().process_frame  # Espera um frame para layout aplicar
	var tamanho_min_dia = $"HBoxContainer/Dias/VBoxContainer/S1/D1".size
	__ajuste_de_tamanhos(tamanho_min_dia)
	await get_tree().process_frame
	__get_tamanho_ajustado()
	__resetar_posicionamento_dos_scrolls()
	$HBoxContainer/Anos.connect("gui_input", Callable(self, "__on_scroll_input").bind($HBoxContainer/Anos))
	$HBoxContainer/Meses.connect("gui_input", Callable(self, "__on_scroll_input").bind($HBoxContainer/Meses))
	$HBoxContainer/Dias.connect("gui_input", Callable(self, "__on_scroll_input").bind($HBoxContainer/Dias))

func _process(delta: float) -> void:
	#__scroll_sincronizado()
	__efeito_carrossel()
	__verificacao_inatividade_scrollactive(delta)





###############################################################################



func __on_scroll_input(event, emissor):
	which_scroll_is_active = emissor.name # Meses / Anos / Dias
	if event is InputEventMouseButton or event is InputEventGesture or event is InputEventScreenDrag:
		set_process(true)
		scroll_timer = scroll_timerout

	# ROLAGEM de mouse
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				emissor.scroll_vertical += event.factor * 1
			MOUSE_BUTTON_WHEEL_DOWN:
				emissor.scroll_vertical += event.factor * 1
	
	# TOUCHPAD de notebooks
	if event is InputEventPanGesture:
		print("Scroll delta:", event.delta.y)
	
	# ARRASTO dedo ou mouse
	if event is InputEventScreenDrag:
		print("Rolagem/arrasto:", event.relative.y)


func __ajuste_de_tamanhos(tamanho:Vector2):
	var h = tamanho[1] ## Altura (pixels) das células/linhas dos dias do Calendário (padrão de teste = 133 px)
	
	# Dias
	$HBoxContainer/Dias/VBoxContainer.custom_minimum_size[1] = h * ( 5 + 2 ) # quantos tem
	$HBoxContainer/Dias.custom_minimum_size[1] = h * 5 # quantos devem aparecer
	for semana in $HBoxContainer/Dias/VBoxContainer.get_children():
		semana.custom_minimum_size[1] = h
		semana.visible = true
	
	# Meses
	$HBoxContainer/Meses/HBoxContainer.custom_minimum_size[1] = ( 5 * h ) * 3 
	$HBoxContainer/Meses.custom_minimum_size[1] = ( 5 * h ) * 1 
	for mes in $HBoxContainer/Meses/HBoxContainer.get_children():
		mes.custom_minimum_size[1] = h * 5
	
	# Anos
	$HBoxContainer/Anos/HBoxContainer.custom_minimum_size[1] = ( 5 * h ) * 3
	$HBoxContainer/Anos.custom_minimum_size[1] = ( 5 * h ) * 1
	for ano in $HBoxContainer/Anos/HBoxContainer.get_children():
		ano.custom_minimum_size[1] = 12 * h * 5 * 3

func __get_tamanho_ajustado():
	_hD = $"HBoxContainer/Dias/VBoxContainer/S0/D1".size[1]
	_hM = $"HBoxContainer/Meses/HBoxContainer/0".size[1]
	_hA = $"HBoxContainer/Anos/HBoxContainer/0".size[1]
	
func __resetar_posicionamento_dos_scrolls(scroll_name:String=""):
	if scroll_name == 'Dias' or scroll_name=="":
		$HBoxContainer/Dias.scroll_vertical = _hD + 1 # +1 para evitar ficar com borda grossa devido ao separador dos dias da semana com a semana anterior
	if scroll_name == 'Meses' or scroll_name=="":
		$HBoxContainer/Meses.scroll_vertical = _hM - 1
	if scroll_name == 'Anos' or scroll_name=="":
		$HBoxContainer/Anos.scroll_vertical = _hA * (1 + float(_mes_ativo)/12)


func __preencher_calendario_inicialmente():
	var datetime_dict = Time.get_datetime_dict_from_system() ## Dicionário da data de agora. Keys: [year, month, day, weekday, hour, minute, second]
	_dia_ativo = int(datetime_dict["day"])
	
	datetime_dict["day"]=1 # altera a data para o dia 1 do mesmo mês e ano.

	## Data (em string) do 1° dia do mês. Formato: YYYY-MM-DD HH:MM:SS
	var dia_1_string = Time.get_datetime_string_from_datetime_dict(datetime_dict,true)

	## Data (em dicionário) do 1° dia do mês. Keys: [year, month, day, weekday, hour, minute, second]
	var dia_1_dict = Time.get_datetime_dict_from_datetime_string(dia_1_string, true)
	
	__preencher_nomes_dos_dias_da_semana()
	__preencher_nome_do_mes( dia_1_dict["month"], dia_1_dict["year"]) # -1 para corrigir a saida dict [1-Jan 2-Fez ... 12-Dez] -> [0-Jan 1-Fev ... 11-Dez]
	__preencher_ano(dia_1_dict["year"])
	__preencher_dias(dia_1_dict)

## Preenche as células (de dias) do calendário.
## Insere-se a data da primeira semana a ser exibida para completar as demais células 
func __preencher_dias(data_primeira_semana:Dictionary):
	var hoje_unix = Time.get_unix_time_from_datetime_dict(data_primeira_semana) ## Data (em unix) da primeira semana do mês
	var dia_semana = data_primeira_semana["weekday"] ## Número do dia da semana -> 0 Domingo, 1 Segunda, ... 6 Sabado
	var data_1o_domingo = hoje_unix - dia_semana * UM_DIA_UNIX ## Data do 1° domingo deste mês (em unix)
	var num_dia = data_1o_domingo - 7 * UM_DIA_UNIX ## Data (em unix) <- inicialmente do domingo anterior ao 1° domingo do mês
	
	## semana é um item da lista -> [S0, S1, ... , S6]
	for semana in $HBoxContainer/Dias/VBoxContainer.get_children():
		var lista_dias = semana.get_children() ## [S, D1, ... , D7] <- Lista dos Nodes de 'HBoxContainer/Dias/VBoxContainer'
		#lista_dias.pop_front()
		for i in range(lista_dias.size()):
			var dia = lista_dias[i] ## um dos seguintes nodes -> [S, D1, ... , D7]
			dia.alterar_para_a_data(num_dia)
			if not dia.name == "S":
				num_dia += UM_DIA_UNIX

## Ao invés de aplicar avancar_dias(n) em cada uma das células,
## esta função poupa processamento copiando as células centrais em deslocamento
func __alterar_dias(avanco:bool) -> void:
	var lista_semana = $HBoxContainer/Dias/VBoxContainer.get_children() ## l = [ S0 , S1 , ... , S5 , S6 ]
	var semana_atual ## um dos elementos -> [ S0 , S1 , ... , S6 ] 
	var lista_dias ## l = [S, D1, ... , D7]
	
	# avançar dias no calendario / descer 
	if avanco:
		for s in lista_semana.size(): ## [S0,S1,...S6].size() = 7
			semana_atual = lista_semana[s] ## um dos elementos -> [ S0 , S1 , ... , S6 ] 
			lista_dias = semana_atual.get_children() ## [S, D1, ... , D7] de umas das Semanas S0 a S6
			
			var lista_dias_semana_seguinte := [] ## [S, D1, ... , D7] da semana seguinte
			if s < 6:
				var semana_seguinte = lista_semana[s+1] ## prox semana -> [ S1 , ... , S6 ] 
				lista_dias_semana_seguinte = semana_seguinte.get_children()
				#lista_dias_semana_seguinte.pop_front()
			
			for i in lista_dias.size():
				if s < 6:
					lista_dias[i].copiar_atributos( lista_dias_semana_seguinte[i] )
				else:
					lista_dias[i].avancar_dias(7)
	
	# voltar dias no calendario / subir
	else: 
		for s in lista_semana.size(): ## [S0,S1,...S6].size() = 7
			semana_atual = lista_semana[6-s] 
			lista_dias = semana_atual.get_children()
			#lista_dias.pop_front()
			
			var lista_dias_semana_anterior := []
			if 6-s > 0:
				var semana_anterior = lista_semana[6-s-1] ## semana anterior -> [ S0 , S1 , ... , S5 ] 
				lista_dias_semana_anterior = semana_anterior.get_children()
				#lista_dias_semana_anterior.pop_front()
			for i in lista_dias.size():
				if 6-s > 0:
					lista_dias[i].copiar_atributos( lista_dias_semana_anterior[i] )
				else:
					lista_dias[i].avancar_dias(-7)



## Preenche as células dos Anos do calendário com base no ano inserido
func __preencher_ano(n:int):
	_ano_ativo = n
	 # "{0}-01-01 12:00:00".format([ano])
	$"HBoxContainer/Anos/HBoxContainer/-1".alterar_para_a_data("{0}-01-01 12:00:00".format([n-1]))
	$"HBoxContainer/Anos/HBoxContainer/0".alterar_para_a_data("{0}-01-01 12:00:00".format([n]))
	$"HBoxContainer/Anos/HBoxContainer/+1".alterar_para_a_data("{0}-01-01 12:00:00".format([n+1]))

## Preenche as células dos Meses do calendário com base no mês inserido (e ano)
func __preencher_nome_do_mes(m:int, y:int):
	var _mes_anterior = (12 + m - 1) % 12
	_mes_ativo = (12 + m) % 12
	var _mes_posterior = (m + 1) % 12
	print("{0}-{1}-01 12:00:00".format([y,_mes_ativo]))
	$"HBoxContainer/Meses/HBoxContainer/-1".alterar_para_a_data("{0}-{1}-01 12:00:00".format([y,_mes_anterior]))
	$"HBoxContainer/Meses/HBoxContainer/0".alterar_para_a_data("{0}-{1}-01 12:00:00".format([y,_mes_ativo]))
	$"HBoxContainer/Meses/HBoxContainer/+1".alterar_para_a_data("{0}-{1}-01 12:00:00".format([y,_mes_posterior]))



## Preenche no Calendario os dias da semana ('Dom', 'Seg', ... , 'Sab')
func __preencher_nomes_dos_dias_da_semana():
	var DiaSemana = ["Dom","Seg","Ter","Qua","Qui","Sex","Sab"]
	for i in DiaSemana.size():
		var dia = DiaSemana[i]
		var node_name = "D{0}".format([i+1])
		$DiaDaSemana.get_node(node_name).get_node("Label").text = dia


#func eh_ano_bissexto(ano: int) -> bool:
	#return (ano % 4 == 0 and ano % 100 != 0) or (ano % 400 == 0)
#
#func dias_no_mes(mes: int, ano: int) -> int:
	#match mes:
		#1, 3, 5, 7, 8, 10, 12:
			#return 31
		#4, 6, 9, 11:
			#return 30
		#2:
			#return 29 if eh_ano_bissexto(ano) else 28
		#_:
			#return 0  # inválido


## OBS: Qualquer edicao aqui por favor refletir em -> [method __posicionamento_inicial_dos_scrolls()]
func __efeito_carrossel():
	# Anos
	var scroll_anos = $HBoxContainer/Anos.scroll_vertical
	if scroll_anos == 0:
		__resetar_posicionamento_dos_scrolls("Anos")
		$"HBoxContainer/Anos/HBoxContainer/-1".avancar_anos(-1)
		$"HBoxContainer/Anos/HBoxContainer/0".avancar_anos(-1)
		$"HBoxContainer/Anos/HBoxContainer/+1".avancar_anos(-1)
	elif scroll_anos >= _hA * 2 - 2: # Esse último '-2' é porque são 3 meses, logo tem 2 divisões entre eles de 1 pixel cada.
		__resetar_posicionamento_dos_scrolls("Anos")
		$"HBoxContainer/Anos/HBoxContainer/-1".avancar_anos(1)
		$"HBoxContainer/Anos/HBoxContainer/0".avancar_anos(1)
		$"HBoxContainer/Anos/HBoxContainer/+1".avancar_anos(1)
	
	# Meses
	var scroll_meses = $HBoxContainer/Meses.scroll_vertical
	if scroll_meses == 0: # voltando
		_mes_ativo -= 1
		__resetar_posicionamento_dos_scrolls("Meses")
		$"HBoxContainer/Meses/HBoxContainer/-1".avancar_meses(-1)
		$"HBoxContainer/Meses/HBoxContainer/0".avancar_meses(-1)
		$"HBoxContainer/Meses/HBoxContainer/+1".avancar_meses(-1)
	elif scroll_meses >= _hM * 2 - 2:
		_mes_ativo += 1
		__resetar_posicionamento_dos_scrolls("Meses")
		$"HBoxContainer/Meses/HBoxContainer/-1".avancar_meses(1)
		$"HBoxContainer/Meses/HBoxContainer/0".avancar_meses(1)
		$"HBoxContainer/Meses/HBoxContainer/+1".avancar_meses(1)
	
	# Dias
	var scroll_dias = $HBoxContainer/Dias.scroll_vertical
	if scroll_dias == 0:
		__resetar_posicionamento_dos_scrolls("Dias")
		__alterar_dias(false)
	elif scroll_dias >= _hD * 2 - 1: #268 # certificar que vai do S0 ao S6
		__resetar_posicionamento_dos_scrolls("Dias")
		__alterar_dias(true)

## Usado no _process(), desliga o _process() caso 
## detectado inatividade no scroll do calendário
## para evitar processamento do efeito carrossel e etc.
func __verificacao_inatividade_scrollactive(delta):
	scroll_timer -= delta
	if scroll_timer <= 0:
		set_process(false)
