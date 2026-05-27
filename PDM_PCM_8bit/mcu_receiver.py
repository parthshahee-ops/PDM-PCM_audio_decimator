from machine import Pin, SPI
import time
import shrike

shrike.flash("FPGA_bitstream_MCU.bin")
# Initialize active-low hardware reset on RP2040 GPIO 14
reset_pin = Pin(14, Pin.OUT, value=1)
reset_pin.value(0)
time.sleep(0.1)
reset_pin.value(1)
time.sleep(0.1)

# RP2040 Native SPI0 Peripheral Pin Mapping
SCK  = 2  
CS   = 1  
MOSI = 3  
MISO = 0  

cs = Pin(CS, Pin.OUT, value=1)

# Configure SPI Block (Mode 0, 1 MHz, MSB first)
spi = SPI(0,
          baudrate=1000000,
          polarity=0,
          phase=0,
          bits=8,
          firstbit=SPI.MSB,
          sck=Pin(SCK),
          mosi=Pin(MOSI),
          miso=Pin(MISO))

def spi_exchange(byte_to_send):
    tx = bytes([byte_to_send])
    rx = bytearray(1)

    cs.value(0)  # Select FPGA (Enables MISO Output)
    spi.write_readinto(tx, rx)
    cs.value(1)  # Deselect FPGA (Tri-states MISO)

    return rx[0]

# Standard trial data sequence matching our earlier successful link tests
test_patterns = [0x42, 0x7F, 0x9C, 0xA5, 0x5A]

print("=== Starting CIC Filter Live Data Exchange ===")
while True:
    for val in test_patterns:
        resp = spi_exchange(val)
        
        # Convert raw unsigned byte into signed integer spectrum values (-128 to 127)
        signed_pcm = resp - 256 if resp > 127 else resp
        
        print(f"Injected: 0x{val:02X} | Filter Out: {signed_pcm:4d}")
        time.sleep(1)
