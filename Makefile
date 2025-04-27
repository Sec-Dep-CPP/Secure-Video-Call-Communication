CC=gcc
CFLAGS=-Wall -Iinclude
LDFLAGS=-lpthread -lcrypto

SRC_DIR=src
BUILD_DIR=build

CLIENT_SRC=$(SRC_DIR)/client.c $(SRC_DIR)/shared.c
SERVER_SRC=$(SRC_DIR)/server.c $(SRC_DIR)/shared.c
AES_SRC=$(SRC_DIR)/aes_wrapper.c $(SRC_DIR)/aes.c
AUDIO_SRC=$(SRC_DIR)/audio_sender.c $(SRC_DIR)/audio_receiver.c $(SRC_DIR)/aes.c

CLIENT_BIN=$(BUILD_DIR)/client
SERVER_BIN=$(BUILD_DIR)/server
LIBAES=$(SRC_DIR)/libaes.so
LIBAUDIO=$(SRC_DIR)/libaudio.so

all: $(BUILD_DIR) $(CLIENT_BIN) $(SERVER_BIN) $(LIBAES) $(LIBAUDIO)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(CLIENT_BIN): $(CLIENT_SRC)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(SERVER_BIN): $(SERVER_SRC)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

$(LIBAES): $(AES_SRC)
	$(CC) -shared -fPIC -Iinclude -o $@ $^

$(LIBAUDIO): $(AUDIO_SRC)
	$(CC) -shared -fPIC -Iinclude -o $@ $^ -lasound -lcrypto

clean:
	rm -f $(BUILD_DIR)/* $(SRC_DIR)/*.o $(SRC_DIR)/*.so
