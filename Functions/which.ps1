function which {
    param ($cmd)
    (Get-Command $cmd).Path
}