# pre-requirements:
# openssl "full" 64bit: https://slproweb.com/download/Win64OpenSSL-1_1_1k.exe
# tcl: https://sourceforge.net/projects/magicsplat/files/magicsplat-tcl/tcl-8.6.11-installer-1.11.2-x64.msi/download


$ProgressPreference = 'SilentlyContinue'

Write-Output "Downloading SQLCipher zip"
Invoke-WebRequest -Uri "https://github.com/sqlcipher/sqlcipher/archive/refs/tags/v4.4.3.zip" -OutFile "sqlcipher.zip"

Write-Output "Extracting SQLCipher source code"
Expand-Archive -Force -Path sqlcipher.zip -DestinationPath ./

Remove-Item sqlcipher.zip

# assume you have vs build tools, otherwise, correct the path
# https://stackoverflow.com/a/2124759
# pushd "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\Common7\Tools"
pushd "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\VC\Auxiliary\Build"
# cmd /c "VsDevCmd.bat&set" |
cmd /c "vcvars64.bat&set" |
foreach {
  if ($_ -match "=") {
    $v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
  }
}
popd
Write-Host "`nVisual Studio 2017 Command Prompt variables set." -ForegroundColor Yellow

mkdir sqlcipher-build
cd sqlcipher-build

# build sqlite amalgamation
nmake /f ..\sqlcipher-4.4.3\Makefile.msc sqlite3.c CFLAGS="-DSQLITE_HAS_CODEC" TOP=..\sqlcipher-4.4.3

# TODO check if sqlite.[ch] are not empty files - if yes, error

cd ..

Write-Output "Downloading SQLCipher3 python binding zip"
Invoke-WebRequest -Uri "https://github.com/lstolcman/sqlcipher3/archive/refs/heads/master.zip" -OutFile "sqlcipher3.zip"

Write-Output "Extracting SQLCipher3 python binding source code"
Expand-Archive -Force -Path sqlcipher3.zip -DestinationPath ./
Remove-Item sqlcipher3.zip

# to build .whl file
python -m venv venv
.\venv\scripts\activate
pip install wheel

cd sqlcipher3-master
cp ../sqlcipher-build/sqlite3.[ch] .

# build pyd
python setup.py build_static

# build whl
python setup.py bdist_wheel

cp .\dist\*whl ..\

cd ..

Remove-Item -Force -Recurse venv
Remove-Item -Force -Recurse sqlcipher3-master
Remove-Item -Force -Recurse sqlcipher-4.4.3
Remove-Item -Force -Recurse sqlcipher-build

# installing result .whl: pip install sqlcipher3-0.4.5-cp39-cp39-win_amd64.whl
