import sys
import time
import os
import pyodbc
import pysftp
import configparser
import zipfile
import logging
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
        self.load_config(config_path)

        self.custom_backup = self.config.getboolean('Settings', 'custom_backup', fallback=False)

        # Crear directorios de logs si no existen
        log_dir = os.path.join(script_dir, 'logs')
        service_log_dir = os.path.join(log_dir, 'service')
        error_log_dir = os.path.join(log_dir, 'error')
        self.create_directories(service_log_dir, error_log_dir)

        # Configurar logging
        self.setup_logging(service_log_dir, error_log_dir)

    def load_config(self, config_path):
        try:
            self.config.read(config_path)
        except Exception as e:
            self.log_error(f"Error loading config.ini: {str(e)}")
            raise

    def create_directories(self, *dirs):
        for directory in dirs:
            try:
                os.makedirs(directory, exist_ok=True)
            except Exception as e:
                self.log_error(f"Error creating directory {directory}: {str(e)}")
                raise

    def setup_logging(self, service_log_dir, error_log_dir):
        current_month = datetime.now().strftime('%Y-%m')
        self.log_file = os.path.join(service_log_dir, f"service_logs_{current_month}.log")
        self.error_log_file = os.path.join(error_log_dir, f"error_logs_{current_month}.log")

        logging.basicConfig(level=logging.INFO, format='%(asctime)s: %(levelname)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
        self.logger = logging.getLogger('BackupService')
        self.logger.addHandler(logging.FileHandler(self.log_file))
        self.error_logger = logging.getLogger('ErrorLogger')
        self.error_logger.addHandler(logging.FileHandler(self.error_log_file))

        self.logger.info("Service initialized.")

    def log_error(self, message):
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.error_logger.error(f"{timestamp}: {message}")

    def log_message(self, message):
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        self.logger.info(f"{timestamp}: {message}")

    def is_duplicate_log(self, message, error=False):
        today = datetime.now().strftime('%Y-%m-%d %H')
        log_file = self.error_log_file if error else self.log_file
        try:
            with open(log_file, "r") as log:
                for line in log:
                    if today in line and message in line:
                        return True
        except Exception as e:
            self.log_error(f"Error reading log file {log_file}: {str(e)}")
        return False

    def perform_custom_backup(self, database):
        # Log: Custom backup enabled
        self.log_message(f"Custom backup enabled for {database}. Using existing backup file.")

        # Use the existing backup file
        backup_folder = self.config['Settings']['backup_folder']
        current_year = str(datetime.now().year)
        current_month = f"{datetime.now().month:02d}"
        current_day = f"{datetime.now().day:02d}"

        # Filtrar los archivos que contienen el año, mes, día y "SCAIIPRD"
        filtered_files = [
            os.path.join(backup_folder, file) for file in os.listdir(backup_folder)
            if file.endswith('.bak') and current_year in file and current_month in file and current_day in file and database in file
        ]
        # Obtener el archivo más reciente de los archivos filtrados
        if filtered_files:
            backup_file = max(filtered_files, key=os.path.getctime)
        else:
            backup_file = None

        # Log: Archivo de respaldo seleccionado
        if backup_file:
            self.log_message(f"Selected backup file: {backup_file}")
        else:
            self.log_message(f"No backup file found matching the criteria: {database}_{current_year}_{current_month}_{current_day}.")

        return backup_file

    def backup_database(self, database):
        self.log_message(f"Loading config.ini for database {database}.")

        # Cargar configuración de la base de datos
        try:
            server = self.config['Database']['server']
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
        self.log_message(f"Starting database backup for {database}.")

        # Comando de respaldo para SQL Server
        conn_str = f"DRIVER={{SQL Server}};SERVER={server};UID={user};PWD={password}"
        # Dentro del bloque donde ejecutas el respaldo:
        try:
            with pyodbc.connect(conn_str) as conn:
                cursor = conn.cursor()

                # Cerrar cualquier transacción activa antes de realizar el respaldo
                cursor.execute("IF @@TRANCOUNT > 0 COMMIT")  # Commitear cualquier transacción pendiente

                # Verificar si la conexión se ha establecido correctamente
                self.log_message(f"Connected to SQL Server database '{database}'.")

                # Realizar el comando de respaldo
                backup_query = f"BACKUP DATABASE [{database}] TO DISK = '{backup_file}' WITH FORMAT"
                cursor.execute(backup_query)

                time.sleep(5)  # Esperar a que el respaldo se complete
                cursor.commit()

            # Después de ejecutar el comando de respaldo
            if os.path.isfile(backup_file):
                self.log_message(f"Backup file successfully created: {backup_file}")
            else:
                self.log_message(f"Backup file was not created: {backup_file}")

        except Exception as e:
            self.log_error(f"Error during backup: {str(e)}")
            return None

        return backup_file

    def compress_backup(self, backup_file):
        zip_file = backup_file.replace('.bak', '.zip')

        try:
            with zipfile.ZipFile(zip_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
                # Comprimir el archivo completo como un único archivo dentro del ZIP
                zipf.write(backup_file, os.path.basename(backup_file))
            
            # Log: Compresión completada
            self.log_message(f"Backup file compressed successfully into: {zip_file}")

        except Exception as e:
            self.log_error(f"Error during compression: {str(e)}")
            return None

        return zip_file

    def upload_to_sftp(self, file_path, database):
        # Reemplazar espacios en blanco por guiones bajos en el nombre de la base de datos
        #db_key = database.replace(" ", "_")
        
        # Cargar configuración del SFTP para la base de datos específica
        try:
            sftp_host = self.config['SFTP']['host']
            sftp_username = self.config['SFTP'][f'{database}_username']
            sftp_password = self.config['SFTP'][f'{database}_password']
            sftp_port = int(self.config['SFTP']['port'])
        except KeyError as e:
            self.log_error(f"Missing SFTP config for {database}: {str(e)}")
            return

        # Log: Intentando conectar al SFTP
        self.log_message(f"Connecting to SFTP server {sftp_host}...")

        # Validar si el archivo existe antes de intentar cargarlo
        if not os.path.isfile(file_path):
            self.log_message(f"File not found: {file_path}")
            return

        # Conectar al servidor SFTP y cargar el archivo
        try:
            cnopts = pysftp.CnOpts()
            cnopts.hostkeys = None  # Deshabilitar la validación de hostkeys (no recomendado para producción)

            with pysftp.Connection(sftp_host, username=sftp_username, password=sftp_password, port=sftp_port, cnopts=cnopts) as sftp:
                file_size = os.path.getsize(file_path)
                self.log_message(f"Starting upload of {file_path} ({file_size} bytes).")

                last_logged_progress = 0

                def progress_callback(transferred, total):
                    nonlocal last_logged_progress
                    progress = (transferred / total) * 100
                    if progress - last_logged_progress >= 10:  # Log cada 10%
                        self.log_message(f"Upload progress: {progress:.2f}%")
                        last_logged_progress = progress

                remote_path = os.path.basename(file_path)  # Subir con el mismo nombre
                sftp.put(file_path, remote_path, callback=progress_callback)  # Subir el archivo al servidor SFTP

                # Log: Archivo subido exitosamente
                self.log_message(f"File {file_path} uploaded to SFTP as {remote_path}.")

                # Log de desconexión
                self.log_message("SFTP connection closed.")

        except pysftp.ConnectionException as e:
            self.log_error(f"SFTP connection error: {str(e)}")
        except pysftp.AuthenticationException as e:
            self.log_error(f"SFTP authentication error: {str(e)}")
        except Exception as e:
            self.log_error(f"Error during SFTP upload: {str(e)}")

    def main(self):
        self.log_message("Starting main cycle.")

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
                        self.log_message("Starting backup and upload cycle.")

                        databases = [db for db in self.config['Databases'].values()]

                        for database in databases:
                            if self.custom_backup:
                                # Realizar el respaldo
                                backup_file = self.perform_custom_backup(database)
                                if backup_file is None:
                                    continue
                                    
                                # Comprimir el archivo de respaldo
                                zip_file = self.compress_backup(backup_file)
                                if zip_file is None:
                                    continue

                                # Subir el archivo comprimido al SFTP
                                self.upload_to_sftp(zip_file, database)

                                # Log: Custom backup process completed
                                self.log_message(f"Custom backup and upload completed for {database}.")

                            else:
                                # Realizar el respaldo
                                backup_file = self.backup_database(database)
                                if backup_file is None:
                                    continue

                                # Comprimir el archivo de respaldo
                                zip_file = self.compress_backup(backup_file)
                                if zip_file is None:
                                    continue

                                # Subir el archivo comprimido al SFTP
                                self.upload_to_sftp(zip_file, database)
                                
                                # Eliminar los archivos locales después de subirlos
                                if os.path.isfile(backup_file):
                                    os.remove(backup_file)
                                    self.log_message(f"Local backup file {backup_file} removed.")
                                
                                if os.path.isfile(zip_file):
                                    os.remove(zip_file)
                                    self.log_message(f"Local zip file {zip_file} removed.")

                                # Log: Respaldo completado y archivos eliminados localmente
                                self.log_message(f"Backup and upload completed for {database}. Local files removed.")

                        # Actualizar la fecha del último respaldo
                        self.last_backup_date = now.date()
                 # Esperar hasta la hora del próximo respaldo
                sleep_time = (next_backup - now).total_seconds()
                self.log_message(f"Sleeping until next backup at {next_backup}.")
                        
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