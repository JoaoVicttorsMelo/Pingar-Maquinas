require 'mail'
require 'yaml'

module EnviarEmail

  def enviar_email(titulo, corpo, informacao,informacao_complementar='')
    config_path = File.join(__dir__, 'config.yml')
    config = YAML.load_file(config_path)
    # Configuração do e-mail
    sender_email = config['smtp']['sender_email']
    receiver_emails = config['smtp']['receiver_emails']
    adress = config['smtp']['address']
    domain = config['smtp']['domain']

    # Configurações do servidor SMTP interno
    options = {
      address: adress,
      port: 25,
      domain: domain,
      authentication: nil,
      enable_starttls_auto: false
    }


    Mail.defaults do
      delivery_method :smtp, options
    end

    # Criando o e-mail com estilo e prioridade
    mail = Mail.new do
      from    sender_email
      to      receiver_emails.join(', ')
      subject titulo
      content_type 'text/html; charset=UTF-8'

      # Definir prioridade alta
      header['X-Priority'] = '1'
      header['X-MSMail-Priority'] = 'High'
      header['Importance'] = 'High'

      # Corpo do e-mail com HTML e estilo
      body    <<-HTML
  <html>
  <body>
    <H1 style="color: red;"><p><strong><center>#{corpo}</center></strong></p></H1>
    <H3><p"><center>#{informacao}</center></p></H3>
<H2><p"><center>#{informacao_complementar}</center></p></H2>
  </body>
  </html>
  HTML
    end
    # Enviando o e-mail
    mail.deliver!
  end
end
