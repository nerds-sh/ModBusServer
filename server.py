from flask import Flask, request, jsonify
from pymodbus3.server.sync import StartTcpServer
from pymodbus3.datastore import ModbusSequentialDataBlock, ModbusSlaveContext, ModbusServerContext
from pymodbus3.client.sync import ModbusTcpClient
from threading import Thread
import logging

# Initialize Flask app
app = Flask(__name__)

# Initialize Modbus data store with arbitrary initial values
store = ModbusSequentialDataBlock(0, [0] * 100)
modbus_context = ModbusSlaveContext(di=store, co=store, hr=store, ir=store)
modbus_context = ModbusServerContext(slaves=modbus_context, single=True)

# Helper function to start the Modbus TCP server
def run_modbus_server():
    StartTcpServer(modbus_context, address=("0.0.0.0", 5020))

@app.route('/write', methods=['POST'])
def handle_modbus_write():
    client = ModbusTcpClient('localhost', port=5020)
    
    # Get the JSON data from the request
    data = request.json

    # Validate the JSON data structure
    if not isinstance(data, dict) or not all(key in data for key in ['LengthOfLine', 'LengthOfWorkTool', 'HeightOfPiece']):
        return jsonify({"error": "Invalid request format"}), 400

    try:
        # Write the values to Modbus registers 0 to 2
        registers = [
            data['LengthOfLine'],
            data['LengthOfWorkTool'],
            data['HeightOfPiece'],
            data['SpeedToWorkPlace'],
            data['SpeedInFrezare']
        ]
        for address, value in enumerate(registers, start=0):
            store.setValues('h', address, [int(value)])  # Use 'h' for 16-bit registers

        client.close()
        return jsonify({"message": "Values updated successfully"}), 200
    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/read', methods=['GET'])
def handle_modbus_read():
    client = ModbusTcpClient('localhost', port=5020)
    if request.method == 'GET':
        # Handling data reading from Modbus server
        # Assuming we want to read the first 3 registers for demonstration
        result = client.read_holding_registers(0, 3)
        client.close()
        
        if result.function_code > 0x80:
            # Check if it's an error response
            return jsonify({"error": f"Modbus error response (function code {result.function_code & 0x7F})"}), 500

        values = {
            "LengthOfLine": result.registers[0],
            "LengthOfWorkTool": result.registers[1],
            "HeightOfPiece": result.registers[2],
            "SpeedToWorkPlace": result.registers[3],
            "SpeedInFrezare": result.registers[4]
        }
        return jsonify(values), 200

if __name__ == '__main__':
    # Configure logging
    logging.basicConfig()
    log = logging.getLogger()
    log.setLevel(logging.DEBUG)

    # Start Modbus server in a separate thread to prevent blocking
    Thread(target=run_modbus_server).start()

    # Start the Flask HTTP server in the main thread
    app.run(host='0.0.0.0', port=5040, debug=False)
