require 'sqlite3'
require 'logger'
require 'fileutils'
require_relative 'enviar_email'

# Classe para gerenciar a conexão com o banco de dados e enviar e-mails em caso de falhas.
class ConectarBanco
  include EnviarEmail # Inclui o módulo EnviarEmail para utilizar métodos relacionados ao envio de e-mails.

  # Método inicializador da classe. Recebe o caminho do banco de dados como argumento.
  def initialize(caminho_db)
    setup_logger
    @banco = caminho_db
    abrir_conexao # Estabelece a conexão com o banco de dados assim que a classe é instanciada.
  end

  # Método para abrir a conexão com o banco de dados.
  def abrir_conexao
    @db = SQLite3::Database.new(@banco)
    @logger.info "Conexão estabelecida com sucesso"
  rescue SQLite3::Exception => e
    @logger.error "Erro ao estabelecer conexão: #{e.message}"
  end

  # Método para fechar a conexão com o banco de dados.
  def fechar_conexao
    return unless @db
    @db.close
    @logger.info "Conexão fechada com sucesso"
  rescue SQLite3::Exception => e
    @logger.error "Erro ao fechar a conexão: #{e.message}"
  ensure
    @db = nil
  end



  # Método genérico para executar scripts SQL e exibir resultados.
  # O script deve ser passado como argumento e precisa ser apenas de consulta (SELECT).
  def script(script)
    executar_comando(script) do |rows|
      rows.each_with_index do |row, i|
        @logger.info "#{i + 1} - #{row.join(' ')}" # Exibe cada linha de resultado no formato "1 - valor1 valor2..."
      end
    end
  end

  private
  def setup_logger
    project_root = File.expand_path(File.join(__dir__, '../pingar_maquinas'))
    log_dir = File.join(project_root, 'log')
    @log_file = File.join(log_dir, 'database.log')

    ensure_log_file_exists

    @logger = Logger.new(@log_file)
    @logger.level = Logger::INFO

    # Teste inicial do logger
    @logger.info("Logger iniciado com sucesso")
  rescue StandardError => e
    p "Erro ao configurar logger: #{e.message}"
    p "Stacktrace: #{e.backtrace.join("\n")}"
    @logger = Logger.new(STDOUT)
  end

  def ensure_log_file_exists
    FileUtils.mkdir_p(File.dirname(@log_file))

    unless File.exist?(@log_file)
      FileUtils.touch(@log_file)
    end

    # Verifica se o arquivo é gravável
    unless File.writable?(@log_file)
      raise "Arquivo de log não é gravável: #{@log_file}"
    end
  end

  public
  # Metodo para realizar o ping em uma lista de IPs obtidos a partir do banco de dados.
  def ping(script)
    hora_atual = Time.now # Obtém a hora atual do sistema.

    # Define o intervalo de horário permitido para execução do ping.
    hora_inicio = Time.new(hora_atual.year, hora_atual.month, hora_atual.day, 10, 30, 0) # 00:00 AM
    hora_fim = Time.new(hora_atual.year, hora_atual.month, hora_atual.day, 21, 55, 0)    # 21:55 PM

    loop do
      # Verifica se o horário atual está dentro do intervalo permitido.
      if hora_atual >= hora_inicio && hora_atual <= hora_fim
        contador = 0
        ips_falhos = [] # Array para armazenar IPs que falharam no ping.

        # Executa o comando SQL para obter a lista de IPs.
        executar_comando(script) do |rows|
          rows.each do |row|
            ip = row.join(' ') # Converte a linha do banco de dados em um IP.

            # Verifica falhas no ping (3 tentativas).
            falhas = 3.times.count { !system("ping -n 1 #{ip}") }
            if falhas >= 2
              ips_falhos << ip
            end
          end
        end

        # Se houver IPs que falharam no ping, busca as informações dessas lojas no banco.
        if ips_falhos.any?
          # Converte a lista de IPs para uma string adequada para o comando SQL.
          ip_list = ips_falhos.map { |ip| "'#{(ip)}'" }.join(', ')

          lojas_com_erro = [] # Array para armazenar informações das lojas com erro.

          # Executa um comando SQL para buscar informações das filiais com base nos IPs falhos.
          executar_comando("SELECT FILIAL, COD_FILIAL, CNPJ, IP FROM filiais_ip WHERE IP IN (#{ip_list})") do |linhas|
            linhas.each do |linha|
              filial = linha[0]
              cod_filial = linha[1]
              cnpj = linha[2]
              ip = linha[3]

              # Formata a mensagem para cada filial com erro.
              info_formatada = "Filial - #{filial} - (#{cod_filial.to_s.rjust(6, '0')}) do CNPJ: #{cnpj}, IP pingado: #{ip}, favor verificar VPN/Internet"
              lojas_com_erro << info_formatada # Adiciona a informação formatada ao array.
            end
          end
          contador+=1

          # Se houver informações de lojas com erro, envia um e-mail com os detalhes.
          unless contador < 25
            enviar_email_lojas_com_erro(lojas_com_erro)
            contador = 0
          end
        end
      else
        # Se o horário estiver fora do intervalo permitido, calcule o tempo de espera até o próximo ciclo.
        if hora_atual < hora_inicio
          # Estamos antes do horário permitido no mesmo dia
          tempo_espera = hora_inicio - hora_atual
        else
          # Estamos após o horário permitido; espera até o próximo dia
          hora_proximo_inicio = Time.new(hora_atual.year, hora_atual.month, hora_atual.day + 1, 00, 00, 0)
          tempo_espera = hora_proximo_inicio - hora_atual
        end

        # Converte o tempo de espera em horas e minutos
        horas = (tempo_espera / 3600).to_i # 1 hora = 3600 segundos
        minutos = ((tempo_espera % 3600) / 60).to_i # Resto de segundos convertido para minutos

        @logger.info "Sistema fora do horário de funcionamento. Esperando #{horas}:#{minutos}hr até o próximo horário permitido..."
        sleep(tempo_espera) # Pausa a execução até o horário permitido.
      end
    end
  end


  # Método para executar um comando SQL no banco de dados.
  # Verifica se o comando é permitido e, se sim, executa o comando e retorna os resultados.
  def executar_comando(script)
    if comando_permitido?(script) # Verifica se o comando é um SELECT.
      rows = @db.execute(script) # Executa o comando SQL.
      yield(rows) if block_given? # Passa as linhas do resultado para um bloco, se houver.
    else
      @logger.info "Usuário não é capaz de fazer qualquer modificação, apenas consulta"
    end
  rescue SQLite3::Exception => e
    @logger.error "Erro ao executar o comando: #{e.message}" # Exibe mensagem de erro em caso de falha na execução.
  end

  # Metodo para verificar se o comando SQL é permitido.
  # Apenas comandos que começam com 'SELECT' são permitidos.
  def comando_permitido?(script)
    script.strip.downcase.start_with?('select') # Verifica se o script começa com 'select'.
  end


  def ip_gateway_increment(ip)
    partes_ip = ip.split(".")
    ultimo_numero = partes_ip[-1].to_i + 1
    partes_ip[-1] = ultimo_numero.to_s
    partes_ip.join(".")
  end
  def enviar_email_lojas_com_erro(lojas_com_erro)
    if lojas_com_erro.any?
      enviar_email("Lojas sem conexão com a Matriz", "FILIAIS COM ERRO", lojas_com_erro.join("<br>"))
    end
  end

end