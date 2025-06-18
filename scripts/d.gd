extends Control

const UM_DIA_UNIX = 86400 ## 60 * 60 * 24 = 86400
const UMA_SEMANA_UNIX = UM_DIA_UNIX * 7

@export_enum("Ano", "Mes", "Semana", "Dia", "Numero da Semana", "Nome da Semana") var tipo_de_celula # 0, 1, 2, 3

#@export_range(0,1,0.01,"Controle de Opacidade da celula") var A = 0.5 # alpha / opacidade

var data_dicionario
var data_unix = 0
var ano:int
var dia:int
var mes:int ## 0 = Janeiro,[br]1 = Fevereiro[br]...[br]11 = Dezembro
var dia_da_semana:int ## 0 = Domingo,[br]1 = Segunda,[br]...[br]6 = Sábado
var numero_da_semana:int

@onready var COR_MES = Global.COR_MES
@onready var NOME_MESES = Global.NOME_MESES

func _ready():#
	pass

func _alterar_aparencia():
	$Label.text = str(dia)
	if tipo_de_celula == 4:
		$Label.text = "S" + str(numero_da_semana)
	elif tipo_de_celula == 1:
		$Label.text = "\n".join(str(NOME_MESES[mes]).split(""))
	elif tipo_de_celula == 0:
		$Label.text = __string_ano_formatado(ano)
	$ColorRect.color = COR_MES[mes % 12]

func alterar_para_a_data(nova_data):
	if nova_data is String: #YYYY-MM-DD HH:MM:SS
		nova_data = Time.get_unix_time_from_datetime_string(nova_data)
	data_unix = nova_data
	data_dicionario = Time.get_datetime_dict_from_unix_time(data_unix)
	dia_da_semana = data_dicionario['weekday']
	dia = data_dicionario["day"]
	mes = data_dicionario["month"]-1
	ano = data_dicionario["year"]
	numero_da_semana = calcular_numero_da_semana(data_unix)
	tipo_de_celula
	_alterar_aparencia()

func avancar_dias(n:int):
	var avanco_de_dia_em_unix = UM_DIA_UNIX * n
	var nova_data_unix = data_unix + avanco_de_dia_em_unix
	alterar_para_a_data(nova_data_unix)

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

func calcular_numero_da_semana(data_em_unix):
	var data_string_1o_dia_do_ano = "{0}-01-01 12:00:00".format([ano]) #YYYY-MM-DD HH:MM:SS
	var unix_data = Time.get_unix_time_from_datetime_string(data_string_1o_dia_do_ano)
	var dict_data = Time.get_datetime_dict_from_datetime_string(data_string_1o_dia_do_ano, true)
	var dia_da_semama = int(dict_data['weekday']) # 0 Domindo, 1 Seg, ... , 6 Sábado
	var unix_prox_domingo = unix_data - (7 - dia_da_semama) * UM_DIA_UNIX
	
	var num_da_semana = ( data_em_unix - unix_prox_domingo ) / UMA_SEMANA_UNIX
	return num_da_semana


func qtd_semanas_no_mes(_ano=ano,_mes=mes):
	var unix_1o_dia_do_mes =  "{0}-{1}-01 12:00:00".format([_ano,_mes]) #YYYY-MM-DD HH:MM:SS
	var num_semana_1o_dia = calcular_numero_da_semana(unix_1o_dia_do_mes)
	
	var unix_1o_dia_do_prox_mes =  "{0}-{1}-01 12:00:00".format([_ano,_mes+1]) #YYYY-MM-DD HH:MM:SS
	var unix_ultimo_dia_do_mes = unix_1o_dia_do_prox_mes - UM_DIA_UNIX
	var num_semana_ultimo_dia = calcular_numero_da_semana(unix_ultimo_dia_do_mes)
	
	var num_de_semanas_no_mes = num_semana_ultimo_dia - num_semana_1o_dia
	return num_de_semanas_no_mes


func __string_ano_formatado(ano:int):
	var esp = "\n\n\n\n\n" + "\n\n\n\n\n" + "\n\n\n\n\n" + "\n\n\n\n\n"
	var espacamento = esp + esp + esp + esp + esp
	var string_ano = "\n\n\n\n".join(str(ano).split(""))
	return string_ano + espacamento + string_ano + espacamento + string_ano

func _on_button_pressed() -> void:
	print("tipo: ",tipo_de_celula, " data:", dia, "/", mes, "/", ano)
	
