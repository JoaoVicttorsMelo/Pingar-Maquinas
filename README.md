<div align="center">
  <h1>🔌Gerenciamento de Conexão e Envio de E-mails</h1>
  <img src="https://img.shields.io/badge/Ruby-2.7%2B-red" alt="Ruby Version">
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License">
  <img src="https://img.shields.io/badge/Status-Finalizado-green" alt="Status">
</div>

<div>
  <h2>📝 Descrição</h2>
  <p><strong>ConectarBanco</strong> é uma aplicação em Ruby que gerencia a conexão com bancos de dados SQLite, executa comandos SQL de consulta e envia e-mails de notificação em caso de falhas. O sistema também realiza o monitoramento de conexões, verificando problemas com IPs de filiais e reportando através de e-mails automatizados.</p>
</div>

<div>
  <h2>🚀 Funcionalidades</h2>
  <ul>
    <li>🔗 <strong>Conexão com Bancos de Dados</strong>: Conecta-se aos bancos de dados SQLite e executa comandos SQL.</li>
    <li>📝 <strong>Execução de Scripts SQL</strong>: Executa consultas SQL seguras nas bases de dados e retorna os resultados.</li>
    <li>✉️ <strong>Envio de E-mails</strong>: Envia e-mails em caso de falha na conexão ou quando ocorre um erro de comunicação entre sistemas.</li>
    <li>⏰ <strong>Monitoramento de IPs</strong>: Monitora IPs de lojas, realiza ping e identifica falhas de conexão, enviando relatórios das filiais com problemas.</li>
    <li>📄 <strong>Geração de Logs</strong>: Gera logs detalhados das atividades de conexão e execução de comandos SQL.</li>
    <li>🔄 <strong>Reconexão Automática</strong>: Tenta reconectar automaticamente ao banco de dados em caso de falha de conexão.</li>
    <li>📧 <strong>Envio de E-mails Automatizado para IPs Falhos</strong>: Identifica IPs que falharam em múltiplos pings e envia e-mails com informações detalhadas sobre as lojas afetadas.</li>
    <li>🕒 <strong>Verificação de Horário</strong>: A execução do monitoramento e envio de e-mails ocorre apenas em horários permitidos (das 09:30 às 21:55).</li>
    <li>🛠️ <strong>Teste Unitário</strong>: Funções implementadas com suporte a testes unitários utilizando RSpec para validação de funcionalidades críticas como envio de e-mails, ping de IPs e verificação de horário permitido.</li>
  </ul>
</div>

<div>
  <h2>🛠️ Tecnologias Utilizadas</h2>
  <ul>
    <li><strong>Linguagem</strong>: <img src="https://img.shields.io/badge/-Ruby-red" alt="Ruby"> Ruby 2.7+</li>
    <li><strong>Banco de Dados</strong>: SQLite</li>
    <li><strong>Gems Utilizadas</strong>:
      <ul>
        <li><code>sqlite3</code>: Interação com o banco de dados SQLite.</li>
        <li><code>logger</code>: Gerenciamento de logs.</li>
        <li><code>fileutils</code>: Manipulação de arquivos e diretórios.</li>
        <li><code>net/smtp</code>: Envio de e-mails via SMTP.</li>
        <li><code>rspec</code>: Framework de testes para Ruby.</li>
      </ul>
    </li>
  </ul>
</div>

<div>
  <h2>📋 Pré-requisitos</h2>
  <ul>
    <li>Ruby instalado na versão 2.7 ou superior.</li>
    <li>Acesso ao banco de dados SQLite.</li>
    <li>Configuração do arquivo <code>config.yml</code> com as informações de conexão e do servidor SMTP.</li>
  </ul>
</div>

<div>
  <h2>🔧 Instalação</h2>
  <ol>
    <li><p><strong>Clone o repositório</strong>:</p>
      <pre><code>git clone https://github.com/JoaoVicttorsMelo/ConectarBanco.git</code></pre>
    </li>
    <li><p><strong>Instale as dependências</strong>:</p>
      <pre><code>bundle install</code></pre>
    </li>
    <li><p><strong>Configure o arquivo <code>config.yml</code></strong>:</p>
      <pre><code>
database: caminho_para_o_banco.db
email_config:
  smtp_server: 'smtp.seuprovedor.com'
  port: 587
  username: 'seu_usuario'
  password: 'sua_senha'
      </code></pre>
    </li>
  </ol>
</div>

<div>
  <h2>🚀 Uso</h2>
  <ol>
    <li><p><strong>Executando o Script Principal</strong>:</p>
      <pre><code>ruby main.rb</code></pre>
    </li>
  </ol>
</div>

<div>
  <h2>🗂️ Estrutura do Projeto</h2>
  <pre><code>
conectar_banco/
├── config.yml
├── main.rb 
├── classes/
     └── services.rb
     └── filial_ip.rb
├── lib/
     └──conexao_banco.rb
     └──enviar_email.rb
├── spec/
│   └── services_spec.rb
├── log/
├── Gemfile
├── .rspec
└── README.md
  </code></pre>
</div>

<div>
  <h2>🤝 Contribuição</h2>
  <ol>
    <li>Faça um <strong>fork</strong> do projeto.</li>
    <li>Crie uma nova branch: <code>git checkout -b feature/nova-funcionalidade</code>.</li>
    <li>Commit suas alterações: <code>git commit -m 'Adiciona nova funcionalidade'</code>.</li>
    <li>Faça um push para a branch: <code>git push origin feature/nova-funcionalidade</code>.</li>
    <li>Abra um <strong>pull request</strong>.</li>
  </ol>
</div>

<div>
  <h2>📄 Licença</h2>
  <p>Este projeto está sob a licença <a href="LICENSE">MIT</a>.</p>
</div>

<div>
  <h2>📞 Contato</h2>
  <p>✉️ Email: <a href="mailto:joaovicttorsilveiramelo@gmail.com">joaovicttorsilveiramelo@gmail.com</a></p>
</div>
