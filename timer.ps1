# Carrega os componentes de interface e desenho disponíveis no Windows.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -Path (Join-Path $PSScriptRoot 'RangeAudio.cs')
Add-Type -Path (Join-Path $PSScriptRoot 'RangeHotkeys.cs') -ReferencedAssemblies System.Windows.Forms, System.Drawing -ErrorAction Stop
. (Join-Path $PSScriptRoot 'RangeSpotify.ps1')

[System.Windows.Forms.Application]::EnableVisualStyles()

# Define as cores e a fonte usadas em toda a interface.
$background = [System.Drawing.Color]::FromArgb(16, 23, 31)
$surface = [System.Drawing.Color]::FromArgb(28, 37, 47)
$foreground = [System.Drawing.Color]::FromArgb(236, 232, 225)
$muted = [System.Drawing.Color]::FromArgb(151, 162, 171)
$accent = [System.Drawing.Color]::FromArgb(255, 70, 85)
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
[void](Add-MusicLabel 'TOCANDO AGORA / SPOTIFY' 10 5 240 18 8 $accent)
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
$previousTrack = Add-MusicButton 'ANTERIOR' 10 76
$playTrack = Add-MusicButton 'PLAY' 94 76
$nextTrack = Add-MusicButton 'PROXIMA' 178 76
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
    foreach ($control in $settingsControls) {
        $control.Visible = -not $Compact
    }

    if ($Compact) {
        $form.ClientSize = New-Object System.Drawing.Size(264, (112 + $(if ($script:musicVisible) { 146 } else { 0 })))
        $musicPanel.Location = New-Object System.Drawing.Point(0, 112)
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
    } else {
        $form.ClientSize = New-Object System.Drawing.Size(372, (254 + $(if ($script:musicVisible) { 146 } else { 0 })))
        $musicPanel.Location = New-Object System.Drawing.Point(54, 254)
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
    }

    $workingArea = [System.Windows.Forms.Screen]::FromControl($form).WorkingArea
    $left = [Math]::Max($workingArea.Left, [Math]::Min($form.Left, $workingArea.Right - $form.Width))
    $top = [Math]::Max($workingArea.Top, [Math]::Min($form.Top, $workingArea.Bottom - $form.Height))
    $form.Location = New-Object System.Drawing.Point($left, $top)
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
    $playTrack.Text = if ($state.Playing) { 'PAUSAR' } else { 'PLAY' }
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
    $musicPanel.Visible = $script:musicVisible
    Set-CompactMode $script:compact
    if ($script:musicVisible) {
        if ($null -eq $script:spotify -or -not $script:spotify.Available) { $script:spotify = New-SpotifyState }
        Update-MusicPanel
        $musicTimer.Start()
    } else { $musicTimer.Stop() }
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

[void]$form.ShowDialog()
