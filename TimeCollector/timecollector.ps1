# Konfiguration: Pfad zur CSV-Datei (anpassen!)
# C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
# -NonInteractive -WindowStyle Hidden -command C:\zeiterfassung\timecollector.ps1
# Trigger für Start: Beim Systemstart (Ereignis-ID 1 von Kernel-General) wird der Task ausgelöst.
# Trigger für Ende: Beim Abmelden/Herunterfahren (Ereignis-ID 1074 von USER32) wird der Task aktiviert.
$csvPath = "C:\zeiterfassung\Zeiterfassung.csv"

# Pause in Minuten (anpassen!)
$pause = 30

# Aktuelles Datum und Zeit
$heute = Get-Date -Format "dd.MM.yyyy"
$jetzt = Get-Date

# Falls die CSV noch nicht existiert, lege sie mit Header an.
if (-not (Test-Path $csvPath)) {
    "Start_____Zeitpunkt;End_____Zeitpunkt;SummeTag;SummeWoche" | Out-File -FilePath $csvPath -Encoding UTF8
}

# CSV einlesen
$data = Import-Csv -Path $csvPath -Delimiter ';'

# Funktion zur Formatierung der Zeitspanne
function Format-Dauer($timespan) {
    return $timespan.ToString("hh\:mm\:ss")
}

# Funktion, um ISO-Wochenzahl zu ermitteln (ISO 8601: Montag als erster Tag der Woche)
function Get-IsoWeekNumber([datetime]$date) {
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    return $culture.Calendar.GetWeekOfYear($date, [System.Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday)
}

# Sucht nach einem offenen Eintrag (ohne Ende) für heute
$offenerEintrag = $data | Where-Object { $_.Start_____Zeitpunkt -like "$heute*" -and ([string]::IsNullOrWhiteSpace($_.End_____Zeitpunkt)) }

if (-not $offenerEintrag) {
    # Neuer Eintrag: Session starten
    $startZeit = $jetzt.ToString("dd.MM.yyyy HH:mm:ss")
    $newEntry = [PSCustomObject]@{
        Start_____Zeitpunkt = $startZeit
        End_____Zeitpunkt   = ""
        SummeTag            = ""
        SummeWoche          = ""
    }

    # Append the new entry to the CSV file
    $newEntry | Export-Csv -Path $csvPath -Append -NoTypeInformation -Delimiter ';'
    Write-Output "Session gestartet: $startZeit"
}
else {
    # Bestehender Eintrag für heute schließen
    $startString = $offenerEintrag.Start_____Zeitpunkt  # z.B. "23.02.2025 08:30:15"
    try {
        $startDateTime = [datetime]::ParseExact($startString, "dd.MM.yyyy HH:mm:ss", $null)
    }
    catch {
        Write-Error "Fehler beim Parsen des Start-Zeitpunkts: $startString"
        exit 1
    }
    $endeZeit = $jetzt
    $differenz = $endeZeit - $startDateTime

    # Subtrahiere die Pause von der Gesamtdauer
    $differenz = $differenz - [TimeSpan]::FromMinutes($pause)
    $summeTag = Format-Dauer($differenz)

    # Aktualisieren des Eintrags: Endzeit und SummeTag eintragen
    $data | ForEach-Object {
        if ($_.Start_____Zeitpunkt -eq $startString -and ([string]::IsNullOrWhiteSpace($_.End_____Zeitpunkt))) {
            $_.End_____Zeitpunkt = $endeZeit.ToString("dd.MM.yyyy HH:mm:ss")
            $_.SummeTag = $summeTag
        }
    }

    # Um SummeWoche zu berechnen, gruppieren wir alle Einträge nach Woche und Jahr
    # (Wir parsen dazu die Start-Zeit, sofern vorhanden und gültig)
    foreach ($entry in $data) {
        if ($entry.Start_____Zeitpunkt -ne $null -and $entry.Start_____Zeitpunkt -match "\d{2}\.\d{2}\.\d{4}") {
            $entryDate = [datetime]::ParseExact($entry.Start_____Zeitpunkt.Substring(0,10), "dd.MM.yyyy", $null)
            $entry | Add-Member -NotePropertyName IsoWeek -NotePropertyValue (Get-IsoWeekNumber($entryDate)) -Force
            $entry | Add-Member -NotePropertyName Year -NotePropertyValue $entryDate.Year -Force
        }
        else {
            $entry | Add-Member -NotePropertyName IsoWeek -NotePropertyValue $null -Force
            $entry | Add-Member -NotePropertyName Year -NotePropertyValue $null -Force
        }
    }

    # Gruppiere nach Jahr und IsoWeek und berechne die Summe der Tagesdauern
    $groups = $data | Group-Object -Property Year, IsoWeek

    # Für jede Gruppe summieren wir die SummeTag (falls vorhanden) und aktualisieren die Einträge
    foreach ($grp in $groups) {
        $totalSeconds = 0
        foreach ($item in $grp.Group) {
            if (-not [string]::IsNullOrWhiteSpace($item.SummeTag)) {
                # Parse SummeTag (hh:mm:ss) in Sekunden
                $parts = $item.SummeTag.Split(":")
                if ($parts.Length -eq 3) {
                    $seconds = [int]$parts[0]*3600 + [int]$parts[1]*60 + [int]$parts[2]
                    $totalSeconds += $seconds
                }
            }
        }
        # Gesamtzeit als TimeSpan
        $totalTimeSpan = [TimeSpan]::FromSeconds($totalSeconds)
        $summeWocheStr = Format-Dauer($totalTimeSpan)

        # Aktualisiere SummeWoche für alle Einträge der Gruppe
        foreach ($item in $grp.Group) {
            $item.SummeWoche = $summeWocheStr
        }
    }

    # Schreibe alle Daten zurück in die CSV (ohne zusätzlichen Header)
    $data | Select-Object Start_____Zeitpunkt,End_____Zeitpunkt,SummeTag,SummeWoche | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ';'

    Write-Output "Session beendet: Ende = $($endeZeit.ToString("dd.MM.yyyy HH:mm:ss")); SummeTag = $summeTag"
    Write-Output "Wöchentliche Summe aktualisiert."
}
