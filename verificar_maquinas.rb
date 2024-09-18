require_relative 'conectar_banco'
require 'yaml'

config_path = File.join(__dir__, 'config.yml')
config = YAML.load_file(config_path)

caminho_db = config['database']['db']

obj = ConectarBanco.new(caminho_db)
#obj.script("SELECT ip FROM FILIAIS_IP where servidor=1")
obj.ping("SELECT ip FROM FILIAIS_IP where servidor=1 ORDER BY COD_FILIAL")
obj.fechar_conexao
