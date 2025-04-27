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
    DH *dh = DH_new();
    if (!dh || !DH_generate_parameters_ex(dh, 1024, DH_GENERATOR_2, NULL)) {
        fprintf(stderr, "[!] DH initialization failed.\n");
        exit(1);
    }

    if (!DH_generate_key(dh)) {
        fprintf(stderr, "[!] DH_generate_key failed.\n");
        DH_free(dh);
        exit(1);
    }

    const BIGNUM *pub_key = NULL;
    DH_get0_key(dh, &pub_key, NULL);
    int pub_len = BN_num_bytes(pub_key);
    unsigned char *pub_buf = malloc(pub_len);
    if (!pub_buf) {
        fprintf(stderr, "[!] malloc failed for pub_buf.\n");
        DH_free(dh);
        exit(1);
    }
    BN_bn2bin(pub_key, pub_buf);

    int peer_len;
    if (recv(sockfd, &peer_len, sizeof(int), 0) <= 0) {
        fprintf(stderr, "[!] Failed to receive peer length.\n");
        free(pub_buf);
        DH_free(dh);
        exit(1);
    }
    unsigned char *peer_buf = malloc(peer_len);
    if (!peer_buf) {
        fprintf(stderr, "[!] malloc failed for peer_buf.\n");
        free(pub_buf);
        DH_free(dh);
        exit(1);
    }
    if (recv(sockfd, peer_buf, peer_len, 0) <= 0) {
        fprintf(stderr, "[!] Failed to receive peer key.\n");
        free(pub_buf);
        free(peer_buf);
        DH_free(dh);
        exit(1);
    }
    BIGNUM *peer_key = BN_bin2bn(peer_buf, peer_len, NULL);
    if (!peer_key) {
        fprintf(stderr, "[!] BN_bin2bn failed.\n");
        free(pub_buf);
        free(peer_buf);
        DH_free(dh);
        exit(1);
    }

    send(sockfd, &pub_len, sizeof(int), 0);
    send(sockfd, pub_buf, pub_len, 0);

    int secret_size = DH_size(dh);
    if (secret_size <= 0) {
        fprintf(stderr, "[!] Invalid DH secret size.\n");
        BN_free(peer_key);
        free(pub_buf);
        free(peer_buf);
        DH_free(dh);
        exit(1);
    }

    unsigned char *secret = malloc(secret_size);
    if (!secret) {
        fprintf(stderr, "[!] malloc failed for secret.\n");
        BN_free(peer_key);
        free(pub_buf);
        free(peer_buf);
        DH_free(dh);
        exit(1);
    }

    secret_size = DH_compute_key(secret, peer_key, dh);
    if (secret_size <= 0) {
        fprintf(stderr, "[!] DH_compute_key failed.\n");
        BN_free(peer_key);
        free(pub_buf);
        free(peer_buf);
        free(secret);
        DH_free(dh);
        exit(1);
    }

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
            printf("[Server]: %s\n", buffer);
        } else if (strcmp(type, "CALL_REQUEST") == 0) {
            printf("[Server]: Call requested. Type 'accept' or 'reject'.\n");
            call_pending = 1;
        } else if (strcmp(type, "CALL_ACCEPT") == 0) {
            in_call = 1;
            printf("[Server]: Call accepted. Starting video stream...\n");
            system("python3 src/video_call.py &");
        } else if (strcmp(type, "CALL_REJECT") == 0) {
            printf("[Server]: Call rejected.\n");
        } else if (strcmp(type, "CALL_END") == 0) {
            in_call = 0;
            printf("[Server]: Call ended.\n");
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

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <server_ip>\n", argv[0]);
        return 1;
    }

    const char* SERVER_IP = argv[1];
    setenv("PARTNER_IP", SERVER_IP, 1);

    int sockfd = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in server_addr = {0};

    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(PORT);
    inet_pton(AF_INET, SERVER_IP, &server_addr.sin_addr);

    connect(sockfd, (struct sockaddr*)&server_addr, sizeof(server_addr));
    printf("[Client] Connected to server.\n");

    //Do DH key exchange once immediately after connection
    perform_dh_key_exchange(sockfd);

    pthread_t send_thread, recv_thread;
    pthread_create(&recv_thread, NULL, recv_loop, &sockfd);
    pthread_create(&send_thread, NULL, send_loop, &sockfd);

    pthread_join(send_thread, NULL);
    pthread_join(recv_thread, NULL);

    close(sockfd);
    return 0;
}
