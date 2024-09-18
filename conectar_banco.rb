require 'sqlite3'
require_relative 'enviar_email'

class ConectarBanco
  include EnviarEmail
  def initialize(caminho_db)
    @banco = caminho_db
    abrir_conexao
  end
  def abrir_conexao
    @db = SQLite3::Database.new(@banco)
    puts "Conexão estabelecida com sucesso"
  rescue SQLite3::Exception => e
    puts "Erro ao estabelecer conexão: #{e.message}"
  end
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
  def script(script)
    executar_comando(script) do |rows|
      rows.each_with_index do |row, i|
        puts "#{i + 1} - #{row.join(' ')}"
      end
    end
  end
  def ping(script)
    ips_falhos = []
    executar_comando(script) do |rows|
      rows.each do |row|
        ip = row.join(' ')
        puts "Pingando IP: #{ip}"

        falhas = 0
        3.times do
          if system("ping -n 1 #{ip}")
            puts "#{ip} respondeu ao ping"
          else
            puts "#{ip} não respondeu ao ping"
            falhas += 1
          end
        end

        # Se falhar 2 ou mais vezes, adicionar à lista de IPs falhos
        if falhas >= 2
          puts "#{ip} falhou em 2 ou mais tentativas. Adicionando à lista de falhas."
          ips_falhos << ip
        else
          puts "#{ip} respondeu com sucesso ao menos 2 vezes."
        end
      end
    end

    # Mostrar os IPs que falharam
    if ips_falhos.any?
      # Formatar IPs para o SQL corretamente
      ip_list = ips_falhos.map { |ip| "'#{ip}'" }.join(', ')
      lojas_com_erro = []

      # Executar comando com WHERE IN para múltiplos IPs
      executar_comando("SELECT FILIAL, COD_FILIAL, CNPJ FROM filiais_ip WHERE IP IN (#{ip_list})") do |linhas|
        linhas.each do |linha|
          filial = linha[0]
          cod_filial = linha[1]
          cnpj = linha[2]
          info_formatada = "Filial - #{filial} - (#{cod_filial.to_s.rjust(6,'0')}) do CNPJ: #{cnpj}, favor verificar"

          # Adicionar a informação formatada ao array
          lojas_com_erro << info_formatada
        end
      end

      # Enviar o e-mail se houver lojas com erro
      if lojas_com_erro.any?
        receber_email = ["joao.silveira@viaveneto.com.br","ti.loja@viaveneto.com.br"]
        enviar_email("Lojas sem conexão com a Matriz", "FILIAIS COM ERRO", lojas_com_erro.join("<br>"),receber_email)
      end
    end
  end

  def executar_comando(script)
    if comando_permitido?(script)
      rows = @db.execute(script)
      yield(rows) if block_given?
    else
      puts "Usuário não é capaz de fazer qualquer modificação, apenas consulta"
    end
  rescue SQLite3::Exception => e
    puts "Erro ao executar o comando: #{e.message}"
  end
  def comando_permitido?(script)
    script.strip.downcase.start_with?('select')
  end
end

