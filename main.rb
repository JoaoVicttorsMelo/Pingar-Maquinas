require_relative 'classes/services'
require 'yaml'

config_path = File.join(__dir__, 'config.yml')
config = YAML.load_file(config_path)
caminho_db = config['database']['db']
obj = Services.new(caminho_db)
obj.ping
obj.fechar_conexao
