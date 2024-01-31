from flask import Flask, request, jsonify
from pymodbus.server.sync import StartTcpServer
from pymodbus.datastore import ModbusSequentialDataStore, ModbusSlaveContext, ModbusServerContext
from pymodbus.client.sync import ModbusTcpClient
from threading import Thread
import logging

# Initialize Flask app
app = Flask(__name__)

# Initialize Modbus data store with arbitrary initial values
store = ModbusSequentialDataStore(1)
modbus_context = ModbusSlaveContext(di=store, co=store, hr=store, ir=store)
modbus_context = ModbusServerContext(slaves=modbus_context, single=True)

# Helper function to start the Modbus TCP server
def run_modbus_server():
    StartTcpServer(modbus_context, address=("0.0.0.0", 5020))

@app.route('/modbus', methods=['GET', 'POST'])
def handle_modbus():
    client = ModbusTcpClient('localhost', port=5020)
    if request.method == 'POST':
        # Handling data writing to Modbus server
        data = request.json
        if not data:
            return jsonify({"error": "Invalid request"}), 400
        
        # Assuming register addresses start from 1 for simplicity
        write_results = []
        for address, value in enumerate(data.values(), start=1):
            result = client.write_register(address, value)
            write_results.append({f"register_{address}": "success" if not result.isError() else "failed"})

        client.close()
        return jsonify(write_results), 200
    
    else:
        # Handling data reading from Modbus server
        # Assuming we want to read the first 3 registers for demonstration
        result = client.read_holding_registers(1, 3)
        client.close()
        if result.isError():
            return jsonify({"error": "Failed to read Modbus registers"}), 500
        
        values = {
            "LengthOfLine": result.registers[0],
            "LengthOfWorkTool": result.registers[1],
            "HeightOfPiece": result.registers[2],
        }
        return jsonify(values), 200

def run_http_server():
    app.run(host='0.0.0.0', port=5000, debug=False)

if __name__ == '__main__':
    # Configure logging
    logging.basicConfig()
    log = logging.getLogger()
    log.setLevel(logging.DEBUG)

    # Start Modbus server in a separate thread to prevent blocking
    Thread(target=run_modbus_server).start()

    # Start the Flask HTTP server in the main thread
    run_http_server()
