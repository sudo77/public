while ($true) {
    # Bewege die Maus um 1 Pixel hin und her
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class MouseJiggler {
        [DllImport("user32.dll", CharSet = CharSet.Auto, CallingConvention = CallingConvention.StdCall)]
        public static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);
        public static void Jiggle() {
            mouse_event(0x0001, 1, 0, 0, 0); // Maus bewegen
            mouse_event(0x0001, -1, 0, 0, 0); // Maus zurückbewegen
        }
    }
"@

    [MouseJiggler]::Jiggle()

    # Alle 5 Minuten ausführen
    Write-Host "keep moving..." -foregroundcolor green
    Start-Sleep -Seconds 120
}