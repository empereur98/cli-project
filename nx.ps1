$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
bash "$ScriptDir/nx" @args
