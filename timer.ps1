# Carrega os componentes de interface e desenho disponíveis no Windows.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -Path (Join-Path $PSScriptRoot 'RangeAudio.cs')
Add-Type -Path (Join-Path $PSScriptRoot 'RangeHotkeys.cs') -ReferencedAssemblies System.Windows.Forms, System.Drawing -ErrorAction Stop
. (Join-Path $PSScriptRoot 'RangeSpotify.ps1')

[System.Windows.Forms.Application]::EnableVisualStyles()

# Define as cores e a fonte usadas em toda a interface.
# A paleta padrao e fixa; os modos de interface re aplicam as cores depois da criacao.
$defaultBackground = [System.Drawing.Color]::FromArgb(16, 23, 31)
$defaultAccent = [System.Drawing.Color]::FromArgb(255, 70, 85)
$background = $defaultBackground
$surface = [System.Drawing.Color]::FromArgb(28, 37, 47)
$foreground = [System.Drawing.Color]::FromArgb(236, 232, 225)
$muted = [System.Drawing.Color]::FromArgb(151, 162, 171)
$accent = $defaultAccent
$fontFamily = 'Segoe UI'

# Cria a janela sem bordas, sempre no topo e no canto superior direito.
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Range Timer'
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.BackColor = $background
$form.ClientSize = New-Object System.Drawing.Size(372, 254)
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.TopMost = $true
$form.ShowInTaskbar = $true
$form.KeyPreview = $true
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$form.Location = New-Object System.Drawing.Point(($screen.Right - $form.Width - 24), ($screen.Top + 24))

# Estas funções criam controles com o mesmo estilo e os adicionam à janela.
function Add-Label {
    param($Text, $X, $Y, $Width, $Height, $Size, $Color, $Style = [System.Drawing.FontStyle]::Regular)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.Font = New-Object System.Drawing.Font($fontFamily, $Size, $Style)
    $label.ForeColor = $Color
    $label.BackColor = $background
    $form.Controls.Add($label)
    return $label
}

function Add-Button {
    param($Text, $X, $Y, $Width, $BackColor, $ForeColor)
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.Size = New-Object System.Drawing.Size($Width, 33)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.BackColor = $BackColor
    $button.ForeColor = $ForeColor
    $button.Font = New-Object System.Drawing.Font($fontFamily, 9, [System.Drawing.FontStyle]::Bold)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $form.Controls.Add($button)
    return $button
}

function Add-Number {
    param($X, $Maximum, $Value)
    $number = New-Object System.Windows.Forms.NumericUpDown
    $number.Location = New-Object System.Drawing.Point($X, 165)
    $number.Size = New-Object System.Drawing.Size(100, 26)
    $number.Minimum = 0
    $number.Maximum = $Maximum
    $number.Value = $Value
    $number.BackColor = $surface
    $number.ForeColor = $foreground
    $number.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $number.Font = New-Object System.Drawing.Font($fontFamily, 10)
    $form.Controls.Add($number)
    return $number
}

# Monta o visor, os campos de configuração e os botões do overlay.
$brand = Add-Label 'RANGE / TIMER' 12 13 110 22 9 $foreground ([System.Drawing.FontStyle]::Bold)
$randomButton = Add-Button 'SORTEIO' 123 8 58 $background $muted
$randomButton.Font = New-Object System.Drawing.Font($fontFamily, 7, [System.Drawing.FontStyle]::Bold)
$hotkeyButton = Add-Button 'TECLAS' 181 8 52 $background $muted
$hotkeyButton.Font = New-Object System.Drawing.Font($fontFamily, 7, [System.Drawing.FontStyle]::Bold)
$soundButton = Add-Button 'SOM' 233 8 40 $background $muted
$soundButton.Font = New-Object System.Drawing.Font($fontFamily, 7, [System.Drawing.FontStyle]::Bold)
$compactButton = Add-Button 'COMPACTO' 273 8 68 $background $muted
$compactButton.Font = New-Object System.Drawing.Font($fontFamily, 7, [System.Drawing.FontStyle]::Bold)
$closeButton = Add-Button 'X' 345 8 24 $background $muted
$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.SetToolTip($compactButton, 'Alternar modo compacto')
$rule = New-Object System.Windows.Forms.Panel
$rule.Location = New-Object System.Drawing.Point(18, 43)
$rule.Size = New-Object System.Drawing.Size(336, 2)
$rule.BackColor = $accent
$form.Controls.Add($rule)

$timeLabel = Add-Label '05:00' 15 51 220 58 34 $foreground ([System.Drawing.FontStyle]::Bold)
$statusLabel = Add-Label 'PRONTO PARA TREINAR' 20 111 230 19 8 $muted ([System.Drawing.FontStyle]::Bold)
$botsLabel = Add-Label '100 BOTS' 246 70 108 25 12 $accent ([System.Drawing.FontStyle]::Bold)
$botsLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$musicButton = Add-Button 'MUSICA' 262 105 92 $background $muted
$musicButton.Font = New-Object System.Drawing.Font($fontFamily, 8, [System.Drawing.FontStyle]::Bold)
$toolTip.SetToolTip($musicButton, 'Mostrar ou ocultar o Spotify')

$minutesLabel = Add-Label 'MINUTOS' 19 145 100 17 8 $muted ([System.Drawing.FontStyle]::Bold)
$secondsLabel = Add-Label 'SEGUNDOS' 136 145 100 17 8 $muted ([System.Drawing.FontStyle]::Bold)
$targetLabel = Add-Label 'META DE BOTS' 253 145 105 17 8 $muted ([System.Drawing.FontStyle]::Bold)
$minutesInput = Add-Number 19 999 5
$secondsInput = Add-Number 136 59 0
$botsInput = Add-Number 253 9999 100
$botsInput.Minimum = 1

$startButton = Add-Button 'INICIAR' 19 205 160 $accent $foreground
$resetButton = Add-Button 'REINICIAR' 188 205 165 $surface $foreground

# O Stopwatch mede o tempo decorrido; o Timer da interface apenas atualiza o visor.
# As variáveis em script: são compartilhadas pelos eventos dos controles.
$script:clock = [System.Diagnostics.Stopwatch]::new()
$script:duration = 300.0
$script:finished = $false
$script:dragging = $false
$script:dragOffset = [System.Drawing.Point]::Empty
$script:compact = $false
$regularTimeFont = $timeLabel.Font
$regularBotsFont = $botsLabel.Font
$regularBrandFont = $brand.Font
$compactBrandFont = New-Object System.Drawing.Font($fontFamily, 8, [System.Drawing.FontStyle]::Bold)
$compactTimeFont = New-Object System.Drawing.Font($fontFamily, 26, [System.Drawing.FontStyle]::Bold)
$compactBotsFont = New-Object System.Drawing.Font($fontFamily, 9, [System.Drawing.FontStyle]::Bold)
$regularCloseFont = $closeButton.Font
$minimalCloseFont = New-Object System.Drawing.Font($fontFamily, 7, [System.Drawing.FontStyle]::Bold)
$settingsControls = @($minutesLabel, $secondsLabel, $targetLabel, $minutesInput, $secondsInput, $botsInput, $startButton, $resetButton)

# O painel de música é opcional e permanece disponível também no modo compacto.
$script:musicVisible = $false
$script:spotify = $null
$script:shownArtworkKey = ''
$musicPanel = New-Object System.Windows.Forms.Panel
$musicPanel.Location = New-Object System.Drawing.Point(0, 254)
$musicPanel.Size = New-Object System.Drawing.Size(264, 146)
$musicPanel.BackColor = $surface
$musicPanel.Visible = $false
$form.Controls.Add($musicPanel)

function Add-MusicLabel {
    param($Text, $X, $Y, $Width, $Height, $Size, $Color)
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($Width, $Height)
    $label.Font = New-Object System.Drawing.Font($fontFamily, $Size)
    $label.ForeColor = $Color
    $label.AutoEllipsis = $true
    $musicPanel.Controls.Add($label)
    return $label
}
function Add-MusicButton {
    param($Text, $X, $Width)
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, 110)
    $button.Size = New-Object System.Drawing.Size($Width, 27)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.BackColor = $background
    $button.ForeColor = $foreground
    $button.Font = New-Object System.Drawing.Font($fontFamily, 7, [System.Drawing.FontStyle]::Bold)
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $musicPanel.Controls.Add($button)
    return $button
}
$musicHeaderLabel = Add-MusicLabel 'TOCANDO AGORA / SPOTIFY' 10 5 240 18 8 $accent
$musicCover = New-Object System.Windows.Forms.PictureBox
$musicCover.Location = New-Object System.Drawing.Point(10, 27)
$musicCover.Size = New-Object System.Drawing.Size(54, 54)
$musicCover.BackColor = $background
$musicCover.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$musicPanel.Controls.Add($musicCover)
$musicTitle = Add-MusicLabel 'Abra o Spotify no computador' 72 27 180 20 9 $foreground
$musicArtist = Add-MusicLabel 'Aguardando reproducao...' 72 48 180 18 8 $muted
$musicProgress = New-Object System.Windows.Forms.ProgressBar
$musicProgress.Location = New-Object System.Drawing.Point(72, 72)
$musicProgress.Size = New-Object System.Drawing.Size(180, 7)
$musicProgress.Maximum = 1000
$musicPanel.Controls.Add($musicProgress)
$musicTime = Add-MusicLabel '--:-- / --:--' 72 82 180 18 8 $muted
# Carrega um icone da pasta spotify_overlay, redimensiona e repinta na cor pedida,
# preservando a transparencia original do arquivo.
function New-MusicIcon {
    param([string]$FileName, [System.Drawing.Color]$Color)
    $path = Join-Path (Join-Path $PSScriptRoot 'spotify_overlay') $FileName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try {
        $source = [System.Drawing.Image]::FromFile($path)
        try {
            $icon = New-Object System.Drawing.Bitmap 22, 22
            $graphics = [System.Drawing.Graphics]::FromImage($icon)
            try {
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.DrawImage($source, 0, 0, 22, 22)
            } finally { $graphics.Dispose() }
            for ($x = 0; $x -lt 22; $x++) {
                for ($y = 0; $y -lt 22; $y++) {
                    $pixel = $icon.GetPixel($x, $y)
                    if ($pixel.A -gt 0) { $icon.SetPixel($x, $y, [System.Drawing.Color]::FromArgb($pixel.A, $Color)) }
                }
            }
            return $icon
        } finally { $source.Dispose() }
    } catch { return $null }
}

# Aplica o icone ao botao e guarda as duas versoes para alternar conforme o estado.
function Set-MusicButtonIcon {
    param($Button, $OnIcon, $OffIcon)
    if ($null -eq $OnIcon -or $null -eq $OffIcon) { return }
    $Button.Text = ''
    $Button.Image = if ($Button.Enabled) { $OnIcon } else { $OffIcon }
    $Button.Tag = @{ On = $OnIcon; Off = $OffIcon }
}

$previousTrack = Add-MusicButton 'ANTERIOR' 10 76
$playTrack = Add-MusicButton 'PLAY' 94 76
$nextTrack = Add-MusicButton 'PROXIMA' 178 76
[void]$toolTip.SetToolTip($previousTrack, 'Faixa anterior')
[void]$toolTip.SetToolTip($playTrack, 'Tocar ou pausar')
[void]$toolTip.SetToolTip($nextTrack, 'Proxima faixa')
# Sem os arquivos de icone os botoes continuam com texto, garantindo o funcionamento.
$previousTrack.AccessibleName = 'ANTERIOR'
$playTrack.AccessibleName = 'PLAY'
$nextTrack.AccessibleName = 'PROXIMA'
$script:musicIconImages = @(
    (New-MusicIcon 'backward.png' $foreground), (New-MusicIcon 'backward.png' $muted),
    (New-MusicIcon 'play-pause.png' $foreground), (New-MusicIcon 'play-pause.png' $muted),
    (New-MusicIcon 'forward.png' $foreground), (New-MusicIcon 'forward.png' $muted)
)
Set-MusicButtonIcon $previousTrack $script:musicIconImages[0] $script:musicIconImages[1]
Set-MusicButtonIcon $playTrack $script:musicIconImages[2] $script:musicIconImages[3]
Set-MusicButtonIcon $nextTrack $script:musicIconImages[4] $script:musicIconImages[5]
# A troca entre icone claro e apagado acompanha o estado do botao.
foreach ($button in @($previousTrack, $playTrack, $nextTrack)) {
    $button.Add_EnabledChanged({
        $icons = $this.Tag
        if ($icons) { $this.Image = if ($this.Enabled) { $icons.On } else { $icons.Off } }
    })
}

# A barra de modos fica sempre visivel, inclusive no modo competitivo, para permitir voltar ao padrao.
$script:uiMode = 'Padrao'
$script:customBackground = $defaultBackground
$script:customAccent = $defaultAccent
$modeBar = New-Object System.Windows.Forms.Panel
$modeBar.Location = New-Object System.Drawing.Point(0, 254)
$modeBar.Size = New-Object System.Drawing.Size(372, 28)
$modeBar.BackColor = $background
$form.Controls.Add($modeBar)
$modeButtonFontNormal = New-Object System.Drawing.Font($fontFamily, 7, [System.Drawing.FontStyle]::Bold)
$modeButtonFontCompact = New-Object System.Drawing.Font($fontFamily, 6, [System.Drawing.FontStyle]::Bold)

function Add-ModeButton {
    param($Text, $X, $Width)
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Location = New-Object System.Drawing.Point($X, 2)
    $button.Size = New-Object System.Drawing.Size($Width, 24)
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.BackColor = $background
    $button.ForeColor = $muted
    $button.Font = $modeButtonFontNormal
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $modeBar.Controls.Add($button)
    return $button
}
$padraoModeButton = Add-ModeButton 'PADRAO' 12 64
$cleanModeButton = Add-ModeButton 'CLEAN' 80 56
$competitivoModeButton = Add-ModeButton 'COMPETITIVO' 140 92
$customModeButton = Add-ModeButton 'CUSTOM' 236 72
$coresButton = Add-ModeButton 'CORES' 312 52
[void]$toolTip.SetToolTip($padraoModeButton, 'Aparencia padrao')
[void]$toolTip.SetToolTip($cleanModeButton, 'Fundo transparente')
[void]$toolTip.SetToolTip($competitivoModeButton, 'Somente timer e meta de bots')
[void]$toolTip.SetToolTip($customModeButton, 'Cores escolhidas por voce')
[void]$toolTip.SetToolTip($coresButton, 'Escolher as cores personalizadas')
$coresButton.Visible = $false
$padraoModeButton.Add_Click({ Set-UIMode 'Padrao' })
$cleanModeButton.Add_Click({ Set-UIMode 'Clean' })
$competitivoModeButton.Add_Click({ Set-UIMode 'Competitivo' })
$customModeButton.Add_Click({ Set-UIMode 'Customizado' })
$coresButton.Add_Click({ Show-ColorSettings })

# Calcula o brilho de uma cor para decidir se o texto deve ser claro ou escuro.
function Get-ColorLuminance {
    param([System.Drawing.Color]$Color)
    return (0.2126 * $Color.R + 0.7152 * $Color.G + 0.0722 * $Color.B) / 255
}

# Mistura uma cor na direcao de outra para derivar a superficie do tema.
function Shift-Color {
    param([System.Drawing.Color]$Color, [System.Drawing.Color]$Target, [double]$Amount)
    $r = [int][Math]::Round($Color.R + ($Target.R - $Color.R) * $Amount)
    $g = [int][Math]::Round($Color.G + ($Target.G - $Color.G) * $Amount)
    $b = [int][Math]::Round($Color.B + ($Target.B - $Color.B) * $Amount)
    return [System.Drawing.Color]::FromArgb($r, $g, $b)
}

# Recria os icones do Spotify com as cores do tema atual.
function Update-MusicIconTheme {
    $newIcons = @(
        (New-MusicIcon 'backward.png' $script:foreground), (New-MusicIcon 'backward.png' $script:muted),
        (New-MusicIcon 'play-pause.png' $script:foreground), (New-MusicIcon 'play-pause.png' $script:muted),
        (New-MusicIcon 'forward.png' $script:foreground), (New-MusicIcon 'forward.png' $script:muted)
    )
    Set-MusicButtonIcon $previousTrack $newIcons[0] $newIcons[1]
    Set-MusicButtonIcon $playTrack $newIcons[2] $newIcons[3]
    Set-MusicButtonIcon $nextTrack $newIcons[4] $newIcons[5]
    foreach ($icon in $script:musicIconImages) { if ($null -ne $icon) { $icon.Dispose() } }
    $script:musicIconImages = $newIcons
}

# Aplica a paleta atual a todos os controles, incluindo o overlay do Spotify.
function Update-ThemeColors {
    $clean = ($script:uiMode -eq 'Clean')
    # No modo Clean o fundo vira chave de transparencia; os botoes usam superficie solida.
    $solidBg = if ($clean) { $script:surface } else { $script:background }
    $form.BackColor = $script:background
    $form.TransparencyKey = if ($clean) { $script:background } else { [System.Drawing.Color]::Empty }
    $rule.BackColor = $script:accent
    $brand.ForeColor = $script:foreground
    $timeLabel.ForeColor = if ($script:finished) { $script:accent } else { $script:foreground }
    $statusLabel.ForeColor = $script:muted
    $botsLabel.ForeColor = $script:accent
    foreach ($label in @($minutesLabel, $secondsLabel, $targetLabel)) { $label.ForeColor = $script:muted }
    # No modo Clean o visor e a meta ganham uma placa solida para continuar legiveis e arrastaveis.
    $chipColor = if ($clean) { $script:surface } else { $script:background }
    $timeLabel.BackColor = $chipColor
    $botsLabel.BackColor = $chipColor
    foreach ($control in @($brand, $statusLabel, $minutesLabel, $secondsLabel, $targetLabel)) { $control.BackColor = $script:background }
    foreach ($input in @($minutesInput, $secondsInput, $botsInput)) {
        $input.BackColor = $script:surface
        $input.ForeColor = $script:foreground
    }
    $startButton.BackColor = $script:accent
    $startButton.ForeColor = $script:accentText
    $resetButton.BackColor = $script:surface
    $resetButton.ForeColor = $script:foreground
    foreach ($button in @($randomButton, $hotkeyButton, $soundButton, $compactButton, $closeButton, $musicButton)) {
        $button.BackColor = $solidBg
        $button.ForeColor = $script:muted
    }
    $musicPanel.BackColor = $script:surface
    $musicCover.BackColor = $chipColor
    $musicHeaderLabel.ForeColor = $script:accent
    $musicTitle.ForeColor = $script:foreground
    $musicArtist.ForeColor = $script:muted
    $musicTime.ForeColor = $script:muted
    foreach ($button in @($previousTrack, $playTrack, $nextTrack)) { $button.BackColor = $solidBg }
    $modeBar.BackColor = $script:background
    $coresButton.BackColor = $solidBg
    $coresButton.ForeColor = $script:muted
    $modeButtons = @(
        @($padraoModeButton, 'Padrao'), @($cleanModeButton, 'Clean'),
        @($competitivoModeButton, 'Competitivo'), @($customModeButton, 'Customizado')
    )
    foreach ($pair in $modeButtons) {
        if ($pair[1] -eq $script:uiMode) {
            $pair[0].BackColor = $script:accent
            $pair[0].ForeColor = $script:accentText
        } else {
            $pair[0].BackColor = $solidBg
            $pair[0].ForeColor = $script:muted
        }
    }
    Update-MusicIconTheme
}

# Define toda a paleta a partir do fundo e da cor de detalhe escolhida.
function Set-ThemeColors {
    param([System.Drawing.Color]$Background, [System.Drawing.Color]$Accent)
    $script:background = $Background
    $script:accent = $Accent
    if ($Background -eq $defaultBackground -and $Accent -eq $defaultAccent) {
        # Paleta original do aplicativo, mantida intacta no modo Padrao.
        $script:surface = [System.Drawing.Color]::FromArgb(28, 37, 47)
        $script:foreground = [System.Drawing.Color]::FromArgb(236, 232, 225)
        $script:muted = [System.Drawing.Color]::FromArgb(151, 162, 171)
        $script:accentText = $script:foreground
    } else {
        # Cores personalizadas: o texto acompanha a tonalidade clara ou escura do fundo.
        $light = (Get-ColorLuminance $Background) -ge 0.5
        if ($light) {
            $script:foreground = [System.Drawing.Color]::FromArgb(24, 24, 24)
            $script:muted = [System.Drawing.Color]::FromArgb(92, 92, 92)
            $script:surface = Shift-Color $Background ([System.Drawing.Color]::Black) 0.12
        } else {
            $script:foreground = [System.Drawing.Color]::FromArgb(240, 240, 240)
            $script:muted = [System.Drawing.Color]::FromArgb(160, 160, 160)
            $script:surface = Shift-Color $Background ([System.Drawing.Color]::White) 0.10
        }
        $script:accentText = if ((Get-ColorLuminance $Accent) -ge 0.5) { [System.Drawing.Color]::FromArgb(24, 24, 24) } else { [System.Drawing.Color]::FromArgb(245, 245, 245) }
    }
    Update-ThemeColors
}
$musicTimer = New-Object System.Windows.Forms.Timer
$musicTimer.Interval = 500

# O áudio é mantido em memória para que a contagem não dependa do arquivo original.
$script:soundBytes = [RangeAudio]::DefaultWave()
$script:soundName = 'Som padrao'
$script:soundVolume = 100
$script:customSound = $false
$script:soundPlayer = $null
$script:soundStream = $null
$soundDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'RangeTimer'
$soundConfigPath = Join-Path $soundDirectory 'sound.json'
$soundFilePath = Join-Path $soundDirectory 'alert.wav'
$hotkeyConfigPath = Join-Path $soundDirectory 'hotkeys.json'
$themeConfigPath = Join-Path $soundDirectory 'theme.json'
$script:hotkeys = [RangeHotkeys]::new()
$hotkeyActionNames = @('', 'Iniciar / continuar', 'Pausar', 'Reiniciar', 'Abrir / compacto')

try {
    if (Test-Path -LiteralPath $hotkeyConfigPath) {
        $savedHotkeys = Get-Content -LiteralPath $hotkeyConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($binding in $savedHotkeys.bindings) {
            $script:hotkeys.RestoreBinding([int]$binding.id, [int]$binding.key, [int]$binding.modifiers)
        }
    }
} catch {
    [void][System.Windows.Forms.MessageBox]::Show('Nao foi possivel ler os atalhos salvos. Confira o menu TECLAS.', 'Range Timer', 'OK', 'Warning')
}

try {
    if (Test-Path -LiteralPath $soundConfigPath) {
        $savedSound = Get-Content -LiteralPath $soundConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $savedVolume = 0
        if ([int]::TryParse([string]$savedSound.volume, [ref]$savedVolume) -and $savedVolume -ge 0 -and $savedVolume -le 100) {
            $script:soundVolume = $savedVolume
        }
        if ($savedSound.custom -eq $true) {
            $script:soundBytes = [RangeAudio]::LoadWave($soundFilePath)
            $script:soundName = [string]$savedSound.name
            $script:customSound = $true
        }
    }
} catch {
    $script:soundBytes = [RangeAudio]::DefaultWave()
    $script:soundName = 'Som padrao'
    $script:customSound = $false
}

function Save-SoundSettings {
    [void][System.IO.Directory]::CreateDirectory($soundDirectory)
    if ($script:customSound) {
        [System.IO.File]::WriteAllBytes($soundFilePath, $script:soundBytes)
    } elseif (Test-Path -LiteralPath $soundFilePath) {
        Remove-Item -LiteralPath $soundFilePath -Force -ErrorAction Stop
    }
    @{ volume = $script:soundVolume; custom = $script:customSound; name = $script:soundName } |
        ConvertTo-Json | Set-Content -LiteralPath $soundConfigPath -Encoding UTF8 -ErrorAction Stop
}

function Play-Alert {
    if ($null -ne $script:soundPlayer) {
        $script:soundPlayer.Stop()
        $script:soundPlayer.Dispose()
        $script:soundStream.Dispose()
    }
    $scaledSound = [RangeAudio]::AtVolume($script:soundBytes, $script:soundVolume)
    $script:soundStream = [System.IO.MemoryStream]::new($scaledSound)
    $script:soundPlayer = [System.Media.SoundPlayer]::new($script:soundStream)
    $script:soundPlayer.Load()
    $script:soundPlayer.Play()
}

function Show-SoundError {
    param([string]$Message)
    [void][System.Windows.Forms.MessageBox]::Show($Message, 'Range Timer', 'OK', 'Warning')
}

# A janela de som continua acessível no modo compacto e não pausa o cronômetro.
function Show-SoundSettings {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'Som do alerta'
    $dialog.ClientSize = New-Object System.Drawing.Size(340, 238)
    $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dialog.BackColor = $background
    $dialog.ForeColor = $foreground
    $dialog.Font = New-Object System.Drawing.Font($fontFamily, 9)
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.ShowInTaskbar = $false
    $dialog.TopMost = $true

    $volumeLabel = New-Object System.Windows.Forms.Label
    $volumeLabel.Location = New-Object System.Drawing.Point(18, 17)
    $volumeLabel.Size = New-Object System.Drawing.Size(300, 22)
    $volumeLabel.Font = New-Object System.Drawing.Font($fontFamily, 10, [System.Drawing.FontStyle]::Bold)
    $volumeLabel.Text = 'VOLUME: {0}%' -f $script:soundVolume
    $dialog.Controls.Add($volumeLabel)

    $volumeSlider = New-Object System.Windows.Forms.TrackBar
    $volumeSlider.Location = New-Object System.Drawing.Point(15, 42)
    $volumeSlider.Size = New-Object System.Drawing.Size(310, 42)
    $volumeSlider.Minimum = 0
    $volumeSlider.Maximum = 100
    $volumeSlider.TickFrequency = 10
    $volumeSlider.Value = $script:soundVolume
    $dialog.Controls.Add($volumeSlider)
    $volumeSlider.Add_ValueChanged({
        $script:soundVolume = $volumeSlider.Value
        $volumeLabel.Text = 'VOLUME: {0}%' -f $script:soundVolume
    })

    $fileTitle = New-Object System.Windows.Forms.Label
    $fileTitle.Text = 'SOM SELECIONADO'
    $fileTitle.Location = New-Object System.Drawing.Point(18, 94)
    $fileTitle.Size = New-Object System.Drawing.Size(300, 18)
    $fileTitle.ForeColor = $muted
    $dialog.Controls.Add($fileTitle)
    $fileLabel = New-Object System.Windows.Forms.Label
    $fileLabel.Location = New-Object System.Drawing.Point(18, 115)
    $fileLabel.Size = New-Object System.Drawing.Size(300, 22)
    $fileLabel.AutoEllipsis = $true
    $fileLabel.Text = $script:soundName
    $dialog.Controls.Add($fileLabel)

    function Add-SoundButton {
        param($Text, $X, $Y, $Width, $Color)
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $Text
        $button.Location = New-Object System.Drawing.Point($X, $Y)
        $button.Size = New-Object System.Drawing.Size($Width, 32)
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $button.FlatAppearance.BorderSize = 0
        $button.BackColor = $Color
        $button.ForeColor = $foreground
        $button.Font = New-Object System.Drawing.Font($fontFamily, 8, [System.Drawing.FontStyle]::Bold)
        $button.Cursor = [System.Windows.Forms.Cursors]::Hand
        $dialog.Controls.Add($button)
        return $button
    }

    $importButton = Add-SoundButton 'IMPORTAR WAV' 18 145 144 $surface
    $defaultButton = Add-SoundButton 'SOM PADRAO' 170 145 152 $surface
    $previewButton = Add-SoundButton 'TESTAR SOM' 18 188 144 $accent
    $doneButton = Add-SoundButton 'FECHAR' 170 188 152 $surface

    $importButton.Add_Click({
        $picker = New-Object System.Windows.Forms.OpenFileDialog
        $picker.Title = 'Escolha um som WAV'
        $picker.Filter = 'Audio WAV (*.wav)|*.wav'
        $picker.CheckFileExists = $true
        try {
            if ($picker.ShowDialog($dialog) -eq [System.Windows.Forms.DialogResult]::OK) {
                try {
                    $bytes = [RangeAudio]::LoadWave($picker.FileName)
                    $script:soundBytes = $bytes
                    $script:soundName = [System.IO.Path]::GetFileName($picker.FileName)
                    $script:customSound = $true
                    $fileLabel.Text = $script:soundName
                } catch {
                    Show-SoundError ('Nao foi possivel importar o som. Use WAV PCM de 16 bits, mono ou stereo, com ate 30 segundos e 10 MB.')
                }
            }
        } finally {
            $picker.Dispose()
        }
    })
    $defaultButton.Add_Click({
        $script:soundBytes = [RangeAudio]::DefaultWave()
        $script:soundName = 'Som padrao'
        $script:customSound = $false
        $fileLabel.Text = $script:soundName
    })
    $previewButton.Add_Click({
        try { Play-Alert } catch { Show-SoundError 'Nao foi possivel reproduzir o alerta. Confira o dispositivo de audio do Windows.' }
    })
    $doneButton.Add_Click({ $dialog.Close() })
    try {
        [void]$dialog.ShowDialog($form)
        try { Save-SoundSettings } catch { Show-SoundError 'Nao foi possivel salvar as configuracoes de som. Elas valem apenas nesta sessao.' }
    } finally {
        $dialog.Dispose()
    }
}

# As teclas ficam suspensas durante a configuração para permitir a captura segura.
function Save-HotkeySettings {
    [void][System.IO.Directory]::CreateDirectory($soundDirectory)
    $bindings = @(
        foreach ($id in 1..4) {
            if ($script:hotkeys.GetKey($id) -ne 0) {
                @{ id = $id; key = $script:hotkeys.GetKey($id); modifiers = $script:hotkeys.GetModifiers($id) }
            }
        }
    )
    @{ bindings = $bindings } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $hotkeyConfigPath -Encoding UTF8 -ErrorAction Stop
}

function Show-HotkeySettings {
    $script:hotkeys.Deactivate()
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'Atalhos de teclado'
    $dialog.ClientSize = New-Object System.Drawing.Size(390, 320)
    $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dialog.BackColor = $background
    $dialog.ForeColor = $foreground
    $dialog.Font = New-Object System.Drawing.Font($fontFamily, 9)
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.ShowInTaskbar = $false
    $dialog.TopMost = $true

    $help = New-Object System.Windows.Forms.Label
    $help.Text = 'Clique no campo e pressione a tecla ou combinacao. X remove o atalho.'
    $help.Location = New-Object System.Drawing.Point(18, 15)
    $help.Size = New-Object System.Drawing.Size(355, 36)
    $help.ForeColor = $muted
    $dialog.Controls.Add($help)

    $shortcutButtons = @{}
    foreach ($id in 1..4) {
        $y = 58 + (($id - 1) * 43)
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $hotkeyActionNames[$id]
        $label.Location = New-Object System.Drawing.Point(18, ($y + 7))
        $label.Size = New-Object System.Drawing.Size(145, 22)
        $dialog.Controls.Add($label)

        $captureButton = New-Object HotkeyCaptureButton
        $captureButton.Tag = $id
        $captureButton.Text = $script:hotkeys.GetDisplay($id)
        $captureButton.Location = New-Object System.Drawing.Point(163, $y)
        $captureButton.Size = New-Object System.Drawing.Size(164, 32)
        $captureButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $captureButton.FlatAppearance.BorderSize = 0
        $captureButton.BackColor = $surface
        $captureButton.ForeColor = $foreground
        $captureButton.Cursor = [System.Windows.Forms.Cursors]::Hand
        $dialog.Controls.Add($captureButton)
        $shortcutButtons[$id] = $captureButton
        $captureButton.Add_Click({
            foreach ($item in $shortcutButtons.Values) {
                $item.Capturing = $false
                $item.Text = $script:hotkeys.GetDisplay([int]$item.Tag)
            }
            $this.Capturing = $true
            $this.Text = 'PRESSIONE A TECLA...'
            [void]$this.Focus()
        })
        $captureButton.Add_Leave({
            if ($this.Capturing) {
                $this.Capturing = $false
                $this.Text = $script:hotkeys.GetDisplay([int]$this.Tag)
            }
        })
        $captureButton.Add_ShortcutCaptured({
            if ($script:hotkeys.SetBinding([int]$this.Tag, $_.Key, $_.Modifiers)) {
                try { Save-HotkeySettings } catch { Show-SoundError 'Nao foi possivel salvar os atalhos. As alteracoes valem apenas nesta sessao.' }
            } else {
                Show-SoundError $script:hotkeys.LastError
            }
            $this.Text = $script:hotkeys.GetDisplay([int]$this.Tag)
        })

        $clear = New-Object System.Windows.Forms.Button
        $clear.Tag = $id
        $clear.Text = 'X'
        $clear.Location = New-Object System.Drawing.Point(335, $y)
        $clear.Size = New-Object System.Drawing.Size(36, 32)
        $clear.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $clear.FlatAppearance.BorderSize = 0
        $clear.BackColor = $surface
        $clear.ForeColor = $muted
        $clear.Cursor = [System.Windows.Forms.Cursors]::Hand
        $dialog.Controls.Add($clear)
        $clear.Add_Click({
            $id = [int]$this.Tag
            [void]$script:hotkeys.SetBinding($id, 0, 0)
            $shortcutButtons[$id].Text = $script:hotkeys.GetDisplay($id)
            try { Save-HotkeySettings } catch { Show-SoundError 'Nao foi possivel salvar os atalhos. As alteracoes valem apenas nesta sessao.' }
        })
    }

    $warning = New-Object System.Windows.Forms.Label
    $warning.Text = 'Atalhos globais podem impedir o uso da tecla no jogo. Prefira combinacoes com Ctrl, Alt ou Shift.'
    $warning.Location = New-Object System.Drawing.Point(18, 235)
    $warning.Size = New-Object System.Drawing.Size(355, 35)
    $warning.ForeColor = $muted
    $dialog.Controls.Add($warning)

    $done = New-Object System.Windows.Forms.Button
    $done.Text = 'FECHAR'
    $done.Location = New-Object System.Drawing.Point(225, 278)
    $done.Size = New-Object System.Drawing.Size(146, 32)
    $done.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $done.FlatAppearance.BorderSize = 0
    $done.BackColor = $accent
    $done.ForeColor = $foreground
    $done.Cursor = [System.Windows.Forms.Cursors]::Hand
    $done.Add_Click({ $dialog.Close() })
    $dialog.Controls.Add($done)

    try {
        [void]$dialog.ShowDialog($form)
    } finally {
        $dialog.Dispose()
        $failed = @($script:hotkeys.Activate())
        if ($failed.Count -gt 0) {
            $names = @($failed | ForEach-Object { $hotkeyActionNames[$_] }) -join ', '
            Show-SoundError "Nao foi possivel ativar: $names. Outra aplicacao ou o Windows pode estar usando essas teclas."
        }
    }
}

# As imagens WebP originais têm cópias PNG para a leitura nativa do Windows Forms.
function Get-DrawImages {
    $images = @{}
    $imageDirectory = Join-Path $PSScriptRoot 'images'
    foreach ($directory in @($imageDirectory, (Join-Path $imageDirectory 'compatibles'))) {
        if (Test-Path -LiteralPath $directory -PathType Container) {
            foreach ($file in @(Get-ChildItem -LiteralPath $directory -File -ErrorAction SilentlyContinue)) {
                if ($file.Extension -in @('.png', '.jpg', '.jpeg', '.bmp')) {
                    $key = $file.BaseName.ToLowerInvariant()
                    if (-not $images.ContainsKey($key)) { $images[$key] = $file.FullName }
                }
            }
        }
    }
    return $images
}

function Show-Randomizer {
    $images = Get-DrawImages
    $agents = @($images.Keys | Where-Object { -not $_.StartsWith('weapon_') } | Sort-Object)
    $weapons = @($images.Keys | Where-Object { $_.StartsWith('weapon_') } | Sort-Object)

    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'Sorteio de treino'
    $dialog.ClientSize = New-Object System.Drawing.Size(410, 342)
    $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dialog.BackColor = $background
    $dialog.ForeColor = $foreground
    $dialog.Font = New-Object System.Drawing.Font($fontFamily, 9)
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.ShowInTaskbar = $false
    $dialog.TopMost = $true

    function Add-DrawLabel {
        param($Text, $X, $Y, $Width, $Height, $Color)
        $label = New-Object System.Windows.Forms.Label
        $label.Text = $Text
        $label.Location = New-Object System.Drawing.Point($X, $Y)
        $label.Size = New-Object System.Drawing.Size($Width, $Height)
        $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $label.ForeColor = $Color
        $dialog.Controls.Add($label)
        return $label
    }
    function Add-DrawButton {
        param($Text, $X, $Y, $Width, $Color)
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $Text
        $button.Location = New-Object System.Drawing.Point($X, $Y)
        $button.Size = New-Object System.Drawing.Size($Width, 32)
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $button.FlatAppearance.BorderSize = 0
        $button.BackColor = $Color
        $button.ForeColor = $foreground
        $button.Cursor = [System.Windows.Forms.Cursors]::Hand
        $dialog.Controls.Add($button)
        return $button
    }
    function Set-DrawResult {
        param($Items, $Picture, $Label)
        if ($Items.Count -eq 0) { return }
        $key = Get-Random -InputObject $Items
        try {
            $loaded = [System.Drawing.Image]::FromFile($images[$key])
            try { $copy = [System.Drawing.Bitmap]::new($loaded) } finally { $loaded.Dispose() }
            $previous = $Picture.Image
            $Picture.Image = $copy
            if ($null -ne $previous) { $previous.Dispose() }
            $name = $key -replace '^weapon_', ''
            if ($name -eq 'kayo') { $name = 'KAY/O' }
            if ($name -eq 'melee') { $name = 'FACA' }
            $Label.Text = $name.ToUpperInvariant()
        } catch {
            $Label.Text = 'Erro ao abrir imagem'
            if ($null -ne $Picture.Image) { $Picture.Image.Dispose(); $Picture.Image = $null }
        }
    }

    [void](Add-DrawLabel 'AGENTE' 18 12 180 24 $accent)
    [void](Add-DrawLabel 'ARMA' 212 12 180 24 $accent)
    $agentPicture = New-Object System.Windows.Forms.PictureBox
    $agentPicture.Location = New-Object System.Drawing.Point(18, 42)
    $agentPicture.Size = New-Object System.Drawing.Size(180, 150)
    $agentPicture.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $agentPicture.BackColor = $surface
    $dialog.Controls.Add($agentPicture)
    $weaponPicture = New-Object System.Windows.Forms.PictureBox
    $weaponPicture.Location = New-Object System.Drawing.Point(212, 42)
    $weaponPicture.Size = New-Object System.Drawing.Size(180, 150)
    $weaponPicture.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $weaponPicture.BackColor = $surface
    $dialog.Controls.Add($weaponPicture)

    $agentName = Add-DrawLabel 'Clique para sortear' 18 198 180 25 $foreground
    $weaponName = Add-DrawLabel 'Clique para sortear' 212 198 180 25 $foreground
    $drawAgent = Add-DrawButton 'SORTEAR AGENTE' 18 228 180 $surface
    $drawWeapon = Add-DrawButton 'SORTEAR ARMA' 212 228 180 $surface
    $drawBoth = Add-DrawButton 'SORTEAR AMBOS' 18 280 180 $accent
    $done = Add-DrawButton 'FECHAR' 212 280 180 $surface
    if ($agents.Count -eq 0) { $agentName.Text = 'Nenhum agente encontrado'; $drawAgent.Enabled = $false }
    if ($weapons.Count -eq 0) { $weaponName.Text = 'Nenhuma arma encontrada'; $drawWeapon.Enabled = $false }
    $drawBoth.Enabled = ($agents.Count -gt 0 -and $weapons.Count -gt 0)
    $drawAgent.Add_Click({ Set-DrawResult $agents $agentPicture $agentName })
    $drawWeapon.Add_Click({ Set-DrawResult $weapons $weaponPicture $weaponName })
    $drawBoth.Add_Click({
        Set-DrawResult $agents $agentPicture $agentName
        Set-DrawResult $weapons $weaponPicture $weaponName
    })
    $done.Add_Click({ $dialog.Close() })
    try {
        [void]$dialog.ShowDialog($form)
    } finally {
        if ($null -ne $agentPicture.Image) { $agentPicture.Image.Dispose() }
        if ($null -ne $weaponPicture.Image) { $weaponPicture.Image.Dispose() }
        $dialog.Dispose()
    }
}

# Alterna a apresentação sem alterar o estado ou o tempo da contagem.
function Set-CompactMode {
    param([bool]$Compact)
    $script:compact = $Compact
    Set-Layout
}

# Reorganiza a janela conforme o modo de interface e o estado compacto.
# O modo Competitivo usa o layout minimo: somente visor, meta e barra de modos.
function Set-Layout {
    $minimal = ($script:uiMode -eq 'Competitivo')
    foreach ($control in $settingsControls) {
        $control.Visible = ((-not $script:compact) -and (-not $minimal))
    }

    # O painel de musica e reavaliado no fim; a barra de modos nunca e ocultada.
    $musicPanel.Visible = $false
    $musicTimer.Stop()

    if ($minimal) {
        $form.ClientSize = New-Object System.Drawing.Size(264, 84)
        $brand.Visible = $false
        $randomButton.Visible = $false
        $hotkeyButton.Visible = $false
        $soundButton.Visible = $false
        $compactButton.Visible = $false
        $musicButton.Visible = $false
        $rule.Visible = $false
        $statusLabel.Visible = $false
        $closeButton.Location = New-Object System.Drawing.Point(238, 4)
        $closeButton.Size = New-Object System.Drawing.Size(20, 20)
        $closeButton.Font = $minimalCloseFont
        $timeLabel.Location = New-Object System.Drawing.Point(15, 6)
        $timeLabel.Size = New-Object System.Drawing.Size(145, 43)
        $timeLabel.Font = $compactTimeFont
        $botsLabel.Location = New-Object System.Drawing.Point(160, 17)
        $botsLabel.Size = New-Object System.Drawing.Size(76, 22)
        $botsLabel.Font = $compactBotsFont
        $modeBar.Location = New-Object System.Drawing.Point(0, 56)
        $modeBar.Size = New-Object System.Drawing.Size(264, 28)
        $compactModeButtons = $true
    } else {
        # Controles ocultos no modo Competitivo voltam a aparecer nos demais.
        $brand.Visible = $true
        $randomButton.Visible = $true
        $hotkeyButton.Visible = $true
        $soundButton.Visible = $true
        $compactButton.Visible = $true
        $musicButton.Visible = $true
        $rule.Visible = $true
        $statusLabel.Visible = $true
        $closeButton.Font = $regularCloseFont
        $closeButton.Size = New-Object System.Drawing.Size(24, 33)

        if ($script:compact) {
            $form.ClientSize = New-Object System.Drawing.Size(264, (140 + $(if ($script:musicVisible) { 146 } else { 0 })))
            $musicPanel.Location = New-Object System.Drawing.Point(0, 140)
            $musicButton.Location = New-Object System.Drawing.Point(187, 84)
            $musicButton.Size = New-Object System.Drawing.Size(67, 24)
            $statusLabel.Size = New-Object System.Drawing.Size(165, 19)
            $brand.Text = 'RANGE'
            $brand.Font = $compactBrandFont
            $brand.Location = New-Object System.Drawing.Point(8, 13)
            $brand.Size = New-Object System.Drawing.Size(43, 22)
            $randomButton.Location = New-Object System.Drawing.Point(51, 8)
            $randomButton.Size = New-Object System.Drawing.Size(55, 33)
            $hotkeyButton.Location = New-Object System.Drawing.Point(106, 8)
            $hotkeyButton.Size = New-Object System.Drawing.Size(48, 33)
            $soundButton.Location = New-Object System.Drawing.Point(154, 8)
            $soundButton.Size = New-Object System.Drawing.Size(36, 33)
            $compactButton.Text = 'ABRIR'
            $compactButton.Location = New-Object System.Drawing.Point(190, 8)
            $compactButton.Size = New-Object System.Drawing.Size(47, 33)
            $closeButton.Location = New-Object System.Drawing.Point(237, 8)
            $rule.Size = New-Object System.Drawing.Size(228, 2)
            $timeLabel.Location = New-Object System.Drawing.Point(15, 48)
            $timeLabel.Size = New-Object System.Drawing.Size(145, 43)
            $timeLabel.Font = $compactTimeFont
            $botsLabel.Location = New-Object System.Drawing.Point(164, 59)
            $botsLabel.Size = New-Object System.Drawing.Size(82, 22)
            $botsLabel.Font = $compactBotsFont
            $statusLabel.Location = New-Object System.Drawing.Point(20, 88)
            $modeBar.Location = New-Object System.Drawing.Point(0, 112)
            $modeBar.Size = New-Object System.Drawing.Size(264, 28)
            $compactModeButtons = $true
        } else {
            $form.ClientSize = New-Object System.Drawing.Size(372, (282 + $(if ($script:musicVisible) { 146 } else { 0 })))
            $musicPanel.Location = New-Object System.Drawing.Point(54, 282)
            $musicButton.Location = New-Object System.Drawing.Point(262, 105)
            $musicButton.Size = New-Object System.Drawing.Size(92, 33)
            $statusLabel.Size = New-Object System.Drawing.Size(230, 19)
            $brand.Text = 'RANGE / TIMER'
            $brand.Font = $regularBrandFont
            $brand.Location = New-Object System.Drawing.Point(12, 13)
            $brand.Size = New-Object System.Drawing.Size(110, 22)
            $randomButton.Location = New-Object System.Drawing.Point(123, 8)
            $randomButton.Size = New-Object System.Drawing.Size(58, 33)
            $hotkeyButton.Location = New-Object System.Drawing.Point(181, 8)
            $hotkeyButton.Size = New-Object System.Drawing.Size(52, 33)
            $soundButton.Location = New-Object System.Drawing.Point(233, 8)
            $soundButton.Size = New-Object System.Drawing.Size(40, 33)
            $compactButton.Text = 'COMPACTO'
            $compactButton.Location = New-Object System.Drawing.Point(273, 8)
            $compactButton.Size = New-Object System.Drawing.Size(68, 33)
            $closeButton.Location = New-Object System.Drawing.Point(345, 8)
            $rule.Size = New-Object System.Drawing.Size(336, 2)
            $timeLabel.Location = New-Object System.Drawing.Point(15, 51)
            $timeLabel.Size = New-Object System.Drawing.Size(220, 58)
            $timeLabel.Font = $regularTimeFont
            $botsLabel.Location = New-Object System.Drawing.Point(246, 70)
            $botsLabel.Size = New-Object System.Drawing.Size(108, 25)
            $botsLabel.Font = $regularBotsFont
            $statusLabel.Location = New-Object System.Drawing.Point(20, 111)
            $modeBar.Location = New-Object System.Drawing.Point(0, 254)
            $modeBar.Size = New-Object System.Drawing.Size(372, 28)
            $compactModeButtons = $false
        }
    }

    # O painel de musica continua disponivel fora do modo Competitivo.
    if ((-not $minimal) -and $script:musicVisible) {
        $musicPanel.Visible = $true
        if ($null -eq $script:spotify -or -not $script:spotify.Available) { $script:spotify = New-SpotifyState }
        $musicTimer.Start()
    }

    # Os botoes de modo se ajustam a largura disponivel do layout atual.
    $modeButtonLayout = if ($compactModeButtons) {
        @(
            @($padraoModeButton, 8, 44), @($cleanModeButton, 56, 40),
            @($competitivoModeButton, 100, 64), @($customModeButton, 168, 46),
            @($coresButton, 218, 38)
        )
    } else {
        @(
            @($padraoModeButton, 12, 64), @($cleanModeButton, 80, 56),
            @($competitivoModeButton, 140, 92), @($customModeButton, 236, 72),
            @($coresButton, 312, 52)
        )
    }
    $modeButtonFont = if ($compactModeButtons) { $modeButtonFontCompact } else { $modeButtonFontNormal }
    foreach ($pair in $modeButtonLayout) {
        $pair[0].Location = New-Object System.Drawing.Point($pair[1], 2)
        $pair[0].Size = New-Object System.Drawing.Size($pair[2], 24)
        $pair[0].Font = $modeButtonFont
    }

    # Mantem a janela dentro da area de trabalho apos o redimensionamento.
    $workingArea = [System.Windows.Forms.Screen]::FromControl($form).WorkingArea
    $left = [Math]::Max($workingArea.Left, [Math]::Min($form.Left, $workingArea.Right - $form.Width))
    $top = [Math]::Max($workingArea.Top, [Math]::Min($form.Top, $workingArea.Bottom - $form.Height))
    $form.Location = New-Object System.Drawing.Point($left, $top)
}

# Aplica o modo de interface escolhido e registra a escolha para a proxima execucao.
function Set-UIMode {
    param([string]$Mode)
    $script:uiMode = $Mode
    if ($Mode -eq 'Customizado') {
        Set-ThemeColors $script:customBackground $script:customAccent
    } else {
        Set-ThemeColors $defaultBackground $defaultAccent
    }
    # O seletor de cores so faz sentido no modo Customizado.
    $coresButton.Visible = ($Mode -eq 'Customizado')
    Set-Layout
    Save-ThemeConfig
}

function Convert-ColorToHex {
    param([System.Drawing.Color]$Color)
    return '{0:X2}{1:X2}{2:X2}' -f $Color.R, $Color.G, $Color.B
}

function Convert-HexToColor {
    param([string]$Hex)
    if ($Hex -match '^[0-9A-Fa-f]{6}$') {
        return [System.Drawing.ColorTranslator]::FromHtml('#' + $Hex)
    }
    return $null
}

# Guarda o modo e as cores personalizadas em theme.json.
function Save-ThemeConfig {
    try {
        [void][System.IO.Directory]::CreateDirectory($soundDirectory)
        @{ mode = $script:uiMode; background = (Convert-ColorToHex $script:customBackground); accent = (Convert-ColorToHex $script:customAccent) } |
            ConvertTo-Json | Set-Content -LiteralPath $themeConfigPath -Encoding UTF8 -ErrorAction Stop
    } catch { }
}

# Recupera o modo salvo; em caso de problema volta ao modo Padrao.
function Load-ThemeConfig {
    try {
        if (-not (Test-Path -LiteralPath $themeConfigPath)) { return 'Padrao' }
        $savedTheme = Get-Content -LiteralPath $themeConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $mode = [string]$savedTheme.mode
        if (@('Padrao', 'Clean', 'Competitivo', 'Customizado') -notcontains $mode) { return 'Padrao' }
        if ($mode -eq 'Customizado') {
            $savedBackground = Convert-HexToColor ([string]$savedTheme.background)
            $savedAccent = Convert-HexToColor ([string]$savedTheme.accent)
            if ($null -ne $savedBackground) { $script:customBackground = $savedBackground }
            if ($null -ne $savedAccent) { $script:customAccent = $savedAccent }
        }
        return $mode
    } catch {
        return 'Padrao'
    }
}

# Janela de cores do modo Customizado com preenchimento RGB e previsao em tempo real.
function Show-ColorSettings {
    $dialog = New-Object System.Windows.Forms.Form
    $dialog.Text = 'Cores personalizadas'
    $dialog.ClientSize = New-Object System.Drawing.Size(340, 302)
    $dialog.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dialog.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterParent
    $dialog.BackColor = $background
    $dialog.ForeColor = $foreground
    $dialog.Font = New-Object System.Drawing.Font($fontFamily, 9)
    $dialog.MaximizeBox = $false
    $dialog.MinimizeBox = $false
    $dialog.ShowInTaskbar = $false
    $dialog.TopMost = $true

    $help = New-Object System.Windows.Forms.Label
    $help.Text = 'Defina os canais RGB de 0 a 255. A previsao mostra o resultado.'
    $help.Location = New-Object System.Drawing.Point(18, 15)
    $help.Size = New-Object System.Drawing.Size(304, 34)
    $help.ForeColor = $muted
    $dialog.Controls.Add($help)

    function Add-ColorHeader {
        param($Text, $Y)
        $header = New-Object System.Windows.Forms.Label
        $header.Text = $Text
        $header.Location = New-Object System.Drawing.Point(18, $Y)
        $header.Size = New-Object System.Drawing.Size(120, 18)
        $header.Font = New-Object System.Drawing.Font($fontFamily, 9, [System.Drawing.FontStyle]::Bold)
        $dialog.Controls.Add($header)
    }

    function Add-ColorNumber {
        param($X, $Y, $Value)
        $number = New-Object System.Windows.Forms.NumericUpDown
        $number.Location = New-Object System.Drawing.Point($X, $Y)
        $number.Size = New-Object System.Drawing.Size(84, 26)
        $number.Minimum = 0
        $number.Maximum = 255
        $number.Value = [Math]::Max(0, [Math]::Min(255, [int]$Value))
        $number.BackColor = $surface
        $number.ForeColor = $foreground
        $number.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $number.Font = New-Object System.Drawing.Font($fontFamily, 10)
        $dialog.Controls.Add($number)
        return $number
    }

    Add-ColorHeader 'FUNDO' 58
    $bgRed = Add-ColorNumber 18 78 $script:customBackground.R
    $bgGreen = Add-ColorNumber 128 78 $script:customBackground.G
    $bgBlue = Add-ColorNumber 238 78 $script:customBackground.B
    Add-ColorHeader 'DETALHE' 116
    $acRed = Add-ColorNumber 18 136 $script:customAccent.R
    $acGreen = Add-ColorNumber 128 136 $script:customAccent.G
    $acBlue = Add-ColorNumber 238 136 $script:customAccent.B

    # A previsao reproduz o visor do timer com as cores escolhidas.
    $previewPanel = New-Object System.Windows.Forms.Panel
    $previewPanel.Location = New-Object System.Drawing.Point(18, 174)
    $previewPanel.Size = New-Object System.Drawing.Size(304, 56)
    $dialog.Controls.Add($previewPanel)

    $previewTime = New-Object System.Windows.Forms.Label
    $previewTime.Text = '05:00'
    $previewTime.Location = New-Object System.Drawing.Point(10, 12)
    $previewTime.Size = New-Object System.Drawing.Size(120, 32)
    $previewTime.BackColor = [System.Drawing.Color]::Transparent
    $previewTime.Font = New-Object System.Drawing.Font($fontFamily, 16, [System.Drawing.FontStyle]::Bold)
    $previewPanel.Controls.Add($previewTime)

    $previewBots = New-Object System.Windows.Forms.Label
    $previewBots.Text = '100 BOTS'
    $previewBots.Location = New-Object System.Drawing.Point(140, 18)
    $previewBots.Size = New-Object System.Drawing.Size(110, 22)
    $previewBots.BackColor = [System.Drawing.Color]::Transparent
    $previewBots.Font = New-Object System.Drawing.Font($fontFamily, 9, [System.Drawing.FontStyle]::Bold)
    $previewPanel.Controls.Add($previewBots)

    $previewSwatch = New-Object System.Windows.Forms.Panel
    $previewSwatch.Location = New-Object System.Drawing.Point(258, 14)
    $previewSwatch.Size = New-Object System.Drawing.Size(32, 28)
    $previewPanel.Controls.Add($previewSwatch)

    function Update-ColorPreview {
        $chosenBackground = [System.Drawing.Color]::FromArgb([int]$bgRed.Value, [int]$bgGreen.Value, [int]$bgBlue.Value)
        $chosenAccent = [System.Drawing.Color]::FromArgb([int]$acRed.Value, [int]$acGreen.Value, [int]$acBlue.Value)
        $previewPanel.BackColor = $chosenBackground
        $previewSwatch.BackColor = $chosenAccent
        $previewBots.ForeColor = $chosenAccent
        if ($chosenBackground -eq $defaultBackground -and $chosenAccent -eq $defaultAccent) {
            $previewTime.ForeColor = [System.Drawing.Color]::FromArgb(236, 232, 225)
        } elseif ((Get-ColorLuminance $chosenBackground) -ge 0.5) {
            $previewTime.ForeColor = [System.Drawing.Color]::FromArgb(24, 24, 24)
        } else {
            $previewTime.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
        }
    }

    foreach ($input in @($bgRed, $bgGreen, $bgBlue, $acRed, $acGreen, $acBlue)) {
        $input.Add_ValueChanged({ Update-ColorPreview })
    }

    function Add-ColorButton {
        param($Text, $X, $Width, $Color)
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $Text
        $button.Location = New-Object System.Drawing.Point($X, 250)
        $button.Size = New-Object System.Drawing.Size($Width, 32)
        $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $button.FlatAppearance.BorderSize = 0
        $button.BackColor = $Color
        $button.ForeColor = if ($Color -eq $accent) { $accentText } else { $foreground }
        $button.Font = New-Object System.Drawing.Font($fontFamily, 8, [System.Drawing.FontStyle]::Bold)
        $button.Cursor = [System.Windows.Forms.Cursors]::Hand
        $dialog.Controls.Add($button)
        return $button
    }

    $defaultColorsButton = Add-ColorButton 'PADRAO' 18 96 $surface
    $applyColorsButton = Add-ColorButton 'APLICAR' 124 96 $accent
    $cancelColorsButton = Add-ColorButton 'CANCELAR' 230 92 $surface

    $defaultColorsButton.Add_Click({
        $bgRed.Value = $defaultBackground.R
        $bgGreen.Value = $defaultBackground.G
        $bgBlue.Value = $defaultBackground.B
        $acRed.Value = $defaultAccent.R
        $acGreen.Value = $defaultAccent.G
        $acBlue.Value = $defaultAccent.B
    })
    $applyColorsButton.Add_Click({
        $script:customBackground = [System.Drawing.Color]::FromArgb([int]$bgRed.Value, [int]$bgGreen.Value, [int]$bgBlue.Value)
        $script:customAccent = [System.Drawing.Color]::FromArgb([int]$acRed.Value, [int]$acGreen.Value, [int]$acBlue.Value)
        $dialog.Close()
        Set-UIMode 'Customizado'
    })
    $cancelColorsButton.Add_Click({ $dialog.Close() })

    Update-ColorPreview
    try {
        [void]$dialog.ShowDialog($form)
    } finally {
        $dialog.Dispose()
    }
}

# Atualiza os dados exibidos sem interromper a contagem regressiva.
function Format-MediaTime {
    param([double]$Seconds)
    $seconds = [Math]::Max(0, [Math]::Floor($Seconds))
    return '{0:00}:{1:00}' -f [Math]::Floor($seconds / 60), ($seconds % 60)
}

function Update-MusicPanel {
    if ($null -eq $script:spotify) { return }
    Update-SpotifyState $script:spotify
    $state = $script:spotify
    $previousTrack.Enabled = ($null -ne $state.Session -and $state.CanPrevious -and $null -eq $state.CommandTask)
    $nextTrack.Enabled = ($null -ne $state.Session -and $state.CanNext -and $null -eq $state.CommandTask)
    # Com icones o rotulo fica apenas no nome acessivel; sem icones o texto continua.
    if ($null -eq $playTrack.Image) { $playTrack.Text = if ($state.Playing) { 'PAUSAR' } else { 'PLAY' } }
    $playTrack.AccessibleName = if ($state.Playing) { 'PAUSAR' } else { 'PLAY' }
    $playTrack.Enabled = ($null -ne $state.Session -and $null -eq $state.CommandTask -and (($state.Playing -and $state.CanPause) -or (-not $state.Playing -and $state.CanPlay)))
    if (-not $state.Available) {
        $musicTitle.Text = 'Spotify indisponivel'
        $musicArtist.Text = $state.Error
    } elseif ($null -eq $state.Session) {
        $musicTitle.Text = 'Abra o Spotify no computador'
        $musicArtist.Text = 'Aguardando reproducao...'
    } else {
        $musicTitle.Text = if ($state.Title) { $state.Title } else { 'Aguardando faixa...' }
        $musicArtist.Text = if ($state.CommandError) { $state.CommandError } elseif ($state.Artist) { $state.Artist } else { 'Artista indisponivel' }
    }
    if ($state.Duration -gt 0) {
        $musicTime.Text = '{0} / {1}' -f (Format-MediaTime $state.Position), (Format-MediaTime $state.Duration)
        $musicProgress.Value = [Math]::Max(0, [Math]::Min(1000, [int](1000 * $state.Position / $state.Duration)))
    } else {
        $musicTime.Text = '--:-- / --:--'
        $musicProgress.Value = 0
    }
    if ($script:shownArtworkKey -ne $state.TrackKey -or $null -eq $state.Session) {
        if ($null -ne $musicCover.Image) { $musicCover.Image.Dispose(); $musicCover.Image = $null }
        $script:shownArtworkKey = ''
    }
    if ($null -ne $state.ArtworkBytes -and $script:shownArtworkKey -ne $state.TrackKey) {
        try {
            $stream = [System.IO.MemoryStream]::new($state.ArtworkBytes)
            try {
                $loaded = [System.Drawing.Image]::FromStream($stream)
                try { $musicCover.Image = [System.Drawing.Bitmap]::new($loaded) } finally { $loaded.Dispose() }
            } finally { $stream.Dispose() }
        } catch { }
        $script:shownArtworkKey = $state.TrackKey
    }
}

$musicTimer.Add_Tick({ Update-MusicPanel })
$previousTrack.Add_Click({ Send-SpotifyCommand $script:spotify 'Previous'; Update-MusicPanel })
$nextTrack.Add_Click({ Send-SpotifyCommand $script:spotify 'Next'; Update-MusicPanel })
$playTrack.Add_Click({
    if ($script:spotify.Playing) { Send-SpotifyCommand $script:spotify 'Pause' } else { Send-SpotifyCommand $script:spotify 'Play' }
    Update-MusicPanel
})
$musicButton.Add_Click({
    $script:musicVisible = -not $script:musicVisible
    Set-Layout
    if ($script:musicVisible) { Update-MusicPanel }
})

# Arredonda os segundos restantes para cima e impede que o visor fique negativo.
function Update-Display {
    $remaining = [Math]::Max(0, [Math]::Ceiling($script:duration - $script:clock.Elapsed.TotalSeconds))
    $totalMinutes = [Math]::Floor($remaining / 60)
    $seconds = $remaining % 60
    $timeLabel.Text = '{0:00}:{1:00}' -f $totalMinutes, $seconds
}

# Restaura o estado inicial usando os valores atualmente configurados.
function Reset-Timer {
    $script:clock.Reset()
    $script:finished = $false
    $script:duration = [double]($minutesInput.Value * 60 + $secondsInput.Value)
    $minutesInput.Enabled = $true
    $secondsInput.Enabled = $true
    $botsInput.Enabled = $true
    $botsLabel.Text = '{0} BOTS' -f $botsInput.Value
    $statusLabel.Text = 'PRONTO PARA TREINAR'
    $timeLabel.ForeColor = $foreground
    $startButton.Text = 'INICIAR'
    Update-Display
}

# Atualiza o visor periodicamente e toca o alerta quando o tempo termina.
$ticker = New-Object System.Windows.Forms.Timer
$ticker.Interval = 100
$ticker.Add_Tick({
    Update-Display
    if ($script:clock.Elapsed.TotalSeconds -ge $script:duration) {
        $ticker.Stop()
        $script:clock.Stop()
        $script:finished = $true
        $statusLabel.Text = 'TEMPO ESGOTADO'
        $timeLabel.ForeColor = $accent
        $startButton.Text = 'INICIAR'
        try { Play-Alert } catch { Show-SoundError 'Nao foi possivel reproduzir o alerta. Confira o dispositivo de audio do Windows.' }
    }
})

# As ações são compartilhadas entre os botões e os atalhos globais.
function Pause-Timer {
    if (-not $script:clock.IsRunning) { return }
    $script:clock.Stop()
    $ticker.Stop()
    $statusLabel.Text = 'PAUSADO'
    $startButton.Text = 'CONTINUAR'
    Update-Display
}

function Start-Timer {
    if ($script:clock.IsRunning) { return }
    if ($script:finished) { Reset-Timer }
    if ($script:duration -le 0) {
        $statusLabel.Text = 'DEFINA UM TEMPO MAIOR QUE ZERO'
        return
    }
    $minutesInput.Enabled = $false
    $secondsInput.Enabled = $false
    $botsInput.Enabled = $false
    $statusLabel.Text = 'TREINO EM ANDAMENTO'
    $startButton.Text = 'PAUSAR'
    if ($script:clock.ElapsedTicks -eq 0) {
        Set-CompactMode $true
    }
    $script:clock.Start()
    $ticker.Start()
}

function Restart-Timer {
    $ticker.Stop()
    Reset-Timer
}

$startButton.Add_Click({
    if ($script:clock.IsRunning) { Pause-Timer } else { Start-Timer }
})
$resetButton.Add_Click({ Restart-Timer })
$minutesInput.Add_ValueChanged({ Reset-Timer })
$secondsInput.Add_ValueChanged({ Reset-Timer })
$botsInput.Add_ValueChanged({ Reset-Timer })
$randomButton.Add_Click({ Show-Randomizer })
$hotkeyButton.Add_Click({ Show-HotkeySettings })
$soundButton.Add_Click({ Show-SoundSettings })
$script:hotkeys.Add_Pressed({
    switch ($_.Id) {
        1 { Start-Timer }
        2 { Pause-Timer }
        3 { Restart-Timer }
        4 { Set-CompactMode (-not $script:compact) }
    }
})
$form.Add_Shown({
    $failed = @($script:hotkeys.Activate())
    if ($failed.Count -gt 0) {
        $names = @($failed | ForEach-Object { $hotkeyActionNames[$_] }) -join ', '
        Show-SoundError "Nao foi possivel ativar: $names. Confira o menu TECLAS para escolher outros atalhos."
    }
})
$compactButton.Add_Click({ Set-CompactMode (-not $script:compact) })
$closeButton.Add_Click({ $form.Close() })
$form.Add_FormClosed({
    $ticker.Stop()
    $ticker.Dispose()
    $musicTimer.Stop()
    $musicTimer.Dispose()
    if ($null -ne $script:spotify) { Reset-SpotifySession $script:spotify }
    if ($null -ne $musicCover.Image) { $musicCover.Image.Dispose(); $musicCover.Image = $null }
    foreach ($icon in $script:musicIconImages) { if ($null -ne $icon) { $icon.Dispose() } }
    $script:clock.Stop()
    $script:hotkeys.Dispose()
    if ($null -ne $script:soundPlayer) {
        $script:soundPlayer.Stop()
        $script:soundPlayer.Dispose()
        $script:soundStream.Dispose()
    }
    $toolTip.Dispose()
    $compactBrandFont.Dispose()
    $compactTimeFont.Dispose()
    $compactBotsFont.Dispose()
    $minimalCloseFont.Dispose()
    $modeButtonFontNormal.Dispose()
    $modeButtonFontCompact.Dispose()
})

# Permite arrastar a janela sem bordas pelas áreas que não são campos ou botões.
# A posição inicial do clique é preservada para evitar que a janela salte.
$dragStart = {
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $script:dragging = $true
        $script:dragOffset = $form.PointToClient([System.Windows.Forms.Cursor]::Position)
    }
}
$dragMove = {
    if ($script:dragging) {
        $position = [System.Windows.Forms.Cursor]::Position
        $form.Location = New-Object System.Drawing.Point(($position.X - $script:dragOffset.X), ($position.Y - $script:dragOffset.Y))
    }
}
$dragEnd = { $script:dragging = $false }
foreach ($control in @($form, $brand, $timeLabel, $statusLabel, $botsLabel, $rule, $minutesLabel, $secondsLabel, $targetLabel)) {
    $control.Add_MouseDown($dragStart)
    $control.Add_MouseMove($dragMove)
    $control.Add_MouseUp($dragEnd)
}

# Reaplica o modo de interface guardado na ultima execucao.
Set-UIMode (Load-ThemeConfig)

[void]$form.ShowDialog()
