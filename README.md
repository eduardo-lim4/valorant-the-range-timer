# Range Timer

Um cronômetro regressivo para treinar no The Range do VALORANT. A janela fica sobre as outras, pode ser arrastada e toca um alerta configurável quando o tempo acaba.

## Como baixar e executar

### Pelo GitHub (sem instalar Git)

1. Na página do repositório, clique em **Code** e depois em **Download ZIP**.
2. Extraia o ZIP baixado e abra a pasta extraída. Não execute os arquivos diretamente de dentro do ZIP.
3. Dê dois cliques em **Iniciar Range Timer.bat**. Mantenha `timer.ps1`, `RangeAudio.cs`, `RangeHotkeys.cs`, `RangeSpotify.ps1` e as pastas `images` e `spotify_overlay` juntos, na mesma pasta.

Se preferir usar Git, clone o repositório e execute o mesmo arquivo `.bat` dentro da pasta criada:

```powershell
git clone https://github.com/eduardo-lim4/valorant-the-range-timer.git
cd valorant-the-range-timer
.\'Iniciar Range Timer.bat'
```

Os arquivos `RangeTimer.zip` e `RangeTimer-com-sorteio.zip` são pacotes antigos, preservados para referência. Para usar o pacote pronto mais recente, extraia `RangeTimer-com-spotify.zip` antes de abrir o `.bat`; o **Download ZIP** do GitHub também contém o projeto completo.

### Usando o timer

1. Escolha os minutos, os segundos e a meta de bots. O tempo precisa ser maior que zero.
2. Clique em **Iniciar**. O timer entra automaticamente no modo compacto, mostrando o tempo, a meta e o estado do treino.
3. Clique em **Abrir** para voltar à tela completa e acessar **Pausar**, **Continuar** e **Reiniciar**. Você também pode usar **Compacto** para reduzir a janela a qualquer momento, sem alterar a contagem.
4. Arraste a janela pelo cabeçalho ou pelo visor para posicioná-la. Clique em **X** para fechar.

A meta de bots é apenas uma referência visual: o aplicativo não detecta eliminações nem se conecta ao jogo. O cronômetro termina quando o tempo chega a zero, independentemente da quantidade de bots eliminados.

## Spotify

Abra o aplicativo Spotify para Windows e comece a tocar uma música. Clique em **Música** no timer, mesmo no modo compacto, para mostrar ou ocultar o painel com título, artista, capa, progresso e os botões de reprodução, faixa anterior e próxima. Os botões usam os ícones da pasta `spotify_overlay`, repintados nas cores do tema; desabilitados, eles aparecem apagados. Sem esses arquivos, os botões continuam funcionando com texto. A barra mostra o progresso, mas não permite avançar para um ponto da música. O timer continua funcionando normalmente.

O painel usa a sessão de mídia disponibilizada pelo próprio Windows; não precisa de senha, chave de API ou configuração de conta. É necessário Windows 10 versão 1809 ou mais recente, ou Windows 11. A integração depende dos dados e controles que o Spotify disponibiliza ao Windows: se uma capa, duração ou comando não estiver disponível, o painel não conseguirá exibi-lo ou utilizá-lo. O Spotify no navegador e a reprodução em outros dispositivos não são garantidos. Se nada aparecer, abra o Spotify no computador e inicie uma faixa.

## Sorteio de treino

Clique em **Sorteio** na janela normal ou compacta para sortear um agente, uma arma ou ambos. Cada sorteio é independente e pode repetir resultados; o cronômetro continua funcionando com o menu aberto.

As imagens ficam em `images`: arquivos de armas começam com `weapon_`, e os demais são agentes. O programa lê PNG, JPG, JPEG e BMP; as imagens WebP originais foram preservadas e possuem cópias PNG em `images\compatibles`, necessárias para o sorteio. Para adicionar uma imagem, use um desses formatos compatíveis e siga a mesma convenção de nomes.

## Som do alerta

Clique em **Som**, inclusive no modo compacto, para ajustar o volume, testar o alerta ou importar um arquivo. Use **Som padrão** para voltar ao alerta original. O cronômetro continua funcionando enquanto o menu está aberto.

O formato aceito é **WAV PCM de 16 bits**, mono ou estéreo, entre 8 e 192 kHz, com até 30 segundos e 10 MB. Nem todo arquivo `.wav` usa esse formato; se necessário, converta-o para WAV PCM de 16 bits. O volume em 0% silencia o alerta e também depende do volume do Windows.

O aplicativo guarda o volume e uma cópia do som importado em `%LOCALAPPDATA%\RangeTimer`, para reutilizá-los na próxima abertura.

## Atalhos de teclado

Clique em **Teclas** na janela normal ou compacta. Clique no campo de uma ação e pressione uma tecla ou uma combinação com Ctrl, Alt e/ou Shift. O botão **X** ao lado remove o atalho. Você pode configurar iniciar/continuar, pausar, reiniciar e alternar entre os modos compacto e completo. Inicialmente, nenhuma tecla está atribuída.

Os atalhos são globais enquanto o aplicativo está aberto e ficam suspensos durante a configuração. Uma tecla reservada globalmente pode deixar de funcionar no jogo e em outros programas: prefira combinações que não conflitem com os controles do VALORANT. O Windows não permite algumas teclas ou combinações, como F12; combinações com a tecla Windows e modificadores isolados também não são aceitos. Quando outro programa já usa um atalho, escolha outro. A disponibilidade dos atalhos sobre o jogo depende do Windows, do modo de exibição e das permissões dos aplicativos; teste na sua máquina.

As escolhas são salvas em `%LOCALAPPDATA%\RangeTimer\hotkeys.json`. Se um atalho salvo estiver indisponível ao abrir o aplicativo, ele avisará e manterá a configuração para que você possa alterá-la.

## Requisitos e dicas

- Windows com Windows PowerShell 5.1 e Windows Forms, normalmente já incluídos no sistema. Não é necessário instalar Python ou outras dependências.
- Para visualizar a janela durante a partida, use o VALORANT em **modo janela sem bordas**. Janelas sempre no topo podem não aparecer sobre jogos em tela cheia exclusiva.
- Confira o volume e o dispositivo de saída do Windows se não ouvir o aviso.
- O overlay recebe cliques normalmente; posicione-o onde não atrapalhe os controles do jogo. Ele não modifica nem injeta código no VALORANT.

O arquivo `.bat` usa `-ExecutionPolicy Bypass` somente para o processo que inicia o timer; ele não altera a política de execução permanente do Windows.
