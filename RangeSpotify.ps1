# Consulta a sessão do aplicativo Spotify pelo Windows, sem acessar contas ou APIs externas.
function New-SpotifyState {
    $state = @{
        Available = $false; Error = $null; ManagerTask = $null; Manager = $null
        Session = $null; SessionId = ''; MediaTask = $null; MediaSessionId = ''
        Title = ''; Artist = ''; TrackKey = ''; ArtworkKey = ''; ArtworkBytes = $null
        ArtworkTask = $null; ArtworkStream = $null; ArtworkReader = $null; ReadTask = $null
        LastMediaRequest = [datetime]::MinValue; CommandTask = $null; CommandError = $null
        Playing = $false; CanPlay = $false; CanPause = $false; CanNext = $false; CanPrevious = $false
        Position = 0.0; Duration = 0.0
    }
    try {
        Add-Type -AssemblyName System.Runtime.WindowsRuntime -ErrorAction Stop
        $script:mediaManagerType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType=WindowsRuntime]
        $script:mediaPropertiesType = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionMediaProperties, Windows.Media.Control, ContentType=WindowsRuntime]
        $script:mediaStreamType = [Windows.Storage.Streams.IRandomAccessStreamWithContentType, Windows.Storage.Streams, ContentType=WindowsRuntime]
        $script:mediaReaderType = [Windows.Storage.Streams.DataReader, Windows.Storage.Streams, ContentType=WindowsRuntime]
        $script:mediaRandomStreamType = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType=WindowsRuntime]
        $script:mediaAsTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
            $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1'
        } | Select-Object -First 1
        if ($null -eq $script:mediaAsTask) { throw 'Windows Runtime indisponivel' }
        $state.ManagerTask = ConvertTo-MediaTask ($script:mediaManagerType::RequestAsync()) $script:mediaManagerType
        $state.Available = $true
    } catch {
        $state.Error = 'Controles de midia indisponiveis neste Windows.'
    }
    return $state
}

# As operações assíncronas são verificadas pelo timer da interface, sem bloquear a contagem.
function ConvertTo-MediaTask {
    param($Operation, [Type]$ResultType)
    return $script:mediaAsTask.MakeGenericMethod($ResultType).Invoke($null, @($Operation))
}

function Clear-SpotifyArtwork {
    param($State)
    if ($null -ne $State.ArtworkReader) { try { $State.ArtworkReader.Dispose() } catch { } }
    if ($null -ne $State.ArtworkStream) { try { [void][System.IDisposable].GetMethod('Dispose').Invoke($State.ArtworkStream, @()) } catch { } }
    $State.ArtworkReader = $null
    $State.ArtworkStream = $null
    $State.ArtworkTask = $null
    $State.ReadTask = $null
    $State.ArtworkBytes = $null
    $State.ArtworkKey = ''
}

function Reset-SpotifySession {
    param($State)
    Clear-SpotifyArtwork $State
    $State.Session = $null
    $State.SessionId = ''
    $State.MediaTask = $null
    $State.Title = ''
    $State.Artist = ''
    $State.TrackKey = ''
    $State.LastMediaRequest = [datetime]::MinValue
    $State.CommandTask = $null
    $State.CommandError = $null
    $State.Playing = $false
    $State.CanPlay = $false
    $State.CanPause = $false
    $State.CanNext = $false
    $State.CanPrevious = $false
    $State.Position = 0.0
    $State.Duration = 0.0
}

function Update-SpotifyState {
    param($State)
    if (-not $State.Available) { return }
    try {
        if ($null -eq $State.Manager) {
            if (-not $State.ManagerTask.IsCompleted) { return }
            if ($State.ManagerTask.IsFaulted -or $State.ManagerTask.IsCanceled) { throw 'Falha ao acessar sessoes de midia' }
            $State.Manager = $State.ManagerTask.Result
            $State.ManagerTask = $null
        }
        $session = @($State.Manager.GetSessions() | Where-Object {
            $_.SourceAppUserModelId -match '(?i)(^|[\\.!])spotify(?:\.exe|ab\.spotifymusic)'
        } | Select-Object -First 1)
        if ($session.Count -eq 0) {
            if ($null -ne $State.Session) { Reset-SpotifySession $State }
            return
        }
        $session = $session[0]
        $sessionId = $session.SourceAppUserModelId
        if ($sessionId -ne $State.SessionId) {
            Reset-SpotifySession $State
            $State.SessionId = $sessionId
        }
        $State.Session = $session
        $playback = $session.GetPlaybackInfo()
        $State.Playing = ([string]$playback.PlaybackStatus -eq 'Playing')
        $State.CanPlay = $playback.Controls.IsPlayEnabled
        $State.CanPause = $playback.Controls.IsPauseEnabled
        $State.CanNext = $playback.Controls.IsNextEnabled
        $State.CanPrevious = $playback.Controls.IsPreviousEnabled
        $timeline = $session.GetTimelineProperties()
        $State.Duration = [Math]::Max(0, ($timeline.EndTime - $timeline.StartTime).TotalSeconds)
        $position = ($timeline.Position - $timeline.StartTime).TotalSeconds
        if ($State.Playing -and $State.Duration -gt 0) {
            $elapsed = ([DateTimeOffset]::UtcNow - $timeline.LastUpdatedTime).TotalSeconds
            if ($elapsed -gt 0 -and $elapsed -lt 86400) { $position += $elapsed }
        }
        $State.Position = [Math]::Max(0, [Math]::Min($State.Duration, $position))

        if ($null -ne $State.CommandTask -and $State.CommandTask.IsCompleted) {
            if ($State.CommandTask.IsFaulted -or $State.CommandTask.IsCanceled -or -not $State.CommandTask.Result) {
                $State.CommandError = 'Spotify nao aceitou o comando.'
            } else { $State.CommandError = $null }
            $State.CommandTask = $null
        }
        if ($null -ne $State.MediaTask -and $State.MediaTask.IsCompleted) {
            $mediaTask = $State.MediaTask
            $State.MediaTask = $null
            if (-not $mediaTask.IsFaulted -and -not $mediaTask.IsCanceled -and $State.MediaSessionId -eq $sessionId) {
                $properties = $mediaTask.Result
                if ($null -ne $properties) {
                    $trackKey = '{0}`n{1}`n{2}' -f $properties.Title, $properties.Artist, $properties.AlbumTitle
                    if ($trackKey -ne $State.TrackKey) {
                        Clear-SpotifyArtwork $State
                        $State.TrackKey = $trackKey
                    }
                    $State.Title = $properties.Title
                    $State.Artist = $properties.Artist
                    if ($null -ne $properties.Thumbnail -and $State.ArtworkKey -ne $trackKey) {
                        $State.ArtworkKey = $trackKey
                        try { $State.ArtworkTask = ConvertTo-MediaTask ($properties.Thumbnail.OpenReadAsync()) $script:mediaStreamType } catch { }
                    }
                }
            }
        }
        if ($null -eq $State.MediaTask -and ([datetime]::UtcNow - $State.LastMediaRequest).TotalSeconds -ge 2) {
            $State.MediaSessionId = $sessionId
            $State.MediaTask = ConvertTo-MediaTask ($session.TryGetMediaPropertiesAsync()) $script:mediaPropertiesType
            $State.LastMediaRequest = [datetime]::UtcNow
        }
        try {
            if ($null -ne $State.ArtworkTask -and $State.ArtworkTask.IsCompleted) {
                $artworkTask = $State.ArtworkTask
                $State.ArtworkTask = $null
                if (-not $artworkTask.IsFaulted -and -not $artworkTask.IsCanceled) {
                    $State.ArtworkStream = $artworkTask.Result
                    $streamSize = if ($null -ne $State.ArtworkStream) { $script:mediaRandomStreamType.GetProperty('Size').GetValue($State.ArtworkStream, $null) } else { 0 }
                    if ($streamSize -gt 0 -and $streamSize -le 5242880) {
                        $State.ArtworkReader = $script:mediaReaderType.GetConstructors()[0].Invoke(@($State.ArtworkStream))
                        $State.ReadTask = ConvertTo-MediaTask ($State.ArtworkReader.LoadAsync([uint32]$streamSize)) ([uint32])
                    } else { Clear-SpotifyArtwork $State; $State.ArtworkKey = $State.TrackKey }
                } else { Clear-SpotifyArtwork $State; $State.ArtworkKey = $State.TrackKey }
            }
            if ($null -ne $State.ReadTask -and $State.ReadTask.IsCompleted) {
                $readTask = $State.ReadTask
                $State.ReadTask = $null
                if (-not $readTask.IsFaulted -and -not $readTask.IsCanceled -and $readTask.Result -gt 0) {
                    $bytes = New-Object byte[] ([int]$readTask.Result)
                    $State.ArtworkReader.ReadBytes($bytes)
                    $State.ArtworkBytes = $bytes
                    $State.ArtworkReader.Dispose()
                    try { [void][System.IDisposable].GetMethod('Dispose').Invoke($State.ArtworkStream, @()) } catch { }
                    $State.ArtworkReader = $null
                    $State.ArtworkStream = $null
                } else { Clear-SpotifyArtwork $State; $State.ArtworkKey = $State.TrackKey }
            }
        } catch {
            Clear-SpotifyArtwork $State
            $State.ArtworkKey = $State.TrackKey
        }
    } catch {
        Reset-SpotifySession $State
        $State.Available = $false
        $State.Error = 'Nao foi possivel acessar os controles de midia do Windows.'
    }
}

function Send-SpotifyCommand {
    param($State, [string]$Action)
    if ($null -eq $State.Session -or $null -ne $State.CommandTask) { return }
    try {
        $operation = switch ($Action) {
            'Play' { $State.Session.TryPlayAsync() }
            'Pause' { $State.Session.TryPauseAsync() }
            'Next' { $State.Session.TrySkipNextAsync() }
            'Previous' { $State.Session.TrySkipPreviousAsync() }
        }
        if ($null -ne $operation) {
            $State.CommandError = $null
            $State.CommandTask = ConvertTo-MediaTask $operation ([bool])
        }
    } catch { $State.CommandError = 'Nao foi possivel enviar o comando ao Spotify.' }
}
