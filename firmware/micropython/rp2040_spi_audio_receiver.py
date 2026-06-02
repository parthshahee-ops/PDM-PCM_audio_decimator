from machine import Pin, SPI
import time
import shrike

print("Flashing unchanged FPGA bitstream core...")
shrike.flash("FPGA_bitstream_MCU.bin")

reset_pin = Pin(14, Pin.OUT, value=1)
reset_pin.value(0)
time.sleep(0.1)
reset_pin.value(1)
time.sleep(0.1)

# Configure native 16-bit Master SPI channel
cs = Pin(1, Pin.OUT, value=1)
spi = SPI(0, baudrate=1000000, polarity=0, phase=0, bits=16, firstbit=SPI.MSB, sck=Pin(2), mosi=Pin(3), miso=Pin(0))

def spi_exchange_16bit(word_to_send):
    tx_buffer = bytes([(word_to_send >> 8) & 0xFF, word_to_send & 0xFF])
    rx_buffer = bytearray(2)
    
    cs.value(0)  # Drop CS to clear internal FPGA transmission counts 
    spi.write_readinto(tx_buffer, rx_buffer)
    cs.value(1)  # Raise CS to latch the packet inside the hardware register
    
    raw_val = (rx_buffer[0] << 8) | rx_buffer[1]
    if raw_val > 32767:
        raw_val -= 65536
    return raw_val

# Symmetrical alternating patterns that resonate perfectly with R=64 steps
discrete_samples = [0x42, 0x7F, 0x9C, 0xA5, 0x5A, 0x42, 0x7F, 0x9C, 0xA5, 0x5A, 0x42, 0x7F, 0x9C, 0xA5, 0x5A]

print("=== Starting Synced 16-Bit Discrete Data Exchange ===")

while True:
    for sample in discrete_samples:
        # Cast our signed sample to a clean 16-bit unsigned vector representation [cite: 8]
        unsigned_sample = sample & 0xFFFF
        
        # Pump the sample and read the stable filtered PCM output back instantly [cite: 22]
        pcm_out = spi_exchange_16bit(unsigned_sample)
        
        print(f"OUT:{pcm_out}")

