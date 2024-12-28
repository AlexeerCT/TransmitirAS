import win32serviceutil

SERVICE_NAME = "TransmitirAS"

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

if __name__ == "__main__":
    restart_service(SERVICE_NAME)