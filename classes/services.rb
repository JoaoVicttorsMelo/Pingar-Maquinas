require 'sqlite3'
require 'logger'
require 'fileutils'
require_relative 'filial_ip'  # Model para acessar a tabela filiais_ip
require_relative '../lib/conexao_banco'  # Módulo para gerenciar a conexão com o banco de dados
require_relative '../lib/enviar_email'  # Módulo para enviar e-mails

# Classe Services para gerenciar conexão com o banco, pings em IPs e envio de e-mails.
class Services
  include EnviarEmail # Métodos relacionados ao envio de e-mails.
  include ConexaoBanco # Gerenciamento de conexão com banco de dados.

  # Inicializa o serviço, configura o logger e abre conexão com o banco.
  def initialize(caminho_db)
    setup_logger
    @banco = caminho_db
    abrir_conexao
  end

  # Estabelece a conexão com o banco e faz logging
  def abrir_conexao
    ConexaoBanco.parametros(@banco)
    @logger.info "Conexão estabelecida com sucesso"
  rescue SQLite3::Exception => e
    @logger.error "Erro ao abrir conexão: #{e.message}"
    retry_connection(e) # Tenta reconectar em caso de erro.
  end

  # Reexecuta tentativa de conexão após falha.
  def retry_connection(e)
    @logger.error "Erro ao estabelecer conexão: #{e.message}"
    sleep(5)
    abrir_conexao
  end

  private

  # Configura o logger e cria o arquivo de log se necessário.
  def setup_logger
    project_root = File.expand_path(File.join(__dir__, '../pingar_maquinas'))
    log_dir = File.join(project_root, 'log')
    @log_file = File.join(log_dir, 'database.log')

    ensure_log_file_exists

    @logger = Logger.new(@log_file)
    @logger.level = Logger::INFO
    @logger.info("Logger iniciado com sucesso")
  rescue StandardError => e
    p "Erro ao configurar logger: #{e.message}"
    p "Stacktrace: #{e.backtrace.join("\n")}"
    @logger = Logger.new(STDOUT)
  end

  # Verifica se o arquivo de log existe e é gravável.
  def ensure_log_file_exists
    FileUtils.mkdir_p(File.dirname(@log_file))
    FileUtils.touch(@log_file) unless File.exist?(@log_file)
    raise "Arquivo de log não é gravável: #{@log_file}" unless File.writable?(@log_file)
  end

  # Verifica se a hora atual está dentro do intervalo permitido.
  def horario_permitido?(hora)
    hora_inicio = Time.new(hora.year, hora.month, hora.day, 9, 30, 0)
    hora_fim = Time.new(hora.year, hora.month, hora.day, 21, 55, 0)
    hora >= hora_inicio && hora <= hora_fim
  end

  # Pinga um IP três vezes e retorna o IP caso falhe duas ou mais vezes.
  def pingar_ips(ip)
    falhas = 3.times.count { !system("ping -n 1 #{ip}") }
    falhas >= 2 ? [ip] : []
  end

  public

  # Realiza o ping dos IPs das filiais, registra falhas e envia e-mails.
  def ping
    hora_atual = Time.now
    loop do
      if horario_permitido?(hora_atual)
        lojas_com_erro = []
        ips = FiliaisIp.where(servidor: 1).select(:ip, :filial, :cod_filial, :cnpj)

        ips.each do |linhas|
          # Acessa as colunas corretamente
          ip = linhas.IP
          filial = linhas.FILIAL
          cod_filial = linhas.COD_FILIAL
          cnpj = linhas.CNPJ

          # Pinga o IP e registra falhas
          ips_falhos = pingar_ips(ip)
          if ips_falhos.any?
            info_formatada = "Filial - #{filial} - (#{cod_filial.to_s.rjust(6, '0')}) do CNPJ: #{cnpj}, IP pingado: #{ip}, favor verificar VPN/Internet"
            lojas_com_erro << info_formatada
          end
        end

        # Envia e-mail se houver lojas com erro
        enviar_email_lojas_com_erro(lojas_com_erro) unless lojas_com_erro.empty?
      else
        @logger.info "Sistema fora do horário de funcionamento."
        sleep(360)
      end
      sleep(360) # Pausa entre cada execução do loop.
    end
  end

  # Envia um e-mail com as lojas que apresentaram falhas no ping.
  def enviar_email_lojas_com_erro(lojas_com_erro)
    if lojas_com_erro.any?
      enviar_email("Lojas sem conexão com a Matriz", "FILIAIS COM ERRO", lojas_com_erro.join("<br>"))
    else
      enviar_email("Lojas com conexão na Matriz", "Nenhuma loja esta com o servidor ser rede/sem VPN")
    end
  end
end
