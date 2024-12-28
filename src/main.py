import sys
import time
import os
import pyodbc
import pysftp
import configparser
import zipfile
from datetime import datetime, timedelta

class BackupService:
    def __init__(self):
        self.running = True
        self.last_backup_date = None

        # Obtener la ruta del directorio del ejecutable
        if getattr(sys, 'frozen', False):
            # Si el script está empaquetado como un ejecutable
            script_dir = os.path.dirname(sys.executable)
        else:
            # Si el script se está ejecutando en un entorno de desarrollo
            script_dir = os.path.dirname(os.path.abspath(__file__))

        # Cargar configuración
        self.config = configparser.ConfigParser()
        config_path = os.path.join(script_dir, 'config.ini')
        try:
            self.config.read(config_path)  # Lee el archivo de configuración
        except Exception as e:
            self.log_error(f"Error loading config.ini: {str(e)}")
            raise

        # Abrir archivo de logs al inicio
        self.log_file = os.path.join(script_dir, "service_logs.log")
        try:
            with open(self.log_file, "a") as log:
                log.write(f"{datetime.now()}: Service initialized.\n")
        except Exception as e:
            self.log_error(f"Error opening log file: {str(e)}")
            raise

    def log_error(self, message):
        with open(self.log_file, "a") as log:
            log.write(f"{datetime.now()}: ERROR: {message}\n")

    def backup_database(self):
        with open(self.log_file, "a") as log:
            log.write(f"{datetime.now()}: Loading config.ini.\n")

        # Cargar configuración de la base de datos
        try:
            server = self.config['Database']['server']
            database = self.config['Database']['database']
            user = self.config['Database']['user']
            password = self.config['Database']['password']
            backup_folder = self.config['Settings']['backup_folder']
        except KeyError as e:
            self.log_error(f"Missing configuration: {str(e)}")
            return None

        # Asegurarse de que la carpeta de respaldo exista
        os.makedirs(backup_folder, exist_ok=True)

        # Crear el nombre del archivo de respaldo
        backup_file = os.path.join(
            backup_folder,
            f"{database}_{datetime.now().strftime('%Y%m%d')}.bak"
        )

        # Log: Intentando realizar el respaldo
        with open(self.log_file, "a") as log:
            log.write(f"{datetime.now()}: Starting database backup for {database}.\n")

        # Comando de respaldo para SQL Server
        conn_str = f"DRIVER={{SQL Server}};SERVER={server};UID={user};PWD={password}"
        # Dentro del bloque donde ejecutas el respaldo:
        try:
            with pyodbc.connect(conn_str) as conn:
                cursor = conn.cursor()

                # Cerrar cualquier transacción activa antes de realizar el respaldo
                cursor.execute("IF @@TRANCOUNT > 0 COMMIT")  # Commitear cualquier transacción pendiente

                # Verificar si la conexión se ha establecido correctamente
                with open(self.log_file, "a") as log:
                    log.write(f"{datetime.now()}: Connected to SQL Server database '{database}'.\n")

                # Realizar el comando de respaldo
                backup_query = f"BACKUP DATABASE [{database}] TO DISK = '{backup_file}' WITH FORMAT"
                cursor.execute(backup_query)

                time.sleep(5)  # Esperar a que el respaldo se complete
                cursor.commit()

            # Después de ejecutar el comando de respaldo
            if os.path.isfile(backup_file):
                with open(self.log_file, "a") as log:
                    log.write(f"{datetime.now()}: Backup file successfully created: {backup_file}\n")
            else:
                with open(self.log_file, "a") as log:
                    log.write(f"{datetime.now()}: Backup file was not created: {backup_file}\n")

        except Exception as e:
            self.log_error(f"Error during backup: {str(e)}")
            return None

        return backup_file

    def compress_backup(self, backup_file):
        zip_file = backup_file.replace('.bak', '.zip')
        total_size = os.path.getsize(backup_file)
        compressed_size = 0
        last_logged_progress = 0

        try:
            with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
                with open(backup_file, 'rb') as f:
                    while True:
                        chunk = f.read(1024 * 1024)  # Leer en bloques de 1MB
                        if not chunk:
                            break
                        zipf.writestr(os.path.basename(backup_file), chunk)
                        compressed_size += len(chunk)
                        progress = (compressed_size / total_size) * 100
                        if progress - last_logged_progress >= 10:  # Log cada 10%
                            with open(self.log_file, "a") as log:
                                log.write(f"{datetime.now()}: Compression progress: {progress:.2f}%\n")
                            last_logged_progress = progress
        except Exception as e:
            self.log_error(f"Error during compression: {str(e)}")
            return None

        return zip_file

    def upload_to_sftp(self, file_path):
        # Cargar configuración del SFTP
        try:
            sftp_host = self.config['SFTP']['host']
            sftp_username = self.config['SFTP']['username']
            sftp_password = self.config['SFTP']['password']
            sftp_port = int(self.config['SFTP']['port'])
        except KeyError as e:
            self.log_error(f"Missing SFTP config: {str(e)}")
            return

        # Log: Intentando conectar al SFTP
        with open(self.log_file, "a") as log:
            log.write(f"{datetime.now()}: Connecting to SFTP server {sftp_host}...\n")

        # Validar si el archivo existe antes de intentar cargarlo
        if not os.path.isfile(file_path):
            with open(self.log_file, "a") as log:
                log.write(f"{datetime.now()}: File not found: {file_path}\n")
            return

        # Conectar al servidor SFTP y cargar el archivo
        try:
            cnopts = pysftp.CnOpts()
            cnopts.hostkeys = None  # Deshabilitar la validación de hostkeys (no recomendado para producción)

            with pysftp.Connection(sftp_host, username=sftp_username, password=sftp_password, port=sftp_port, cnopts=cnopts) as sftp:
                file_size = os.path.getsize(file_path)
                with open(self.log_file, "a") as log:
                    log.write(f"{datetime.now()}: Starting upload of {file_path} ({file_size} bytes).\n")

                last_logged_progress = 0

                def progress_callback(transferred, total):
                    nonlocal last_logged_progress
                    progress = (transferred / total) * 100
                    if progress - last_logged_progress >= 10:  # Log cada 10%
                        with open(self.log_file, "a") as log:
                            log.write(f"{datetime.now()}: Upload progress: {progress:.2f}%\n")
                        last_logged_progress = progress

                remote_path = os.path.basename(file_path)  # Subir con el mismo nombre
                sftp.put(file_path, remote_path, callback=progress_callback)  # Subir el archivo al servidor SFTP

                # Log: Archivo subido exitosamente
                with open(self.log_file, "a") as log:
                    log.write(f"{datetime.now()}: File {file_path} uploaded to SFTP as {remote_path}.\n")

                # Log de desconexión
                with open(self.log_file, "a") as log:
                    log.write(f"{datetime.now()}: SFTP connection closed.\n")

        except pysftp.ConnectionException as e:
            self.log_error(f"SFTP connection error: {str(e)}")
        except pysftp.AuthenticationException as e:
            self.log_error(f"SFTP authentication error: {str(e)}")
        except Exception as e:
            self.log_error(f"Error during SFTP upload: {str(e)}")

    def main(self):
        with open(self.log_file, "a") as log:
            log.write(f"{datetime.now()}: Starting main cycle.\n")

        backup_time_str = self.config['Settings']['backup_time']

        while self.running:
            try:
                # Calcular la hora del próximo respaldo
                now = datetime.now()
                backup_time = datetime.strptime(backup_time_str, '%H:%M').time()
                next_backup = datetime.combine(now.date(), backup_time)

                if now.time() > backup_time:
                    next_backup += timedelta(days=1)

                    # Verificar si el respaldo ya se ha realizado hoy
                    if self.last_backup_date != now.date():                       

                        # Log: Iniciar proceso de respaldo
                        with open(self.log_file, "a") as log:
                            log.write(f"{datetime.now()}: Starting backup and upload cycle.\n")

                        # Realizar el respaldo
                        backup_file = self.backup_database()
                        if backup_file is None:
                            continue

                        # Comprimir el archivo de respaldo
                        zip_file = self.compress_backup(backup_file)
                        if zip_file is None:
                            continue

                        # Subir el archivo comprimido al SFTP
                        self.upload_to_sftp(zip_file)
                        
                        # Eliminar los archivos locales después de subirlos
                        if os.path.isfile(backup_file):
                            os.remove(backup_file)
                            with open(self.log_file, "a") as log:
                                log.write(f"{datetime.now()}: Local backup file {backup_file} removed.\n")
                        
                        if os.path.isfile(zip_file):
                            os.remove(zip_file)
                            with open(self.log_file, "a") as log:
                                log.write(f"{datetime.now()}: Local zip file {zip_file} removed.\n")

                        # Log: Respaldo completado y archivos eliminados localmente
                        with open(self.log_file, "a") as log:
                            log.write(f"{datetime.now()}: Backup and upload completed. Local files removed.\n")

                        # Actualizar la fecha del último respaldo
                        self.last_backup_date = now.date()
                 # Esperar hasta la hora del próximo respaldo
                sleep_time = (next_backup - now).total_seconds()
                with open(self.log_file, "a") as log:
                    log.write(f"{datetime.now()}: Sleeping until next backup at {next_backup}.\n")
                        
                # Esperar con chequeos periódicos para permitir la detención del servicio
                while sleep_time > 0 and self.running:
                    wait_time = min(sleep_time, 60)  # Esperar en intervalos de 60 segundos
                    time.sleep(wait_time)
                    sleep_time -= wait_time

                if not self.running:
                    break

            except Exception as e:
                # Registrar cualquier error (puedes escribir en un archivo de log o en el registro de eventos de Windows)
                self.log_error(f"Error during backup/upload cycle: {str(e)}")

if __name__ == '__main__':
    service = BackupService()
    service.main()