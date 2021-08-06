
$ProgressPreference = 'SilentlyContinue'

Write-Output "Downloading SQLCipher zip"
Invoke-WebRequest -Uri "https://github.com/sqlcipher/sqlcipher/archive/refs/tags/v4.4.3.zip" -OutFile "sqlcipher.zip"

Write-Output "Extracting SQLCipher source code"
Expand-Archive -Force -Path sqlcipher.zip -DestinationPath ./

Remove-Item sqlcipher.zip

# assume you have vs build tools, otherwise, correct the path
# https://stackoverflow.com/a/2124759
pushd "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\Common7\Tools"
cmd /c "VsDevCmd.bat&set" |
foreach {
  if ($_ -match "=") {
    $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
  }
}
popd
Write-Host "`nVisual Studio 2017 Command Prompt variables set." -ForegroundColor Yellow

cd sqlcipher-*

mkdir build
cd build
cp ..\Makefile.msc .\

# it can make some errors, but sqlite3.[ch] are the files of our interest, not dll or exes
nmake /f Makefile.msc CFLAGS="-DSQLITE_HAS_CODEC" TOP=..\ | Out-Null

# TODO check if sqlite.[ch] are not empty files - if yes, error

cd ../..

Write-Output "Downloading SQLCipher3 python binding zip"
Invoke-WebRequest -Uri "https://github.com/lstolcman/sqlcipher3/archive/refs/heads/master.zip" -OutFile "sqlcipher3.zip"

Write-Output "Extracting SQLCipher3 python binding source code"
Expand-Archive -Force -Path sqlcipher3.zip -DestinationPath ./
Remove-Item sqlcipher3.zip

cd sqlcipher3-master
cp ../sqlcipher-*/build/sqlite3.[ch] .

# to build .whl file
pip install wheel

# openssl "full" 64bit https://slproweb.com/download/Win64OpenSSL-1_1_1k.exe
# choco install openssl --version 1.1.1.1100 # == 1.1.1k
# default path:
# $env:OPENSSL_DIR="C:\Program Files\OpenSSL-Win64"

# build pyd
python setup.py build_static

# build whl
python setup.py bdist_wheel

# install by: pip install sqlcipher3-0.4.5-cp39-cp39-win_amd64.whl
