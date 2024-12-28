; Script generado por el asistente de Inno Setup.
; Ajustado para instalar TransmitirAS como un servicio usando NSSM.

[Setup]
; Nombre del instalador
AppName=TransmitirAS
; Versión de la aplicación
AppVersion=1.0
; Carpeta de salida del instalador
DefaultDirName={pf}\TransmitirAS
; Nombre del archivo del instalador
OutputDir=.
OutputBaseFilename=TransmitirAS_Installer
; Idioma del instalador
DefaultGroupName=TransmitirAS
; Requiere privilegios de administrador
PrivilegesRequired=admin

[Files]
; Archivos a incluir en el instalador
Source: "src\dist\TransmitirAS.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "src\dist\reload.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "src\dist\config.ini"; DestDir: "{app}"; Flags: ignoreversion
Source: "src\dist\nssm.exe"; DestDir: "{app}"; Flags: ignoreversion

[Run]
; Comandos para ejecutar después de la instalación
; Instalar TransmitirAS como servicio con NSSM sin GUI
Filename: "{app}\nssm.exe"; Parameters: "install TransmitirAS ""{app}\TransmitirAS.exe"""; Flags: runhidden waituntilterminated
; Iniciar el servicio después de instalarlo
Filename: "{app}\nssm.exe"; Parameters: "start TransmitirAS"; Flags: runhidden waituntilterminated

[Icons]
; Crear accesos directos
Name: "{group}\TransmitirAS"; Filename: "{app}\TransmitirAS.exe"
Name: "{group}\Uninstall TransmitirAS"; Filename: "{uninstallexe}"
