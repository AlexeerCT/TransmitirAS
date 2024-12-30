[Setup]
AppName=TransmitirAS
AppVersion=1.0
DefaultDirName={pf}\TransmitirAS
OutputDir=.
OutputBaseFilename=TransmitirAS_Installer
DefaultGroupName=TransmitirAS
PrivilegesRequired=admin

[Files]
Source: "dist\TransmitirAS.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\reload.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\config.ini"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\nssm.exe"; DestDir: "{app}"; Flags: ignoreversion

[Run]
Filename: "{app}\nssm.exe"; Parameters: "install TransmitirAS ""{app}\TransmitirAS.exe"""; Flags: runhidden waituntilterminated
Filename: "{app}\nssm.exe"; Parameters: "start TransmitirAS"; Flags: runhidden waituntilterminated

[UninstallRun]
Filename: "{app}\nssm.exe"; Parameters: "stop TransmitirAS"; Flags: runhidden waituntilterminated
Filename: "{app}\nssm.exe"; Parameters: "remove TransmitirAS confirm"; Flags: runhidden waituntilterminated

[UninstallDelete]
Type: files; Name: "{app}\service_logs.log"

[Icons]
Name: "{group}\TransmitirAS"; Filename: "{app}\TransmitirAS.exe"
Name: "{group}\Uninstall TransmitirAS"; Filename: "{uninstallexe}"

[Code]
var
  DBPage, BackupPage, SFTPPage: TWizardPage;
  ServerEdit, DatabaseEdit, UserEdit, PasswordEdit: TEdit;
  BackupFolderEdit, BackupTimeEdit: TEdit;
  SFTPHostEdit, SFTPUserEdit, SFTPPasswordEdit, SFTPPortEdit: TEdit;
  BackupFolderButton: TButton;

procedure BackupFolderButtonClick(Sender: TObject);
var
  SelectedDir: string;
begin
  SelectedDir := BackupFolderEdit.Text;
  if BrowseForFolder('Seleccione la carpeta de respaldo', SelectedDir, True) then
    BackupFolderEdit.Text := SelectedDir;
end;

procedure InitializeWizard();
begin
  // Página 1: Configuración de la base de datos
  DBPage := CreateCustomPage(wpSelectDir, 'Configuración de Base de Datos', 'Ingrese los datos de conexión a la base de datos');
  with TLabel.Create(DBPage) do
  begin
    Caption := 'Configuración de la Base de Datos:';
    Top := ScaleY(16);
    Parent := DBPage.Surface;
  end;

  with TLabel.Create(DBPage) do
  begin
    Caption := 'Servidor:';
    Top := ScaleY(40);
    Parent := DBPage.Surface;
  end;
  ServerEdit := TEdit.Create(DBPage);
  ServerEdit.Top := ScaleY(56);
  ServerEdit.Width := DBPage.SurfaceWidth div 2;
  ServerEdit.Text := '';
  ServerEdit.Parent := DBPage.Surface;

  with TLabel.Create(DBPage) do
  begin
    Caption := 'Base de Datos:';
    Top := ServerEdit.Top + ScaleY(32);
    Parent := DBPage.Surface;
  end;
  DatabaseEdit := TEdit.Create(DBPage);
  DatabaseEdit.Top := ServerEdit.Top + ScaleY(48);
  DatabaseEdit.Width := ServerEdit.Width;
  DatabaseEdit.Text := '';
  DatabaseEdit.Parent := DBPage.Surface;

  with TLabel.Create(DBPage) do
  begin
    Caption := 'Usuario:';
    Top := DatabaseEdit.Top + ScaleY(32);
    Parent := DBPage.Surface;
  end;
  UserEdit := TEdit.Create(DBPage);
  UserEdit.Top := DatabaseEdit.Top + ScaleY(48);
  UserEdit.Width := ServerEdit.Width;
  UserEdit.Text := 'sa';
  UserEdit.Parent := DBPage.Surface;

  with TLabel.Create(DBPage) do
  begin
    Caption := 'Contraseña:';
    Top := UserEdit.Top + ScaleY(32);
    Parent := DBPage.Surface;
  end;
  PasswordEdit := TEdit.Create(DBPage);
  PasswordEdit.Top := UserEdit.Top + ScaleY(48);
  PasswordEdit.Width := ServerEdit.Width;
  PasswordEdit.PasswordChar := '*';
  PasswordEdit.Text := '';
  PasswordEdit.Parent := DBPage.Surface;

  // Página 2: Configuración de Backup
  BackupPage := CreateCustomPage(DBPage.ID, 'Configuración de Backup', 'Ingrese los parámetros de respaldo');
  with TLabel.Create(BackupPage) do
  begin
    Caption := 'Configuración de Backup:';
    Top := ScaleY(16);
    Parent := BackupPage.Surface;
  end;

  with TLabel.Create(BackupPage) do
  begin
    Caption := 'Carpeta de Respaldo:';
    Top := ScaleY(40);
    Parent := BackupPage.Surface;
  end;
  BackupFolderEdit := TEdit.Create(BackupPage);
  BackupFolderEdit.Top := ScaleY(56);
  BackupFolderEdit.Width := BackupPage.SurfaceWidth div 2;
  BackupFolderEdit.Text := '';
  BackupFolderEdit.Parent := BackupPage.Surface;

  BackupFolderButton := TButton.Create(BackupPage);
  BackupFolderButton.Caption := 'Seleccionar...';
  BackupFolderButton.Top := BackupFolderEdit.Top;
  BackupFolderButton.Left := BackupFolderEdit.Left + BackupFolderEdit.Width + ScaleX(8);
  BackupFolderButton.OnClick := @BackupFolderButtonClick;
  BackupFolderButton.Parent := BackupPage.Surface;

  with TLabel.Create(BackupPage) do
  begin
    Caption := 'Hora de Respaldo (HH:MM): ';
    Top := BackupFolderEdit.Top + ScaleY(32);
    Parent := BackupPage.Surface;
  end;
  BackupTimeEdit := TEdit.Create(BackupPage);
  BackupTimeEdit.Top := BackupFolderEdit.Top + ScaleY(48);
  BackupTimeEdit.Width := BackupFolderEdit.Width;
  BackupTimeEdit.Text := '10:00';
  BackupTimeEdit.Parent := BackupPage.Surface;

  // Página 3: Configuración de SFTP
  SFTPPage := CreateCustomPage(BackupPage.ID, 'Configuración de SFTP', 'Ingrese los datos del servidor SFTP');
  with TLabel.Create(SFTPPage) do
  begin
    Caption := 'Configuración de SFTP:';
    Top := ScaleY(16);
    Parent := SFTPPage.Surface;
  end;

  with TLabel.Create(SFTPPage) do
  begin
    Caption := 'Host:';
    Top := ScaleY(40);
    Parent := SFTPPage.Surface;
  end;
  SFTPHostEdit := TEdit.Create(SFTPPage);
  SFTPHostEdit.Top := ScaleY(56);
  SFTPHostEdit.Width := SFTPPage.SurfaceWidth div 2;
  SFTPHostEdit.Text := '104.192.7.152';
  SFTPHostEdit.Parent := SFTPPage.Surface;

  with TLabel.Create(SFTPPage) do
  begin
    Caption := 'Usuario:';
    Top := SFTPHostEdit.Top + ScaleY(32);
    Parent := SFTPPage.Surface;
  end;
  SFTPUserEdit := TEdit.Create(SFTPPage);
  SFTPUserEdit.Top := SFTPHostEdit.Top + ScaleY(48);
  SFTPUserEdit.Width := SFTPHostEdit.Width;
  SFTPUserEdit.Text := '';
  SFTPUserEdit.Parent := SFTPPage.Surface;

  with TLabel.Create(SFTPPage) do
  begin
    Caption := 'Contraseña:';
    Top := SFTPUserEdit.Top + ScaleY(32);
    Parent := SFTPPage.Surface;
  end;
  SFTPPasswordEdit := TEdit.Create(SFTPPage);
  SFTPPasswordEdit.Top := SFTPUserEdit.Top + ScaleY(48);
  SFTPPasswordEdit.Width := SFTPHostEdit.Width;
  SFTPPasswordEdit.PasswordChar := '*';
  SFTPPasswordEdit.Text := '';
  SFTPPasswordEdit.Parent := SFTPPage.Surface;

  with TLabel.Create(SFTPPage) do
  begin
    Caption := 'Puerto:';
    Top := SFTPPasswordEdit.Top + ScaleY(32);
    Parent := SFTPPage.Surface;
  end;
  SFTPPortEdit := TEdit.Create(SFTPPage);
  SFTPPortEdit.Top := SFTPPasswordEdit.Top + ScaleY(48);
  SFTPPortEdit.Width := SFTPHostEdit.Width;
  SFTPPortEdit.Text := '22';
  SFTPPortEdit.Parent := SFTPPage.Surface;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigContent: string;
begin
  if CurStep = ssPostInstall then
  begin
    ConfigContent := 
      '[Database]'#13#10 +
      'server=' + ServerEdit.Text + #13#10 +
      'database=' + DatabaseEdit.Text + #13#10 +
      'user=' + UserEdit.Text + #13#10 +
      'password=' + PasswordEdit.Text + #13#10 +
      '[Settings]'#13#10 +
      'backup_folder=' + BackupFolderEdit.Text + #13#10 +
      'backup_time=' + BackupTimeEdit.Text + #13#10 +
      '[SFTP]'#13#10 +
      'host=' + SFTPHostEdit.Text + #13#10 +
      'username=' + SFTPUserEdit.Text + #13#10 +
      'password=' + SFTPPasswordEdit.Text + #13#10 +
      'port=' + SFTPPortEdit.Text + #13#10;

    SaveStringToFile(ExpandConstant('{app}\config.ini'), ConfigContent, False);
  end;
end;
