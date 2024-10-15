require 'active_record'

module ConexaoBanco
  def self.parametros(banco)
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: banco
    )
  end

  def self.todos_os_ips
    FiliaisIp.all.map(&:ip)
  end


end
