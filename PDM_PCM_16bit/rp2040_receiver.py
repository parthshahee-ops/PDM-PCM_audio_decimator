from machine import Pin, SPI
import time
import shrike

shrike.flash("FPGA_bitstream_MCU.bin")

# Pulse reset to clear the accumulators safely
reset_pin = Pin(14, Pin.OUT, value=1)
reset_pin.value(0)
time.sleep(0.1)
reset_pin.value(1)
time.sleep(0.1)

cs = Pin(1, Pin.OUT, value=1)
spi = SPI(0, baudrate=1000000, polarity=0, phase=0, bits=16, firstbit=SPI.MSB,
          sck=Pin(2), mosi=Pin(3), miso=Pin(0))

def spi_exchange(value):
    "Mask value to clean 16-bit unsigned format for SPI transmission"
    tx_word = value & 0xFFFF
    tx_buffer = bytes([(tx_word >> 8) & 0xFF, tx_word & 0xFF])
    rx_buffer = bytearray(2)
    
    cs.value(0)
    spi.write_readinto(tx_buffer, rx_buffer)
    cs.value(1)
    
    raw = (rx_buffer[0] << 8) | rx_buffer[1]
    if raw > 32767:
        raw -= 65536
    return raw

# Clean, large base-10 values to get a massive unmistakable wave on screen
test_samples = [0, 200, 400, 600, 800, 1000, 1200, 1400, 1400, 1200, 1000, 800, 600, 400, 200, 0, 200, 400, 600, 800, 1000, 1200, 1400, 1400, 1200, 1000, 800, 600, 400, 200, 0, 200, 400, 600, 800, 1000, 1200, 1400, 1400, 1200, 1000, 800, 600, 400, 200, 0]

print("=== 16-Bit Exchange Online ===")

while True:
    for sample in test_samples:
        pcm_out = spi_exchange(sample)
        print(f"OUT:{pcm_out}")
        time.sleep(0.15)

