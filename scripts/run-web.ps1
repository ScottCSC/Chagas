# Desarrollo local en Edge con credenciales de .env (archivo gitignored).
Set-Location $PSScriptRoot\..
flutter run -d edge --dart-define-from-file=.env @args
