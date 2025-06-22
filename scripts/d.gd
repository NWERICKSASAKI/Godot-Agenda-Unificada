extends Control

const UM_DIA_UNIX = 86400 ## 60 * 60 * 24 = 86400
const UMA_SEMANA_UNIX = UM_DIA_UNIX * 7

@export_enum("Ano", "Mes", "Semana", "Dia", "Nome da Semana") var tipo_de_celula # 0, 1, 2, 3

#@export_range(0,1,0.01,"Controle de Opacidade da celula") var A = 0.5 # alpha / opacidade

var data_dicionario:Dictionary
var data_unix:int = 0
var ano:int
var dia:int
var mes:int ## 0 = Janeiro,[br]1 = Fevereiro,[br]...[br]11 = Dezembro
var dia_da_semana:int ## 0 = Domingo,[br]1 = Segunda,[br]...[br]6 = Sábado
var numero_da_semana:int

@onready var COR_MES = Global.COR_MES
@onready var NOME_MESES = Global.NOME_MESES

func _ready():#
	pass

func _alterar_aparencia():
	$Label.text = str(dia)
	if tipo_de_celula == 0: # ano
		$Label.text = __string_ano_formatado()
	elif tipo_de_celula == 1: # mes
		var n_semanas_no_mes = qtd_semanas_no_mes(mes,ano)
		$Label.text = "\n".join(str(NOME_MESES[mes]).split(""))
	elif tipo_de_celula == 2: # semana
		$Label.text = "S" + str(numero_da_semana)
	$ColorRect.color = COR_MES[mes % 12]


func atualizar_data_unix_com_base_nos_atributos():
	assert( mes >= 0, "'mes' precisa ser maior ou igual que 0. mes -> {0}".format([mes]));
	#  year, month, day, hour, minute, and second.
	var dicionario = {
		"year":ano,
		"month":mes+1, # +1 porque em Time os meses começam em 1 - Jan, 2 - Fev ... 12 - Dez
		"day":dia,
		"hour":12
	}
	data_unix = Time.get_unix_time_from_datetime_dict(dicionario)
	alterar_para_a_data(data_unix)

func alterar_para_a_data(nova_data):
	if nova_data is String: #YYYY-MM-DD HH:MM:SS
		nova_data = Time.get_unix_time_from_datetime_string(nova_data)
	data_unix = nova_data
	data_dicionario = Time.get_datetime_dict_from_unix_time(data_unix)
	dia_da_semana = data_dicionario['weekday']
	dia = data_dicionario["day"]
	mes = data_dicionario["month"]-1 #  Dicio (mês) = { 1-Jan, 2-Fev, ... 12-Dez  } -1 para ao meu modelo
	ano = data_dicionario["year"]
	numero_da_semana = calcular_numero_da_semana(data_unix)
	#tipo_de_celula
	_alterar_aparencia()

func avancar_dias(n:int):
	var avanco_de_dia_em_unix = UM_DIA_UNIX * n
	var nova_data_unix = data_unix + avanco_de_dia_em_unix
	alterar_para_a_data(nova_data_unix)

func avancar_meses(n:int):
	var d_ano = ( mes + abs(n) ) / 12 * sign(n)
	mes = (mes+12 + n)%12 # +12 para evitar que mes = -1
	ano += d_ano
	atualizar_data_unix_com_base_nos_atributos()

func avancar_anos(n:int):
	ano += n
	atualizar_data_unix_com_base_nos_atributos()

func copiar_atributos(obj):
	data_dicionario = obj.data_dicionario
	data_unix = obj.data_unix
	dia_da_semana = obj.dia_da_semana
	dia = obj.dia
	mes = obj.mes
	ano = obj.ano
	numero_da_semana = obj.numero_da_semana
	tipo_de_celula = obj.tipo_de_celula
	custom_minimum_size = obj.custom_minimum_size
	if $Button.has_focus():
		$Button.release_focus()
	elif obj.get_node("Button").has_focus():
		$Button.grab_focus()
	_alterar_aparencia()

## A partir da data unix, retorna o número da semana.
## Convencionalmente, a semana vai de Seg -> Dom
## ao invés de Dom -> Sab
func calcular_numero_da_semana(data_em_unix:int, dom_a_seg=true) -> int:
	var data_string_1o_dia_do_ano = "{0}-01-01 12:00:00".format([ano]) #YYYY-MM-DD HH:MM:SS
	var unix_data_1o_dia_do_ano = Time.get_unix_time_from_datetime_string(data_string_1o_dia_do_ano)
	var dict_data_1o_dia_do_ano = Time.get_datetime_dict_from_datetime_string(data_string_1o_dia_do_ano, true)
	var dia_da_semama_1o_dia_do_ano = int(dict_data_1o_dia_do_ano['weekday']) ## 0 Domindo, 1 Seg, ... , 6 Sábado
	#var unix_anterior_domingo = unix_data_1o_dia_do_ano - (7 - dia_da_semama_1o_dia_do_ano) * UM_DIA_UNIX
	var num_da_semana
	if dom_a_seg:
		var unix_segunda_anterior = unix_data_1o_dia_do_ano - (dia_da_semama_1o_dia_do_ano - 1) * UM_DIA_UNIX
		@warning_ignore("integer_division")
		num_da_semana = ( data_em_unix - unix_segunda_anterior ) / UMA_SEMANA_UNIX + 1 # +1 pq a numeração das semanas começa em 1.
	else: # Usado para fins de calculos "Quantas semanas o mês/ano tem"
		var unix_domingo_anterior = unix_data_1o_dia_do_ano - dia_da_semama_1o_dia_do_ano * UM_DIA_UNIX
		@warning_ignore("integer_division")

		num_da_semana = ( data_em_unix - unix_domingo_anterior ) / UMA_SEMANA_UNIX + 1 # +1 pq a numeração das semanas começa em 1.
	return num_da_semana

## Retorna a quantidade de semanas que o mês possui.
## Função usada para determinar a altura das células dos Meses.
func qtd_semanas_no_mes(_mes=mes,_ano=ano) -> Array:
	_mes += 1 # para adaptar ao unix 
	var string_1o_dia_do_mes =  "{0}-{1}-01 12:00:00".format([_ano,_mes]) #YYYY-MM-DD HH:MM:SS
	var dict_1o_dia_do_mes = Time.get_datetime_dict_from_datetime_string(string_1o_dia_do_mes,true)
	var domingo_1o_dia:bool = dict_1o_dia_do_mes['weekday']==0
	var unix_1o_dia_do_mes =  Time.get_unix_time_from_datetime_string(string_1o_dia_do_mes)
	var num_semana_1o_dia = calcular_numero_da_semana(unix_1o_dia_do_mes,false)
	
	var prox_mes = (_mes+1)%13 # Caso o mês (atual) seja 11 (dez) retona para 0 (jan).
	if prox_mes < mes:
		_ano += 1
		prox_mes += 1
	
	var string_1o_dia_do_prox_mes =  "{0}-{1}-01 12:00:00".format([_ano,prox_mes]) #YYYY-MM-DD HH:MM:SS
	var unix_1o_dia_do_prox_mes =  Time.get_unix_time_from_datetime_string(string_1o_dia_do_prox_mes)
	var unix_ultimo_dia_do_mes = unix_1o_dia_do_prox_mes - UM_DIA_UNIX

	var dict_ult_dia_do_mes = Time.get_datetime_dict_from_unix_time(unix_ultimo_dia_do_mes)
	var sabado_ult_dia:bool = dict_ult_dia_do_mes['weekday']==6

	var num_semana_ultimo_dia = calcular_numero_da_semana(unix_ultimo_dia_do_mes,false)
	
	var num_de_semanas_no_mes = num_semana_ultimo_dia - num_semana_1o_dia + 1
	#var num_de_semanas_no_mes = ceil((float(unix_ultimo_dia_do_mes - unix_1o_dia_do_mes)/UMA_SEMANA_UNIX))
	
	var lista = [num_de_semanas_no_mes, domingo_1o_dia, sabado_ult_dia]
	assert(num_de_semanas_no_mes<=6, "Erro {}".format([num_de_semanas_no_mes]))
	return lista

## Retorna a quantidade de semanas que o ano possui.
## Função usada para determinar a altura das células dos Anos.
func qtd_semanas_no_ano(_ano=ano) -> int:
	var string_1o_dia_do_ano =  "{0}-{1}-01 12:00:00".format([_ano]) #YYYY-MM-DD HH:MM:SS
	var unix_1o_dia_do_ano =  Time.get_datetime_string_from_unix_time(string_1o_dia_do_ano)
	var num_semana_1o_dia = calcular_numero_da_semana(unix_1o_dia_do_ano)
	
	var string_1o_dia_do_prox_ano =  "{0}-01-01 12:00:00".format([_ano+1]) #YYYY-MM-DD HH:MM:SS
	var unix_1o_dia_do_prox_ano =  Time.get_datetime_string_from_unix_time(string_1o_dia_do_prox_ano)
	var unix_ultimo_dia_do_ano = unix_1o_dia_do_prox_ano - UM_DIA_UNIX
	var num_semana_ultimo_dia = calcular_numero_da_semana(unix_ultimo_dia_do_ano)
	
	var num_de_semanas_no_ano = num_semana_ultimo_dia - num_semana_1o_dia
	return num_de_semanas_no_ano


func __string_ano_formatado() -> String:
	var esp = "\n\n\n\n\n" + "\n\n\n\n\n" + "\n\n\n\n\n" + "\n\n\n\n\n"
	var espacamento = esp + esp + esp + esp + esp
	var string_ano = "\n\n\n\n".join(str(ano).split(""))
	return string_ano + espacamento + string_ano + espacamento + string_ano

## Função ao apertar/clicar/tocar a célula do Dia, Mês, Semana ou Ano.
func _on_button_pressed() -> void:
	print("tipo: ",tipo_de_celula, " data:", dia, "/", mes, "/", ano)
	if tipo_de_celula == 1: # month
		print(qtd_semanas_no_mes(mes,ano))
	elif tipo_de_celula == 3: # dia
		print(calcular_numero_da_semana(data_unix,false))
	
