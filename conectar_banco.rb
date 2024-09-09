require 'sqlite3'

class ConectarBanco
  def initialize(caminho_db = "C:/Users/joao.silveira/Desktop/Projetos_Programas/projeto_etl/Verificar_DashBoard/dist/Banco_Dados/comparacao.db")
    @banco = caminho_db
    conexao
  end

  def conexao
    begin
    @db= SQLite3::Database.new @banco
    rescue SQLite3::Exception => e
      puts e.message
    end
  end

  def fechar_conexao
    begin
      @db.clone if @db
      puts "Fechando conexão"
    end
  end

  def script (script)
    if comando_permitido(script)
      begin
        rows = @db.execute script
        i=0
        rows.each do |row|
          puts "#{i+=1} - #{row.join(" ")}"
        end
      rescue SQLite3::Exception => e
        puts e.message
      end
    else
      puts "Usuario não é capaz de fazer qualquer modificação, apenas consulta"
    end
  end

  def ping (script)
    if comando_permitido(script)
      begin
        rows = @db.execute script
        rows.each do |row|
           system("ping #{row.join(" ")}")
        end
      rescue SQLite3::Exception => e
        puts e.message
      end
    else
      puts "Usuario não é capaz de fazer qualquer modificação, apenas consulta"
    end
  end

  def comando_permitido(script)
    begin
      script.strip.downcase.start_with?('select')
    end
  end
end


