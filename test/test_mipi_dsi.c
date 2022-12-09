// Test Code for MIPI DSI
// Add `#include "../../pinephone-nuttx/test/mipi_dsi_inc.c"` to the end of this file:
// https://github.com/lupyuen2/wip-pinephone-nuttx/blob/dsi/arch/arm64/src/a64/mipi_dsi.c

void dump_buffer(const uint8_t *data, size_t len)
{
  char buf[8 * 3];
  memset(buf, ' ', sizeof(buf));
  buf[sizeof(buf) - 1] = 0;

	for (int i = 0; i < len; i++) {
    const int mod = i % 8;
    const int d1 = data[i] >> 4;
    const int d2 = data[i] & 0b1111;
    buf[mod * 3] = (d1 < 10) ? ('0' + d1) : ('a' + d1 - 10);
    buf[mod * 3 + 1] = (d2 < 10) ? ('0' + d2) : ('a' + d2 - 10);

		if ((i + 1) % 8 == 0 || i == len - 1) {
      _info("%s\n", buf);
      if (i == len - 1) { break; }

      memset(buf, ' ', sizeof(buf));
      buf[sizeof(buf) - 1] = 0;
    }
	}
}

/*
39 40 00 25 e9 82 10 06 
05 a2 0a a5 12 31 23 37 
83 04 bc 27 38 0c 00 03 
00 00 00 0c 00 03 00 00 
00 75 75 31 88 88 88 88 
88 88 13 88 64 64 20 88 
88 88 88 88 88 02 88 00 
00 00 00 00 00 00 00 00 
00 00 00 00 65 03 
*/

void mipi_dsi_test(void)  //// TODO: Remove
{
    // Allocate Packet Buffer
    uint8_t pkt_buf[128];
    memset(pkt_buf, 0, sizeof(pkt_buf));

    // Test Compose Short Packet (Without Parameter)
    _info("Testing Compose Short Packet (Without Parameter)...\n");
    const uint8_t short_pkt[1] = {
        0x11,
    };
    const ssize_t short_pkt_result = mipi_dsi_short_packet(
        pkt_buf,  //  Packet Buffer
        sizeof(pkt_buf),  // Packet Buffer Size
        0,         //  Virtual Channel
        MIPI_DSI_DCS_SHORT_WRITE, // DCS Command
        short_pkt,    // Transmit Buffer
        sizeof(short_pkt)  // Buffer Length
    );
    _info("Result:\n");
    dump_buffer(pkt_buf, short_pkt_result);

    const uint8_t expected_short_pkt[] = { 
      0x05, 0x11, 0x00, 0x36 
    };
    DEBUGASSERT(short_pkt_result == sizeof(expected_short_pkt));
    DEBUGASSERT(memcmp(pkt_buf, expected_short_pkt, sizeof(expected_short_pkt)) == 0);

    // Write to MIPI DSI
    // _ = nuttx_mipi_dsi_dcs_write(
    //     null,  //  Device
    //     0,     //  Virtual Channel
    //     MIPI_DSI_DCS_SHORT_WRITE, // DCS Command
    //     &short_pkt,    // Transmit Buffer
    //     short_pkt.len  // Buffer Length
    // );

    // Test Compose Short Packet (With Parameter)
    _info("Testing Compose Short Packet (With Parameter)...\n");
    const uint8_t short_pkt_param[2] = {
        0xbc, 0x4e,
    };
    const ssize_t short_pkt_param_result = mipi_dsi_short_packet(
        pkt_buf,  //  Packet Buffer
        sizeof(pkt_buf),  // Packet Buffer Size
        0,         //  Virtual Channel
        MIPI_DSI_DCS_SHORT_WRITE_PARAM, // DCS Command
        short_pkt_param,    // Transmit Buffer
        sizeof(short_pkt_param)  // Buffer Length
    );
    _info("Result:\n");
    dump_buffer(pkt_buf, short_pkt_param_result);

    const uint8_t expected_short_pkt_param[] = { 
        0x15, 0xbc, 0x4e, 0x35 
    };
    DEBUGASSERT(short_pkt_param_result == sizeof(expected_short_pkt_param));
    DEBUGASSERT(memcmp(pkt_buf, expected_short_pkt_param, sizeof(expected_short_pkt_param)) == 0);

    // Write to MIPI DSI
    // _ = nuttx_mipi_dsi_dcs_write(
    //     null,  //  Device
    //     0,     //  Virtual Channel
    //     MIPI_DSI_DCS_SHORT_WRITE_PARAM, // DCS Command
    //     &short_pkt_param,    // Transmit Buffer
    //     short_pkt_param.len  // Buffer Length
    // );

    // Test Compose Long Packet
    _info("Testing Compose Long Packet...\n");
    const uint8_t long_pkt[] = {
        0xe9, 0x82, 0x10, 0x06, 0x05, 0xa2, 0x0a, 0xa5,
        0x12, 0x31, 0x23, 0x37, 0x83, 0x04, 0xbc, 0x27,
        0x38, 0x0c, 0x00, 0x03, 0x00, 0x00, 0x00, 0x0c,
        0x00, 0x03, 0x00, 0x00, 0x00, 0x75, 0x75, 0x31,
        0x88, 0x88, 0x88, 0x88, 0x88, 0x88, 0x13, 0x88,
        0x64, 0x64, 0x20, 0x88, 0x88, 0x88, 0x88, 0x88,
        0x88, 0x02, 0x88, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };
    const ssize_t long_pkt_result = mipi_dsi_long_packet(
        pkt_buf,  //  Packet Buffer
        sizeof(pkt_buf),  // Packet Buffer Size
        0,         //  Virtual Channel
        MIPI_DSI_DCS_LONG_WRITE, // DCS Command
        long_pkt,    // Transmit Buffer
        sizeof(long_pkt)  // Buffer Length
    );
    _info("Result:\n");
    dump_buffer(pkt_buf, long_pkt_result);

    const uint8_t expected_long_pkt[] = {
        0x39, 0x40, 0x00, 0x25, 0xe9, 0x82, 0x10, 0x06,
        0x05, 0xa2, 0x0a, 0xa5, 0x12, 0x31, 0x23, 0x37,
        0x83, 0x04, 0xbc, 0x27, 0x38, 0x0c, 0x00, 0x03,
        0x00, 0x00, 0x00, 0x0c, 0x00, 0x03, 0x00, 0x00,
        0x00, 0x75, 0x75, 0x31, 0x88, 0x88, 0x88, 0x88,
        0x88, 0x88, 0x13, 0x88, 0x64, 0x64, 0x20, 0x88,
        0x88, 0x88, 0x88, 0x88, 0x88, 0x02, 0x88, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x65, 0x03,
    };
    DEBUGASSERT(long_pkt_result == sizeof(expected_long_pkt));
    DEBUGASSERT(memcmp(pkt_buf, expected_long_pkt, sizeof(expected_long_pkt)) == 0);
}
