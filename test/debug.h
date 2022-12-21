#define baterr printf
#define batinfo printf
#define gerr printf
#define ginfo printf
#define ginfodumpbuffer(msg, buf, len) dump_buffer(buf, len)

void dump_buffer(const uint8_t *data, size_t len);
