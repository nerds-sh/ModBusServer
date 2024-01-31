
# ModbusServer Project

The ModbusServer project integrates a Modbus TCP server with a Flask-based HTTP API, enabling users to read from and write to Modbus registers via HTTP requests. This solution is designed to facilitate interaction with Modbus devices over the network, making it suitable for various applications in automation, IoT, and industrial control systems.

## Features

- **Modbus TCP Server**: Hosts a Modbus server for interaction with Modbus clients and devices.
- **Flask HTTP API**: Provides HTTP endpoints to read and write Modbus register values.
- **Concurrent Operation**: Runs both Modbus and HTTP servers concurrently, allowing simultaneous Modbus and web interactions.

## Prerequisites

- Python 3.6 or higher
- pip for Python 3

## Installation

1. **Clone the Repository**

   ```bash
   git clone https://example.com/ModbusServer.git
   cd ModbusServer
   ```

2. **Setup a Virtual Environment** (Optional but recommended)

   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows use `venv\Scripts\activate`
   ```

3. **Install Dependencies**

   ```bash
   pip install -r requirements.txt
   ```

## Running the Server

1. **Start the Server**

   ```bash
   python server.py
   ```

   This command starts both the Modbus TCP server on port 5020 and the Flask HTTP server on port 5000.

## Usage

### Modbus TCP Server

Connect to the Modbus TCP server using any Modbus TCP client on port 5020.

### HTTP API Endpoints

- **Read Modbus Registers**

  Send a GET request to `http://localhost:5000/modbus` to read values from predefined Modbus registers.

- **Write to Modbus Registers**

  Send a POST request to `http://localhost:5000/modbus` with a JSON payload specifying the register values to write, e.g.,

  ```json
  {
    "1": 100,
    "2": 50,
    "3": 25
  }
  ```

## Contributing

Contributions to the ModbusServer project are welcome. Please follow the standard fork-pull request workflow on GitHub to submit your changes.
