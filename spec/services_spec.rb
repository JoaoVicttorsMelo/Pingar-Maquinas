require_relative '../classes/services'
require 'rspec'


RSpec.describe Services do
  let(:service) { Services.new('caminho_para_o_banco') }  # Instancia a classe Services
  describe '#pingar_ips' do
    # Simula falha completa (3 falhas)
    it 'retorna o IP se falhar 3 vezes' do
      allow(service).to receive(:system).and_return(false)
      expect(service.pingar_ips('192.168.0.1')).to eq(['192.168.0.1'])
    end

    # Simula 2 falhas e 1 sucesso
    it 'retorna o IP se falhar 2 vezes' do
      allow(service).to receive(:system).and_return(false, false, true)
      expect(service.pingar_ips('192.168.0.2')).to eq(['192.168.0.2'])
    end

    # Simula 1 falha e 2 sucessos
    it 'não retorna o IP se falhar menos de 2 vezes' do
      allow(service).to receive(:system).and_return(false, true, true)
      expect(service.pingar_ips('192.168.0.3')).to eq([])
    end

    # Simula sucesso total (3 sucessos)
    it 'não retorna o IP se for bem-sucedido em todos os pings' do
      allow(service).to receive(:system).and_return(true)
      expect(service.pingar_ips('192.168.0.4')).to eq([])
    end
  end

  describe '#horario_permitido?' do
    it 'retorna true se a hora estiver dentro do intervalo permitido' do
      hora = Time.new(2024, 10, 15, 10, 0, 0)  # 10:00 está dentro do intervalo
      expect(service.horario_permitido?(hora)).to be true
    end

    it 'retorna false se a hora for antes do horário permitido' do
      hora = Time.new(2024, 10, 15, 8, 0, 0)  # 08:00 está fora do intervalo (antes)
      expect(service.horario_permitido?(hora)).to be false
    end

    it 'retorna false se a hora for após o horário permitido' do
      hora = Time.new(2024, 10, 15, 22, 0, 0)  # 22:00 está fora do intervalo (depois)
      expect(service.horario_permitido?(hora)).to be false
    end

    it 'retorna true se a hora estiver no limite superior do intervalo' do
      hora = Time.new(2024, 10, 15, 21, 55, 0)  # 21:55 é o limite superior do intervalo
      expect(service.horario_permitido?(hora)).to be true
    end

    it 'retorna true se a hora estiver no limite inferior do intervalo' do
      hora = Time.new(2024, 10, 15, 9, 30, 0)  # 09:30 é o limite inferior do intervalo
      expect(service.horario_permitido?(hora)).to be true
    end
  end

end