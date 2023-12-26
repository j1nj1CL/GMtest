::By j1nj1 
::Github https://github.com/j1nj1CL
::wx wx_f0r_work
@echo off
IF EXIST temp.txt ( del temp.txt ) 
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: %0 [domain or IP]
    exit /b 1
)

set "SERVER=%~1"
set "PORT=443"

for /f "tokens=*" %%i in ('openssl.exe ciphers -v') do (
    set "CIPHER_INFO=%%i"
    for /f "tokens=1,2" %%a in ("!CIPHER_INFO!") do (
        set "CIPHER_NAME=%%a"
        set "TLS_VERSION=%%b"

        if "!TLS_VERSION!"=="TLSv1.3" (
            echo | openssl.exe s_client -ciphersuites "!CIPHER_NAME!" -connect %SERVER%:%PORT% > temp.txt 2>&1
        ) else (
            if "!TLS_VERSION!"=="NTLSv1.1" (
                echo | openssl.exe s_client -enable_ntls -ntls -cipher "!CIPHER_NAME!" -connect %SERVER%:%PORT% > temp.txt 2>&1
            ) else (
                if "!TLS_VERSION!"=="TLSv1.2" (
                    echo | openssl.exe s_client -tls1_2 -cipher "!CIPHER_NAME!" -connect %SERVER%:%PORT% > temp.txt 2>&1
                ) else (
                    if "!TLS_VERSION!"=="TLSv1" (
                        echo | openssl.exe s_client -tls1 -cipher "!CIPHER_NAME!" -connect %SERVER%:%PORT% > temp.txt 2>&1
                    ) else (
                        if "!TLS_VERSION!"=="SSLv3" (
                            echo | openssl.exe s_client -ssl3 -cipher "!CIPHER_NAME!" -connect %SERVER%:%PORT% > temp.txt 2>&1
                        ) else (
                            echo | openssl.exe s_client -cipher "!CIPHER_NAME!" -connect %SERVER%:%PORT% > temp.txt 2>&1
                        )
                    )
                )
            )
        )

        findstr /C:"Cipher is !CIPHER_NAME!" temp.txt >nul
        if not errorlevel 1 (
            echo Supported Cipher: !CIPHER_INFO!
        )
    )
)

del temp.txt

endlocal
