# pre-requirements:
# openssl "full" 64bit: https://slproweb.com/download/Win64OpenSSL-1_1_1k.exe
# tcl: https://sourceforge.net/projects/magicsplat/files/magicsplat-tcl/tcl-8.6.11-installer-1.11.2-x64.msi/download
# visual studio build tools or visualstudio c++


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


# copy sqlcipher amalgamation files into root directory
cp .\sqlite3.[ch] ..\..
cd ..\..


# .whl build requirement
python -m venv venv
.\venv\scripts\activate
pip install wheel

# build pyd
python setup.py build_static

# build whl
python setup.py bdist_wheel

# cleanup
Remove-Item -Force -Recurse .\venv
Remove-Item -Force -Recurse .\build-scripts\sqlcipher-4.4.3
Remove-Item -Force -Recurse .\build-scripts\sqlcipher-build
Remove-Item -Force -Recurse .\sqlcipher
Remove-Item sqlite3.[ch]

# installing result .whl: pip install sqlcipher3-0.4.5-cp39-cp39-win_amd64.whl
