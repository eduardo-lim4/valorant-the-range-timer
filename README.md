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

## Desafios aleatórios

Clique em **Desafios**, na janela normal ou compacta, e use **Sortear desafio** para receber qualquer regra ou escolha uma das quatro categorias para um treino direcionado:

- **Mira e crosshair:** Só headshot, em que eliminações sem headshot não contam; ou Flick, para treinar o giro rápido de câmera e o microajuste.
- **Controle de arma:** Tap ou burst de no máximo 3 balas; ou Somente pistola, com Sheriff, Classic, Bandit ou Ghost.
- **Movimento:** Counter-strafe obrigatório, sem atirar andando; ou Peek e recuo, voltando ao cover antes do próximo bot.
- **Pressão de tempo:** eliminar 50 bots em 2 minutos ou 100 bots em 4 minutos.

Sortear e visualizar uma regra não alteram o timer. Depois de escolher, clique em **Estou pronto** e confirme: somente então o desafio começa e a janela entra no modo compacto. Os desafios comuns usam o tempo e a meta já configurados; os desafios de pressão aplicam seus próprios valores somente após essa confirmação.

**Pausar** preserva o desafio. **Reiniciar**, abandonar pelo botão **Desafio** ou fechar o aplicativo durante um desafio exige outra confirmação; ao recusar, o treino continua preservado. O aplicativo não detecta headshots, tiros, movimento ou eliminações: o cumprimento da regra é controlado pelo próprio jogador.

## Modos de interface

A barra inferior permanece visível em todos os modos para alternar rapidamente entre **Padrão**, **Competitivo** e **Custom**. O botão **Janela** também fica disponível nessa barra:

- **Padrão** mantém a interface completa e as cores originais.
- **Competitivo** mostra apenas o cronômetro, a meta de bots, o botão de fechar e a barra de modos.
- **Custom** permite definir as cores RGB do fundo e dos detalhes pelo botão **Cores**. A prévia atualiza enquanto você ajusta os valores; **Aplicar** confirma as cores.

Nos temas personalizados, as cores do texto e da superfície, incluindo o painel e os controles do Spotify, acompanham automaticamente a luminosidade do fundo. O modo e as cores ficam salvos em `%LOCALAPPDATA%\RangeTimer\theme.json`. Competitivo usa as cores padrão; Custom é o modo que aplica a paleta escolhida. Se o antigo modo Clean estiver salvo, o aplicativo abre no Padrão.

### Compartilhar um tema

Em **Custom → Cores**, ajuste o fundo e os detalhes e clique em **Copiar código**. O código das duas cores vai para a área de transferência e pode ser enviado aos amigos, mesmo antes de aplicar a alteração. O formato é `#RRGGBB / #RRGGBB`, com o fundo primeiro e o detalhe depois; por exemplo, `#0F1E3C / #22D3EE`.

Para importar, copie o código recebido, abra **Custom → Cores** e clique em **Colar código**. Confira a prévia e clique em **Aplicar** para salvar as cores, ou em **Cancelar** para mantê-las como estavam. O código compartilha somente as cores, não a opacidade nem o tamanho da janela.

## Opacidade e tamanho da janela

Clique em **Janela** para ajustar a opacidade de 30% a 100% e o tamanho proporcional de 80% a 150%. As mudanças aparecem na hora; clique em **Aplicar** para salvá-las ou em **Cancelar** para desfazê-las. A opacidade afeta toda a janela, incluindo texto e botões, e não apenas o fundo. A janela continua recebendo cliques.

Arraste o timer para posicioná-lo. Ao fechá-lo, o aplicativo guarda posição, tamanho, opacidade e estado compacto em `%LOCALAPPDATA%\RangeTimer\window.json` e os restaura na próxima abertura. Se o monitor salvo não estiver mais disponível, a janela volta para uma área visível.

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
