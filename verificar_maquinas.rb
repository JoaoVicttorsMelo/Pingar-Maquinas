require_relative 'conectar_banco'
obj = ConectarBanco.new
obj.script("SELECT ip FROM FILIAIS_IP where servidor=1")
#obj.ping("SELECT ip FROM FILIAIS_IP where servidor=1")
obj.fechar_conexao
