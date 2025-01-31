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
Source: "dist\reload.exe"; DestDir: "{app}\utils"; Flags: ignoreversion
Source: "dist\nssm.exe"; DestDir: "{app}\utils"; Flags: ignoreversion

[Run]
Filename: "{app}\utils\nssm.exe"; Parameters: "install TransmitirAS ""{app}\TransmitirAS.exe"""; Flags: runhidden waituntilterminated
Filename: "{app}\utils\nssm.exe"; Parameters: "start TransmitirAS"; Flags: runhidden waituntilterminated

[UninstallRun]
Filename: "{app}\utils\nssm.exe"; Parameters: "stop TransmitirAS"; Flags: runhidden waituntilterminated
Filename: "{app}\utils\nssm.exe"; Parameters: "remove TransmitirAS confirm"; Flags: runhidden waituntilterminated
Filename: "cmd"; Parameters: "/C rmdir /S /Q ""{app}\logs"""; Flags: runhidden

[UninstallDelete]
Type: files; Name: "{app}\config.ini"; 

[Icons]
Name: "{group}\TransmitirAS"; Filename: "{app}\TransmitirAS.exe"
Name: "{group}\Uninstall TransmitirAS"; Filename: "{uninstallexe}"

[Code]
var
  DBPage, BackupPage, SFTPPage, DBCountPage: TWizardPage;
  ServerEdit, UserEdit, PasswordEdit: TEdit;
  BackupFolderEdit, BackupTimeEdit: TEdit;
  CustomBackupCheckBox: TCheckBox;
  SFTPHostEdit, SFTPPortEdit: TEdit;
  DatabaseEdits, SFTPUserEdits, SFTPPasswordEdits: array of TEdit;
  BackupFolderButton: TButton;
  DBCountEdit: TEdit;
  DatabasePagesCreated: Boolean;

procedure BackupFolderButtonClick(Sender: TObject);
var
  SelectedDir: string;
begin
  SelectedDir := BackupFolderEdit.Text;
  if BrowseForFolder('Seleccione la carpeta de respaldo', SelectedDir, True) then
    BackupFolderEdit.Text := SelectedDir;
end;

procedure InitializeWizard();
var
  i: Integer;
  DatabaseLabel, SFTPUserLabel, SFTPPasswordLabel: TLabel;
begin
  DatabasePagesCreated := False;

  // Página 1: Configuración de SQL
  DBPage := CreateCustomPage(wpWelcome, 'Configuración de SQL', 'Ingrese los datos de conexión a SQL');
  with TLabel.Create(DBPage) do
  begin
    Caption := 'Configuración de SQL:';
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
  ServerEdit.Width := DBPage.SurfaceWidth - ScaleX(32);
  ServerEdit.Text := '';
  ServerEdit.Parent := DBPage.Surface;

  with TLabel.Create(DBPage) do
  begin
    Caption := 'Usuario:';
    Top := ServerEdit.Top + ScaleY(32);
    Parent := DBPage.Surface;
  end;
  UserEdit := TEdit.Create(DBPage);
  UserEdit.Top := ServerEdit.Top + ScaleY(48);
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

  // Página 2: Configuración de SFTP
  SFTPPage := CreateCustomPage(DBPage.ID, 'Configuración de SFTP', 'Ingrese los datos del servidor SFTP');
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
  SFTPHostEdit.Width := SFTPPage.SurfaceWidth - ScaleX(32);
  SFTPHostEdit.Text := '104.192.7.152';
  SFTPHostEdit.Parent := SFTPPage.Surface;

  with TLabel.Create(SFTPPage) do
  begin
    Caption := 'Puerto:';
    Top := SFTPHostEdit.Top + ScaleY(32);
    Parent := SFTPPage.Surface;
  end;
  SFTPPortEdit := TEdit.Create(SFTPPage);
  SFTPPortEdit.Top := SFTPHostEdit.Top + ScaleY(48);
  SFTPPortEdit.Width := SFTPHostEdit.Width;
  SFTPPortEdit.Text := '22';
  SFTPPortEdit.Parent := SFTPPage.Surface;

  // Página 3: Número de Bases de Datos
  DBCountPage := CreateCustomPage(SFTPPage.ID, 'Número de Bases de Datos', 'Ingrese el número de bases de datos que desea configurar');
  with TLabel.Create(DBCountPage) do
  begin
    Caption := 'Número de Bases de Datos:';
    Top := ScaleY(16);
    Parent := DBCountPage.Surface;
  end;
  DBCountEdit := TEdit.Create(DBCountPage);
  DBCountEdit.Top := ScaleY(32);
  DBCountEdit.Width := DBCountPage.SurfaceWidth - ScaleX(32);
  DBCountEdit.Text := '1';
  DBCountEdit.Parent := DBCountPage.Surface;

  // Página 4: Configuración de Backup
  BackupPage := CreateCustomPage(DBCountPage.ID, 'Configuración de Backup', 'Ingrese los parámetros de respaldo');
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
  BackupFolderEdit.Width := BackupPage.SurfaceWidth - ScaleX(80);
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

  CustomBackupCheckBox := TCheckBox.Create(BackupPage);
  CustomBackupCheckBox.Caption := 'Respaldo Personalizado';
  CustomBackupCheckBox.Top := BackupTimeEdit.Top + ScaleY(32);
  CustomBackupCheckBox.Parent := BackupPage.Surface;
end;

procedure CurPageChanged(CurPageID: Integer);
var
  i, DBCount: Integer;
  DatabasePage: TWizardPage;
  DatabaseLabel, UserLabel, PasswordLabel: TLabel;
  DatabaseEdit, UserEdit, PasswordEdit: TEdit;
begin
  if (CurPageID = BackupPage.ID) and (not DatabasePagesCreated) then
  begin
    DBCount := StrToInt(DBCountEdit.Text);
    SetLength(DatabaseEdits, DBCount);
    SetLength(SFTPUserEdits, DBCount);
    SetLength(SFTPPasswordEdits, DBCount);

    for i := 0 to DBCount - 1 do
    begin
      DatabasePage := CreateCustomPage(BackupPage.ID, 'Configuración de Base de Datos ' + IntToStr(i + 1), 'Ingrese los datos de conexión a la base de datos ' + IntToStr(i + 1));
      
      DatabaseLabel := TLabel.Create(DatabasePage);
      DatabaseLabel.Caption := 'Base de Datos ' + IntToStr(i + 1) + ':';
      DatabaseLabel.Top := ScaleY(16);
      DatabaseLabel.Parent := DatabasePage.Surface;

      DatabaseEdit := TEdit.Create(DatabasePage);
      DatabaseEdit.Top := DatabaseLabel.Top + ScaleY(16);
      DatabaseEdit.Width := DatabasePage.SurfaceWidth - ScaleX(32);
      DatabaseEdit.Parent := DatabasePage.Surface;
      DatabaseEdits[i] := DatabaseEdit;

      UserLabel := TLabel.Create(DatabasePage);
      UserLabel.Caption := 'Usuario:';
      UserLabel.Top := DatabaseEdit.Top + ScaleY(32);
      UserLabel.Parent := DatabasePage.Surface;

      UserEdit := TEdit.Create(DatabasePage);
      UserEdit.Top := UserLabel.Top + ScaleY(16);
      UserEdit.Width := DatabaseEdit.Width;
      UserEdit.Parent := DatabasePage.Surface;
      SFTPUserEdits[i] := UserEdit;

      PasswordLabel := TLabel.Create(DatabasePage);
      PasswordLabel.Caption := 'Contraseña:';
      PasswordLabel.Top := UserEdit.Top + ScaleY(32);
      PasswordLabel.Parent := DatabasePage.Surface;

      PasswordEdit := TEdit.Create(DatabasePage);
      PasswordEdit.Top := PasswordLabel.Top + ScaleY(16);
      PasswordEdit.Width := DatabaseEdit.Width;
      PasswordEdit.PasswordChar := '*';
      PasswordEdit.Parent := DatabasePage.Surface;
      SFTPPasswordEdits[i] := PasswordEdit;
    end;

    DatabasePagesCreated := True;
  end;
end;

function BoolToString(Value: Boolean): string;
begin
  if Value then
    Result := 'true'
  else
    Result := 'false';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigContent: string;
  i: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    ConfigContent := 
      '[Database]'#13#10 +
      'server=' + ServerEdit.Text + #13#10 +
      'user=' + UserEdit.Text + #13#10 +
      'password=' + PasswordEdit.Text + #13#10 +
      '[Databases]'#13#10;

    for i := 0 to High(DatabaseEdits) do
    begin
      ConfigContent := ConfigContent + 'db' + IntToStr(i + 1) + '=' + DatabaseEdits[i].Text + #13#10;
    end;

    ConfigContent := ConfigContent +
      '[Settings]'#13#10 +
      'backup_folder=' + BackupFolderEdit.Text + #13#10 +
      'backup_time=' + BackupTimeEdit.Text + #13#10 +
      'custom_backup=' + BoolToString(CustomBackupCheckBox.Checked) + #13#10 +
      '[SFTP]'#13#10 +
      'host=' + SFTPHostEdit.Text + #13#10 +
      'port=' + SFTPPortEdit.Text + #13#10;

    for i := 0 to High(DatabaseEdits) do
    begin
      ConfigContent := ConfigContent +
        DatabaseEdits[i].Text + '_username=' + SFTPUserEdits[i].Text + #13#10 +
        DatabaseEdits[i].Text + '_password=' + SFTPPasswordEdits[i].Text + #13#10;
    end;

    SaveStringToFile(ExpandConstant('{app}\config.ini'), ConfigContent, False);
  end;
end;

procedure DeinitializeSetup();
var
  i: Integer;
begin
  for i := 0 to High(DatabaseEdits) do
  begin
    DatabaseEdits[i].Free;
    SFTPUserEdits[i].Free;
    SFTPPasswordEdits[i].Free;
  end;
end;
