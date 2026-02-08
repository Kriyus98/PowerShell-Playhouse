function HelloWorld {
    param(
        [Parameter(Mandatory = $true)]
        [string]$string
    )
    Write-Host "Writing input: $string!"
}

function HelloWorld2 {
    param(
        [Parameter(Mandatory = $true)]
        [string]$string,
        [Parameter(Mandatory = $true)]
        [int]$number
    )
    Write-Host "Writing input: $string! Number: $number"
}