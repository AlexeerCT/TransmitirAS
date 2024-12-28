# Transmitir AS

This project implements a Windows service that automatically backs up SQL Server databases and uploads them to an SFTP server. 

## Project Structure

```
transmitiras
├── src
│   ├── main.py          # Implementation of the BackupService class
│   └── config.ini       # Configuration file for database and SFTP settings
├── requirements.txt     # List of dependencies required for the project
└── README.md            # Documentation for the project
```

## Installation

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd transmitiras
   ```

2. **Install dependencies:**
   Ensure you have Python installed, then run:
   ```
   pip install -r requirements.txt
   ```

4. **Compile:**
   ```
   py -m  PyInstaller .\TransmitirAS.spec
   py -m  PyInstaller .\reload.spec   
   ```

5. **Create the installer:**
   Use inno setup and execute TransmitirAS.iss

6. **Install the service:**
   Run TransmitirAS_Installer.exe

7. **Configure the service:**
   Edit the `{app}/config.ini` file to set your database connection details, SFTP credentials, and backup schedule.
   Reload the service with reload.exe

