function New-GUI {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Dynamic PowerShell GUI"
    $form.Size = New-Object System.Drawing.Size(600, 400)
    $form.StartPosition = "CenterScreen"

    return $form
}