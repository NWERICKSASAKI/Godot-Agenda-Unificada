extends Node

var current_year
var current_month
var current_day

const A = 0.5 # alpha
const COR_MES = [
					Color(1,0,0,A), # 0  Jan
					Color(0,1,0,A), # 1  Fev
					Color(0,0,1,A), # 2  Mar
					Color(1,0,0,A), # 3  Abr
					Color(0,1,0,A), # 4  Mai
					Color(0,0,1,A), # 5  Jun
					Color(1,0,0,A), # 6  Jul
					Color(0,1,0,A), # 7  Ago
					Color(0,0,1,A), # 8  Set
					Color(1,0,0,A), # 9  Out
					Color(0,1,0,A), # 10 Nov
					Color(0,0,1,A)  # 11 Dez
				]
