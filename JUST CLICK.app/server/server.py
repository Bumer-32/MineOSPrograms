import socket
import threading
import configparser
import os
import zipfile
import logging

resources = os.path.dirname(os.path.abspath(__file__))

saveFile = open(resources + "/save.txt", "r+", encoding="utf-8")

num = 0
saveFiledata = saveFile.read()
if saveFiledata != "":
    num = int(saveFiledata)
    saveFiledata = None


#configs
config = configparser.ConfigParser()
if os.path.exists(resources + "/config.ini"):
    try:
        config.read(resources + "/config.ini")
    except Exception as error:
        logging.critical(error)
        logging.warning("config.ini file formatting error! stopping server")
        os._exit(0)
else:
    print("there's no config.ini file! stopping server")
    os._exit(0)

serverPort = int(config["serverConfig"]["port"])

if config["serverConfig"]["ipAddr"] == "Auto":
    serverIp = socket.gethostbyname(socket.gethostname())
else:
    serverIp = config["serverConfig"]["ipAddr"]

if config["serverConfig"]["logsPathLocation"] == "Absolute":
    logsPath = config["serverConfig"]["logsPath"]
else:
    logsPath = resources + config["serverConfig"]["logsPath"]
###
    
if not os.path.exists(logsPath):
        os.makedirs(logsPath)

if config["serverConfig"]["saveLastLog"] != "No":
    if os.path.exists(f"{logsPath}/server_log.log"):
        with zipfile.ZipFile(f"{logsPath}/previuos.zip", "w") as zip:
            zip.write(f"{logsPath}/server_log.log", "previuos_log.log")

logging.basicConfig(
    level=logging.NOTSET, filename=f"{logsPath}/server_log.log", encoding="utf-8", filemode="w",
    format="%(asctime)s || %(lineno)d | [%(levelname)s] [%(filename)s] [%(name)s/%(threadName)s] : %(message)s")

logging.debug("DEBUG")
logging.info("INFO")
logging.warning("WARNING")
logging.error("ERROR")
logging.critical("CRITICAL")

logging.info(f"created new log | You can find previuos log at {logsPath}/previuos.zip/previuos_log.log")

logging.debug(f"server ip: {serverIp}")
logging.debug(f"server port: {serverPort}")

serverSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
serverSocket.bind((serverIp, serverPort))
serverSocket.listen(5)

clients = []

def handle_client(clientSocket):
    while True:
        try:
            message = clientSocket.recv(1024).decode('utf-8')
            if not message:
                clients.remove(clientSocket)
                clientSocket.close()
                break
            
            logging.info(f"new tcp message: {message}")

            if message == "click":
                global num
                num = num + 1
                saveFile.seek(0)
                saveFile.write(str(num))
            elif message == "disconnect":
                logging.info("someone disconnect")
                clients.remove(clientSocket)
                clientSocket.close()
                break

            for client in clients:
                client.send(str(num).encode('utf-8'))
        except Exception as error:
            logging.info(f"someone disconnect: {error}")
            clients.remove(clientSocket)
            clientSocket.close()
            break

while True:
    clientSocket, clientAddress = serverSocket.accept()
    logging.info(f"connected new client: {clientAddress}")
    clients.append(clientSocket)

    clientThread = threading.Thread(target=handle_client, args=(clientSocket,))
    clientThread.start()