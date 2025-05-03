#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <stdatomic.h>
#include <openssl/dh.h>
#include <openssl/sha.h>
#include <openssl/bn.h>
#include "shared.h"

#define PORT 9000

pthread_t video_send_thread;
pthread_t video_recv_thread;
atomic_bool in_call = 0;
int call_pending = 0;

void derive_key_iv(unsigned char *shared_secret, int secret_size) {
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256(shared_secret, secret_size, hash);

    char key_hex[33], iv_hex[33];
    for (int i = 0; i < 16; i++) sprintf(key_hex + i * 2, "%02x", hash[i]);
    for (int i = 0; i < 16; i++) sprintf(iv_hex + i * 2, "%02x", hash[i + 16]);

    key_hex[32] = '\0';
    iv_hex[32] = '\0';
    setenv("AES_KEY", key_hex, 1);
    setenv("AES_IV", iv_hex, 1);
}

void perform_dh_key_exchange(int sockfd) {
    DH *dh = DH_get_2048_256(); // Use standard group
    if (!dh || !DH_generate_key(dh)) {
        fprintf(stderr, "[!] DH setup failed.\n");
        exit(1);
    }

    const BIGNUM *pub_key = NULL;
    DH_get0_key(dh, &pub_key, NULL);
    int pub_len = BN_num_bytes(pub_key);
    unsigned char *pub_buf = malloc(pub_len);
    BN_bn2bin(pub_key, pub_buf);

    int peer_len;
    unsigned char *peer_buf = malloc(pub_len); // Assume same length

    send(sockfd, &pub_len, sizeof(int), 0);
    send(sockfd, pub_buf, pub_len, 0);
    recv(sockfd, &peer_len, sizeof(int), 0);
    recv(sockfd, peer_buf, peer_len, 0);

    BIGNUM *peer_key = BN_bin2bn(peer_buf, peer_len, NULL);
    int secret_size = DH_size(dh);
    unsigned char *secret = malloc(secret_size);
    secret_size = DH_compute_key(secret, peer_key, dh);

    derive_key_iv(secret, secret_size);

    BN_free(peer_key);
    free(pub_buf);
    free(peer_buf);
    free(secret);
    DH_free(dh);
}

void* recv_loop(void* arg) {
    int sockfd = *(int*)arg;
    char type[MSG_TYPE_LEN];
    char buffer[MAX_PAYLOAD];
    uint32_t len;

    while (1) {
        if (recv_message(sockfd, type, buffer, &len) < 0) {
            printf("[!] Connection closed or error.\n");
            break;
        }
        buffer[len] = '\0';

        if (strcmp(type, "TEXT") == 0) {
            printf("[Client]: %s\n", buffer);
        } else if (strcmp(type, "CALL_REQUEST") == 0) {
            printf("[Client]: Call requested. Type 'accept' or 'reject'.\n");
            call_pending = 1;
        } else if (strcmp(type, "CALL_ACCEPT") == 0) {
            in_call = 1;
            printf("[Client]: Call accepted. Starting video stream...\n");
            system("python3 src/video_call.py &");
        } else if (strcmp(type, "CALL_REJECT") == 0) {
            printf("[Client]: Call rejected.\n");
        } else if (strcmp(type, "CALL_END") == 0) {
            in_call = 0;
            printf("[Client]: Call ended.\n");
            system("pkill -F /tmp/video_call.pid");
            sleep(1);
        }
    }
    return NULL;
}

void* send_loop(void* arg) {
    int sockfd = *(int*)arg;
    char input[MAX_PAYLOAD];

    while (1) {
        printf("Enter message ('call', 'end', 'accept', 'reject'): ");
        if (fgets(input, sizeof(input), stdin) == NULL) break;
        input[strcspn(input, "\n")] = 0;

        if (strcmp(input, "call") == 0) {
            send_message(sockfd, "CALL_REQUEST", NULL, 0);
        } else if (strcmp(input, "accept") == 0 && call_pending) {
            send_message(sockfd, "CALL_ACCEPT", NULL, 0);
            in_call = 1;
            call_pending = 0;
            printf("Accepted call. Starting video...\n");
            system("python3 src/video_call.py &");
        } else if (strcmp(input, "reject") == 0 && call_pending) {
            send_message(sockfd, "CALL_REJECT", NULL, 0);
            call_pending = 0;
        } else if (strcmp(input, "end") == 0 && in_call) {
            send_message(sockfd, "CALL_END", NULL, 0);
            in_call = 0;
            system("pkill -F /tmp/video_call.pid");
            sleep(1);
        } else {
            send_message(sockfd, "TEXT", input, strlen(input));
        }
    }
    return NULL;
}

int main() {
    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
    struct sockaddr_in addr = {0};

    addr.sin_family = AF_INET;
    addr.sin_port = htons(PORT);
    addr.sin_addr.s_addr = INADDR_ANY;

    bind(server_fd, (struct sockaddr*)&addr, sizeof(addr));
    listen(server_fd, 1);
    printf("[Server] Waiting for connection on port %d...\n", PORT);

    struct sockaddr_in client_addr;
    socklen_t addr_len = sizeof(client_addr);
    int client_fd = accept(server_fd, (struct sockaddr*)&client_addr, &addr_len);
    printf("[Server] Client connected.\n");

    char partner_ip[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &client_addr.sin_addr, partner_ip, INET_ADDRSTRLEN);
    setenv("PARTNER_IP", partner_ip, 1);

    perform_dh_key_exchange(client_fd);

    printf("[Server] Environment setup:\n");
    printf("  PARTNER_IP = %s\n", getenv("PARTNER_IP"));
    printf("  AES_KEY    = %s\n", getenv("AES_KEY"));
    printf("  AES_IV     = %s\n", getenv("AES_IV"));

    pthread_t send_thread, recv_thread;
    pthread_create(&recv_thread, NULL, recv_loop, &client_fd);
    pthread_create(&send_thread, NULL, send_loop, &client_fd);

    pthread_join(send_thread, NULL);
    pthread_join(recv_thread, NULL);

    close(client_fd);
    close(server_fd);
    return 0;
}
