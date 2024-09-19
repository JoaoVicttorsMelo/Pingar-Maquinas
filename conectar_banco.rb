require 'sqlite3'
require_relative 'enviar_email'

# Classe para gerenciar a conexão com o banco de dados e enviar e-mails em caso de falhas.
class ConectarBanco
  include EnviarEmail # Inclui o módulo EnviarEmail para utilizar métodos relacionados ao envio de e-mails.

  # Método inicializador da classe. Recebe o caminho do banco de dados como argumento.
  def initialize(caminho_db)
    @banco = caminho_db
    abrir_conexao # Estabelece a conexão com o banco de dados assim que a classe é instanciada.
  end

  # Método para abrir a conexão com o banco de dados.
  def abrir_conexao
    @db = SQLite3::Database.new(@banco)
    puts "Conexão estabelecida com sucesso"
  rescue SQLite3::Exception => e
    puts "Erro ao estabelecer conexão: #{e.message}"
  end

  # Método para fechar a conexão com o banco de dados.
  def fechar_conexao
    if @db
      @db.close
      puts "Conexão fechada com sucesso"
    else
      puts "Nenhuma conexão ativa para fechar"
    end
  rescue SQLite3::Exception => e
    puts "Erro ao fechar a conexão: #{e.message}"
  end

  # Método genérico para executar scripts SQL e exibir resultados.
  # O script deve ser passado como argumento e precisa ser apenas de consulta (SELECT).
  def script(script)
    executar_comando(script) do |rows|
      rows.each_with_index do |row, i|
        puts "#{i + 1} - #{row.join(' ')}" # Exibe cada linha de resultado no formato "1 - valor1 valor2..."
      end
    end
  end

  # Método para realizar o ping em uma lista de IPs obtidos a partir do banco de dados.
  def ping(script)
    hora_atual = Time.now # Obtém a hora atual do sistema.
    # Define o intervalo de horário permitido para execução do ping.
    hora_inicio = Time.new(hora_atual.year, hora_atual.month, hora_atual.day, 00, 10, 0) # 10:30 AM
    hora_fim = Time.new(hora_atual.year, hora_atual.month, hora_atual.day, 21, 55, 0)    # 21:55 PM

    # Verifica se o horário atual está dentro do intervalo permitido.
    if hora_atual >= hora_inicio && hora_atual <= hora_fim

      contador=0
      loop do
        ips_falhos = [] # Array para armazenar IPs que falharam no ping.
        # Executa o comando SQL para obter a lista de IPs.
        executar_comando(script) do |rows|
          rows.each do |row|
            ip = row.join(' ') # Converte a linha do banco de dados em um IP.
            puts "Pingando IP: #{ip}"

            falhas = 0
            # Tenta pingar o IP 3 vezes para verificar conectividade.
            3.times do
              if system("ping -n 1 #{ip}") # Executa o comando ping no sistema.
                puts "#{ip} respondeu ao ping"
              else
                puts "#{ip} não respondeu ao ping"
                falhas += 1
              end
            end

            # Se falhar 2 ou mais vezes, adiciona o IP à lista de falhas.
            if falhas >= 2
              puts "#{ip} falhou em 2 ou mais tentativas. Adicionando à lista de falhas."
              ips_falhos << ip
            else
              puts "#{ip} respondeu com sucesso ao menos 2 vezes."
            end
          end
        end

        # Se houver IPs que falharam no ping, busca as informações dessas lojas no banco.
        if ips_falhos.any?
          # Converte a lista de IPs para uma string adequada para o comando SQL.
          ip_list = ips_falhos.map { |ip| "'#{ip}'" }.join(', ')
          lojas_com_erro = [] # Array para armazenar informações das lojas com erro.

          # Executa um comando SQL para buscar informações das filiais com base nos IPs falhos.
          executar_comando("SELECT FILIAL, COD_FILIAL, CNPJ FROM filiais_ip WHERE IP IN (#{ip_list})") do |linhas|
            linhas.each do |linha|
              filial = linha[0]
              cod_filial = linha[1]
              cnpj = linha[2]
              # Formata a mensagem para cada filial com erro.
              info_formatada = "Filial - #{filial} - (#{cod_filial.to_s.rjust(6, '0')}) do CNPJ: #{cnpj}, favor verificar"
              lojas_com_erro << info_formatada # Adiciona a informação formatada ao array.
            end
          end

          # Se houver informações de lojas com erro, envia um e-mail com os detalhes.
          unless contador < 25
            if lojas_com_erro.any?
              # Envia o e-mail utilizando o método enviar_email do módulo EnviarEmail.
              enviar_email("Lojas sem conexão com a Matriz", "FILIAIS COM ERRO", lojas_com_erro.join("<br>"))
              contador = 0
            end
          end
          contador+=1
        end
      end
    else
      # Caso o horário esteja fora do intervalo permitido, não executa o ping.
      puts "Sistema fora do horario de funcionamento"
    end
  end

  # Método para executar um comando SQL no banco de dados.
  # Verifica se o comando é permitido e, se sim, executa o comando e retorna os resultados.
  def executar_comando(script)
    if comando_permitido?(script) # Verifica se o comando é um SELECT.
      rows = @db.execute(script) # Executa o comando SQL.
      yield(rows) if block_given? # Passa as linhas do resultado para um bloco, se houver.
    else
      puts "Usuário não é capaz de fazer qualquer modificação, apenas consulta"
    end
  rescue SQLite3::Exception => e
    puts "Erro ao executar o comando: #{e.message}" # Exibe mensagem de erro em caso de falha na execução.
  end

  # Metodo para verificar se o comando SQL é permitido.
  # Apenas comandos que começam com 'SELECT' são permitidos.
  def comando_permitido?(script)
    script.strip.downcase.start_with?('select') # Verifica se o script começa com 'select'.
  end
end