Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form with increased size
$form = New-Object System.Windows.Forms.Form
$form.Text = "System Info Dashboard"
$form.Size = New-Object System.Drawing.Size(800, 700)  # Increased overall window size
$form.StartPosition = "CenterScreen"

# Output box with larger font
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.Location = New-Object System.Drawing.Point -ArgumentList 20, 20
$outputBox.Size = New-Object System.Drawing.Size(740, 450)  # Adjusted to fill the larger form
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 12)
$form.Controls.Add($outputBox)

# Function to show output in the output box
function Show-Output {
    param ($text)
    $outputBox.Text = $text
}

# Function to update the UI theme based on the selected mode
function Set-Theme {
    param ([string]$theme)
    if ($theme -eq "Dark") {
        $form.BackColor       = [System.Drawing.Color]::FromArgb(45,45,48)
        $form.ForeColor       = [System.Drawing.Color]::White
        $outputBox.BackColor  = [System.Drawing.Color]::FromArgb(30,30,30)
        $outputBox.ForeColor  = [System.Drawing.Color]::White
        
        foreach ($ctrl in $form.Controls) {
            if ($ctrl -is [System.Windows.Forms.Button]) {
                $ctrl.BackColor = [System.Drawing.Color]::FromArgb(63,63,70)
                $ctrl.ForeColor = [System.Drawing.Color]::White
            }
        }
        # Update toggle checkbox colors for consistency
        $toggleThemeCheckBox.BackColor = [System.Drawing.Color]::FromArgb(45,45,48)
        $toggleThemeCheckBox.ForeColor = [System.Drawing.Color]::White
        $toggleThemeCheckBox.Text = "Dark Mode"
        
        # Update the credits label colors if it exists
        if ($creditsLabel -ne $null) {
            $creditsLabel.BackColor = $form.BackColor
            $creditsLabel.ForeColor = $form.ForeColor
        }
    }
    else {
        $form.BackColor       = [System.Drawing.SystemColors]::Control
        $form.ForeColor       = [System.Drawing.Color]::Black
        $outputBox.BackColor  = [System.Drawing.Color]::White
        $outputBox.ForeColor  = [System.Drawing.Color]::Black
        
        foreach ($ctrl in $form.Controls) {
            if ($ctrl -is [System.Windows.Forms.Button]) {
                $ctrl.BackColor = [System.Drawing.SystemColors]::Control
                $ctrl.ForeColor = [System.Drawing.Color]::Black
            }
        }
        # Update toggle checkbox colors for consistency
        $toggleThemeCheckBox.BackColor = [System.Drawing.SystemColors]::Control
        $toggleThemeCheckBox.ForeColor = [System.Drawing.Color]::Black
        $toggleThemeCheckBox.Text = "Light Mode"
        
        # Update the credits label colors if it exists
        if ($creditsLabel -ne $null) {
            $creditsLabel.BackColor = $form.BackColor
            $creditsLabel.ForeColor = $form.ForeColor
        }
    }
}

# Create a toggle checkbox for theme selection
$toggleThemeCheckBox = New-Object System.Windows.Forms.CheckBox
$toggleThemeCheckBox.Text = "Dark Mode"      # Label indicates current theme
$toggleThemeCheckBox.Checked = $true         # Start with dark mode
$toggleThemeCheckBox.AutoSize = $true
$toggleThemeCheckBox.Location = New-Object System.Drawing.Point -ArgumentList 20, 480
$form.Controls.Add($toggleThemeCheckBox)

# Event: When the checkbox state changes, update the theme
$toggleThemeCheckBox.Add_CheckedChanged({
    if ($toggleThemeCheckBox.Checked) {
        Set-Theme "Dark"
    } else {
        Set-Theme "Light"
    }
})

# Button definitions for system information
$buttonData = @(
    @{
        Text = "Logged-in Users"
        Action = {
            try {
                $users = (Get-CimInstance Win32_ComputerSystem).UserName
                if (-not $users) { $users = "No interactive user is currently logged in." }
            } catch { $users = "Unable to retrieve logged-in users." }
            Show-Output -text $users
        }
    },
    @{
        Text = "CPU Usage"
        Action = {
            $cpu = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 ProcessName, CPU | Out-String
            Show-Output -text $cpu
        }
    },
    @{
        Text = "Memory Usage"
        Action = {
            $mem = Get-Process | Sort-Object WorkingSet -Descending |
                Select-Object -First 10 ProcessName, @{Name="Memory(MB)";Expression={[math]::round($_.WorkingSet / 1MB, 2)}} |
                Out-String
            Show-Output -text $mem
        }
    },
    @{
        Text = "App Runtime"
        Action = {
            $apps = Get-Process | Where-Object { $_.MainWindowTitle } |
                Select-Object ProcessName, StartTime | Out-String
            Show-Output -text $apps
        }
    },
    @{
        Text = "Free Memory"
        Action = {
            $freeMem = Get-CimInstance Win32_OperatingSystem |
                Select-Object @{Name='FreePhysicalMemory(MB)';Expression={[math]::Round($_.FreePhysicalMemory / 1024, 2)}},
                              @{Name='TotalVisibleMemory(MB)';Expression={[math]::Round($_.TotalVisibleMemorySize / 1024, 2)}} |
                Out-String
            Show-Output -text $freeMem
        }
    }
)

# Layout and create system info buttons dynamically
$buttonWidth = 160
$buttonHeight = 35
$paddingX = 20
$paddingY = 10
$startY = $toggleThemeCheckBox.Location.Y + $toggleThemeCheckBox.Height + 10

for ($i = 0; $i -lt $buttonData.Count; $i++) {
    $row = [int]($i / 3)
    $col = [int]($i % 3)

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $buttonData[$i].Text
    $btn.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
    $xPos = $paddingX + ($col * ($buttonWidth + 20))
    $yPos = $startY + ($row * ($buttonHeight + $paddingY))
    $btn.Location = New-Object System.Drawing.Point -ArgumentList $xPos, $yPos
    $btn.Add_Click($buttonData[$i].Action)
    $form.Controls.Add($btn)
}

# Determine Y-position for font size control buttons based on system info buttons
$fontControlY = $startY + ([math]::Ceiling($buttonData.Count / 3) * ($buttonHeight + $paddingY)) + 10

# Button to Increase Font Size of the Output Box
$increaseFontButton = New-Object System.Windows.Forms.Button
$increaseFontButton.Text = "Increase Font"
$increaseFontButton.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
$increaseFontButton.Location = New-Object System.Drawing.Point -ArgumentList $paddingX, $fontControlY
$increaseFontButton.Add_Click({
    $currentSize = $outputBox.Font.Size
    $newSize = $currentSize + 2
    $outputBox.Font = New-Object System.Drawing.Font($outputBox.Font.FontFamily, $newSize, $outputBox.Font.Style)
})
$form.Controls.Add($increaseFontButton)

# Button to Decrease Font Size of the Output Box
$decreaseFontButton = New-Object System.Windows.Forms.Button
$decreaseFontButton.Text = "Decrease Font"
$decreaseFontButton.Size = New-Object System.Drawing.Size($buttonWidth, $buttonHeight)
$decreaseFontButton.Location = New-Object System.Drawing.Point -ArgumentList ($paddingX + $buttonWidth + 20), $fontControlY
$decreaseFontButton.Add_Click({
    $currentSize = $outputBox.Font.Size
    if (($currentSize - 2) -ge 6) {
        $newSize = $currentSize - 2
        $outputBox.Font = New-Object System.Drawing.Font($outputBox.Font.FontFamily, $newSize, $outputBox.Font.Style)
    }
})
$form.Controls.Add($decreaseFontButton)

# Create a label for the credits in the bottom-right corner
$creditsLabel = New-Object System.Windows.Forms.Label
$creditsLabel.Text = "Made by Yuvraj Gupta"
# Use a bold font (you can adjust the font family and size as desired)
$creditsLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$creditsLabel.AutoSize = $true
# Anchor the label to the Bottom and Right so it stays in the corner regardless of resizing
$creditsLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Right
# Set an initial location using the form's client size and a margin of 10 pixels
$creditsLabel.Location = New-Object System.Drawing.Point -ArgumentList ($form.ClientSize.Width - $creditsLabel.PreferredWidth - 10), ($form.ClientSize.Height - $creditsLabel.PreferredHeight - 10)
$form.Controls.Add($creditsLabel)

# Apply the initial theme (Dark mode by default)
Set-Theme "Dark"

# Display the form
$form.Topmost = $true
$form.ShowDialog()
