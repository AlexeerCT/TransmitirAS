import win32serviceutil
import ctypes, sys

SERVICE_NAME = "TransmitirAS"

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except:
        return False

def restart_service(service_name):
    try:
        # Detener el servicio
        print(f"Deteniendo el servicio {service_name}...")
        win32serviceutil.StopService(service_name)
        print(f"Servicio {service_name} detenido.")

        # Esperar un momento antes de reiniciar
        import time
        time.sleep(5)

        # Iniciar el servicio
        print(f"Iniciando el servicio {service_name}...")
        win32serviceutil.StartService(service_name)
        print(f"Servicio {service_name} iniciado.")
    except Exception as e:
        print(f"Error al reiniciar el servicio {service_name}: {e}")

def stop_service(service_name):
    try:
        print(f"Deteniendo el servicio {service_name}...")
        win32serviceutil.StopService(service_name)
        print(f"Servicio {service_name} detenido.")
    except Exception as e:
        print(f"Error al detener el servicio {service_name}: {e}")

def start_service(service_name):
    try:
        print(f"Iniciando el servicio {service_name}...")
        win32serviceutil.StartService(service_name)
        print(f"Servicio {service_name} iniciado.")
    except Exception as e:
        print(f"Error al iniciar el servicio {service_name}: {e}")

if __name__ == "__main__":
    if not is_admin():
        print("Este script necesita permisos de administrador para ejecutarse.")
        ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, __file__, None, 1)
        sys.exit()

    print("Seleccione una opción:")
    print("1. Reiniciar servicio")
    print("2. Detener servicio")
    print("3. Iniciar servicio")
    option = input("Ingrese el número de la opción: ")

    if option == "1":
        restart_service(SERVICE_NAME)
    elif option == "2":
        stop_service(SERVICE_NAME)
    elif option == "3":
        start_service(SERVICE_NAME)
    else:
        print("Opción no válida.")